const test = require('node:test');
const assert = require('node:assert/strict');
const { dispatchProcessBatch, persistAndSettleProcess } = require('../utils/processBatch');
const { startProcessingRun } = require('../utils/processingRun');

// Simulate workers completing immediately when published, which used to permit
// the first source to commit before the second source had even been registered.
test('a fast first worker cannot commit while later sources are still being scheduled', async () => {
  const pending = new Set();
  const completionCounts = [];
  const jobs = ['video-a', 'video-b', 'image-c'].map(id => ({ process: { _id: id } }));
  await dispatchProcessBatch(jobs, {
    create: async process => { pending.add(process._id); return process; },
    remove: async process => pending.delete(process._id),
    send: async job => {
      pending.delete(job.process._id);
      completionCounts.push(pending.size);
    },
  });
  assert.deepEqual(completionCounts, [2, 1, 0]);
});

test('registration failure starts no workers and rolls back only newly registered jobs', async () => {
  const pending = new Set(['previous-run']);
  const published = [];
  const jobs = ['first', 'failing', 'last'].map(id => ({ process: { _id: id } }));
  await assert.rejects(dispatchProcessBatch(jobs, {
    create: async process => {
      if (process._id === 'failing') throw new Error('database unavailable');
      pending.add(process._id);
      return process;
    },
    remove: async process => pending.delete(process._id),
    send: async job => published.push(job),
  }), /database unavailable/);
  assert.deepEqual(published, []);
  assert.deepEqual([...pending], ['previous-run']);
});

test('dispatch failure rolls back only this batch and stops later sends', async () => {
  const pending = new Set(['unrelated']);
  const published = [];
  const jobs = ['first', 'second', 'third'].map(id => ({ process: { _id: id } }));
  await assert.rejects(dispatchProcessBatch(jobs, {
    create: async process => { pending.add(process._id); return process; },
    remove: async process => pending.delete(process._id),
    send: async job => {
      published.push(job.process._id);
      if (job.process._id === 'second') throw new Error('broker unavailable');
    },
  }), /broker unavailable/);
  assert.deepEqual(published, ['first', 'second']);
  assert.deepEqual([...pending], ['unrelated']);
});

test('out-of-order results wait for every result before committing once', async () => {
  const pending = new Set(['video-a', 'video-b']);
  const stored = [];
  const commits = [];
  const settle = process => persistAndSettleProcess(process, {
    persistResult: async job => { stored.push(job._id); },
    isCurrent: async () => true,
    remove: async job => pending.delete(job._id),
    countPending: async () => pending.size,
    commit: async job => { commits.push(job._id); return { committedToken: 4 }; },
  });

  const second = await settle({ _id: 'video-b', project_id: 'project', token: 4 });
  assert.equal(second.remaining, 1);
  assert.equal(second.committed, false);
  assert.deepEqual(commits, []);

  const first = await settle({ _id: 'video-a', project_id: 'project', token: 4 });
  assert.equal(first.remaining, 0);
  assert.equal(first.committed, true);
  assert.deepEqual(stored, ['video-b', 'video-a']);
  assert.deepEqual(commits, ['video-a']);
});

test('cancelled run removes stale result and never commits', async () => {
  let removed = false;
  let cleaned = false;
  let committed = false;
  const result = await persistAndSettleProcess(
    { _id: 'video-a', project_id: 'project', token: 4 },
    {
      persistResult: async () => {},
      isCurrent: async () => false,
      remove: async () => { removed = true; },
      countPending: async () => 0,
      commit: async () => { committed = true; return true; },
      cleanupStale: async () => { cleaned = true; },
    },
  );
  assert.deepEqual(result, { stale: true, remaining: null, committed: false });
  assert.equal(removed, true);
  assert.equal(cleaned, true);
  assert.equal(committed, false);
});

test('only the active current run can commit results and terminal status', async () => {
  const modelPath = require.resolve('../models/project');
  const controllerPath = require.resolve('../controllers/project');
  const originalModel = require.cache[modelPath];
  const originalController = require.cache[controllerPath];
  const state = {
    user_id: 'owner', _id: 'project', activeToken: 8, committedToken: 6,
    processingRun: {
      runToken: 8, state: 'running', outcome: null,
      startedAt: new Date('2026-11-17T12:00:00Z'),
      updatedAt: new Date('2026-11-17T12:00:00Z'), finishedAt: null,
      videos: [{ mediaId: 'video', progress: 70, preview: false, updatedAt: new Date() }],
    },
  };
  require.cache[modelPath] = { id: modelPath, filename: modelPath, loaded: true, exports: {
    findOne(filter) {
      return { exec: async () => state.activeToken === filter.activeToken ? { ...state } : null };
    },
    findOneAndUpdate(filter, update) {
      return { exec: async () => {
        if (state.activeToken !== filter.activeToken
          || state.processingRun.runToken !== filter['processingRun.runToken']
          || state.processingRun.state !== filter['processingRun.state']) return null;
        for (const [key, value] of Object.entries(update.$set)) {
          const parts = key.split('.');
          let target = state;
          while (parts.length > 1) target = target[parts.shift()];
          target[parts[0]] = value;
        }
        for (const [key, value] of Object.entries(update.$inc || {})) {
          state[key] = (state[key] || 0) + value;
        }
        return { ...state };
      }};
    },
  }};
  delete require.cache[controllerPath];
  try {
    const Project = require('../controllers/project');
    assert.equal(await Project.commitRunIfActive('owner', 'project', 7, []), null);
    assert.equal(state.committedToken, 6);
    const result = await Project.commitRunIfActive('owner', 'project', 8, [{ procedure: 'extract_frames' }]);
    assert.equal(result.committedToken, 8);
    assert.equal(result.resultsToken, 8);
    assert.equal(result.processingRun.state, 'completed');
    assert.equal(result.processingRun.outcome, 'completed');
    assert.equal(result.processingRun.videos[0].progress, 100);
    assert.equal(await Project.commitRunIfActive('owner', 'project', 8, []), null);

    state.activeToken = 9;
    state.processingRun = startProcessingRun(9, ['video'], new Date());
    const failed = await Project.failRunIfActive('owner', 'project', 9);
    assert.equal(failed.processingRun.state, 'failed');
    assert.equal(failed.processingRun.outcome, 'failed');
    assert.equal(failed.activeToken, 10);
    assert.equal(await Project.failRunIfActive('owner', 'project', 9), null);
  } finally {
    if (originalModel) require.cache[modelPath] = originalModel; else delete require.cache[modelPath];
    if (originalController) require.cache[controllerPath] = originalController; else delete require.cache[controllerPath];
  }
});
