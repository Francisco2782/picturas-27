const test = require('node:test');
const assert = require('node:assert/strict');
const { applyVideoProgress, startProcessingRun } = require('../utils/processingRun');
const { handleVideoProgress } = require('../utils/videoProgress');
const { settleDelivery } = require('../utils/rabbitDelivery');

function setup(overrides = {}) {
  const state = {
    process: {
      msg_id: 'request-source', user_id: 'owner', runner_id: 'editor',
      project_id: 'project', img_id: 'video-a', token: 5,
    },
    project: {
      activeToken: 5,
      processingRun: startProcessingRun(5, ['video-a'], new Date('2026-11-20T10:00:00Z')),
    },
    updates: 0,
    events: [],
  };
  const deps = {
    getProcess: async id => id === state.process.msg_id ? state.process : null,
    getProject: async () => state.project,
    updateProgress: async observation => {
      const next = applyVideoProgress(state.project.processingRun, {
        runToken: observation.runToken,
        mediaId: observation.mediaId,
        progress: observation.percent,
        preview: observation.preview,
        timestamp: observation.timestamp,
      });
      if (!next.accepted) return null;
      state.project.processingRun = next.run;
      state.updates += 1;
      return state.project;
    },
    publishProgress: event => state.events.push(event),
    ...overrides,
  };
  const message = {
    messageType: 'video-progress', sourceProcessId: 'request-source',
    projectId: 'project', mediaId: 'video-a', runToken: 5,
    percent: 25, preview: false, timestamp: '2026-11-20T10:00:01.000Z',
  };
  return { state, deps, message };
}

test('accepted progress is saved before the browser event is published', async () => {
  const { state, deps, message } = setup();
  const result = await handleVideoProgress(message, deps);
  assert.deepEqual(result, { accepted: true });
  assert.equal(state.project.processingRun.videos[0].progress, 25);
  assert.equal(state.updates, 1);
  assert.deepEqual(state.events, [{
    user: 'editor', projectId: 'project', imgId: 'video-a',
    preview: false, percent: 25, timestamp: message.timestamp, runToken: 5,
  }]);
});

test('duplicate and older progress are ignored without another browser event', async () => {
  const { state, deps, message } = setup();
  assert.equal((await handleVideoProgress(message, deps)).accepted, true);
  assert.equal((await handleVideoProgress(message, deps)).accepted, false);
  assert.equal((await handleVideoProgress({ ...message, percent: 20 }, deps)).accepted, false);
  assert.equal(state.updates, 1);
  assert.equal(state.events.length, 1);
});

test('stale, cancelled, wrong-project and wrong-media messages are ignored', async () => {
  const cases = [
    message => ({ ...message, runToken: 4 }),
    message => ({ ...message, projectId: 'other-project' }),
    message => ({ ...message, mediaId: 'other-video' }),
  ];
  for (const mutate of cases) {
    const { state, deps, message } = setup();
    assert.equal((await handleVideoProgress(mutate(message), deps)).accepted, false);
    assert.equal(state.events.length, 0);
  }

  const cancelled = setup();
  cancelled.state.project.activeToken = 6;
  assert.equal((await handleVideoProgress(cancelled.message, cancelled.deps)).accepted, false);
  assert.equal(cancelled.state.events.length, 0);

  const terminal = setup();
  terminal.state.project.processingRun.state = 'cancelled';
  assert.equal((await handleVideoProgress(terminal.message, terminal.deps)).accepted, false);
  assert.equal(terminal.state.events.length, 0);
});

test('malformed progress payloads are rejected before database or browser updates', async () => {
  const invalid = [
    { percent: 25.5 }, { percent: 101 }, { runToken: '5' },
    { preview: 'false' }, { timestamp: 'not-a-date' }, { sourceProcessId: '' },
  ];
  for (const fields of invalid) {
    const { state, deps, message } = setup();
    assert.equal((await handleVideoProgress({ ...message, ...fields }, deps)).accepted, false);
    assert.equal(state.updates, 0);
    assert.equal(state.events.length, 0);
  }
});

test('Rabbit delivery acks completed handlers and requeues failed handlers', async () => {
  const message = { content: Buffer.from('{}') };
  const settled = [];
  await settleDelivery(message, async () => {}, () => settled.push('ack'), () => settled.push('nack'));
  await settleDelivery(message, async () => { throw new Error('database unavailable'); },
    () => settled.push('ack'), () => settled.push('nack'));
  assert.deepEqual(settled, ['ack', 'nack']);
});

test('project progress update is conditional on the active token and a larger percentage', async () => {
  const modelPath = require.resolve('../models/project');
  const controllerPath = require.resolve('../controllers/project');
  const originalModel = require.cache[modelPath];
  const originalController = require.cache[controllerPath];
  let query;
  let update;
  require.cache[modelPath] = {
    id: modelPath, filename: modelPath, loaded: true,
    exports: {
      findOneAndUpdate(filter, change) {
        query = filter;
        update = change;
        return { exec: async () => ({ updated: true }) };
      },
    },
  };
  delete require.cache[controllerPath];
  try {
    const Project = require('../controllers/project');
    const timestamp = new Date('2026-11-20T10:00:02Z');
    const result = await Project.updateVideoProgressIfActive({
      userId: 'owner', projectId: 'project', runToken: 5,
      mediaId: 'video-a', percent: 50, preview: false, timestamp,
    });
    assert.deepEqual(result, { updated: true });
    assert.equal(query.user_id, 'owner');
    assert.equal(query._id, 'project');
    assert.equal(query.activeToken, 5);
    assert.equal(query['processingRun.state'], 'running');
    assert.equal(query['processingRun.videos'].$elemMatch.mediaId, 'video-a');
    assert.deepEqual(query['processingRun.videos'].$elemMatch.progress, { $lt: 50 });
    assert.deepEqual(update.$set['processingRun.videos.$.progress'], 50);
    assert.equal(update.$set['processingRun.videos.$.updatedAt'], timestamp);
  } finally {
    if (originalModel) require.cache[modelPath] = originalModel; else delete require.cache[modelPath];
    if (originalController) require.cache[controllerPath] = originalController; else delete require.cache[controllerPath];
  }
});
