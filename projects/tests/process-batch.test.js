const test = require('node:test');
const assert = require('node:assert/strict');
const { dispatchProcessBatch } = require('../utils/processBatch');
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
    assert.equal(await Project.failRunIfActive('owner', 'project', 9), null);
  } finally {
    if (originalModel) require.cache[modelPath] = originalModel; else delete require.cache[modelPath];
    if (originalController) require.cache[controllerPath] = originalController; else delete require.cache[controllerPath];
  }
});
