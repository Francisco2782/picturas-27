const test = require('node:test');
const assert = require('node:assert/strict');
const {
  startProcessingRun,
  applyVideoProgress,
  finishProcessingRun,
} = require('../utils/processingRun');

test('a run starts with a timestamped snapshot for each unique video', () => {
  const now = new Date('2026-11-17T12:00:00.000Z');
  const run = startProcessingRun(4, ['video-a', 'video-b', 'video-a'], now);

  assert.equal(run.runToken, 4);
  assert.equal(run.state, 'running');
  assert.equal(run.outcome, null);
  assert.equal(run.startedAt, now);
  assert.deepEqual(run.videos.map(video => video.mediaId), ['video-a', 'video-b']);
  assert.deepEqual(run.videos.map(video => video.progress), [0, 0]);
});

test('video progress accepts only current-run, known-media, monotonic integer updates', () => {
  const started = startProcessingRun(8, ['video-a'], new Date('2026-11-17T12:00:00Z'));
  const accepted = applyVideoProgress(started, {
    runToken: 8,
    mediaId: 'video-a',
    progress: 42,
    preview: true,
    timestamp: '2026-11-17T12:00:01Z',
  });

  assert.equal(accepted.accepted, true);
  assert.equal(accepted.run.videos[0].progress, 42);
  assert.equal(accepted.run.videos[0].preview, true);
  assert.equal(accepted.run.videos[0].updatedAt.toISOString(), '2026-11-17T12:00:01.000Z');

  for (const observation of [
    { runToken: 7, mediaId: 'video-a', progress: 70 },
    { runToken: 8, mediaId: 'video-other', progress: 70 },
    { runToken: 8, mediaId: 'video-a', progress: 41 },
    { runToken: 8, mediaId: 'video-a', progress: 42 },
    { runToken: 8, mediaId: 'video-a', progress: 43, timestamp: '2026-11-17T11:59:59Z' },
    { runToken: 8, mediaId: 'video-a', progress: 101 },
    { runToken: 8, mediaId: 'video-a', progress: 42.5 },
  ]) {
    assert.equal(applyVideoProgress(accepted.run, observation).accepted, false);
  }
  assert.equal(accepted.run.videos[0].progress, 42);
});

test('terminal outcomes are final for a run, and success completes media progress', () => {
  const run = startProcessingRun(9, ['video-a', 'video-b']);
  const complete = finishProcessingRun(run, 9, 'completed', '2026-11-17T12:00:10Z');

  assert.equal(complete.state, 'completed');
  assert.equal(complete.outcome, 'completed');
  assert.equal(complete.finishedAt.toISOString(), '2026-11-17T12:00:10.000Z');
  assert.deepEqual(complete.videos.map(video => video.progress), [100, 100]);
  assert.equal(finishProcessingRun(complete, 9, 'failed'), null);
  assert.equal(finishProcessingRun(run, 8, 'cancelled'), null);
});

test('failure and cancellation retain a terminal outcome and may be replaced only by a newer run', () => {
  const run = startProcessingRun(10, ['video-a']);
  const failed = finishProcessingRun(run, 10, 'failed');
  assert.equal(failed.state, 'failed');
  assert.equal(failed.outcome, 'failed');
  assert.equal(finishProcessingRun(failed, 10, 'completed'), null);

  const cancelled = finishProcessingRun(run, 10, 'cancelled');
  assert.equal(cancelled.state, 'cancelled');
  assert.equal(cancelled.outcome, 'cancelled');

  const next = startProcessingRun(11, ['video-b']);
  assert.equal(next.runToken, 11);
  assert.deepEqual(next.videos.map(video => video.mediaId), ['video-b']);
});

test('invalid lifecycle inputs are rejected', () => {
  assert.throws(() => startProcessingRun(0), /positive safe integer/);
  const run = startProcessingRun(12, ['video-a']);
  assert.throws(() => finishProcessingRun(run, 12, 'running'), /Invalid processing run outcome/);
  assert.throws(() => finishProcessingRun(run, 12, 'failed', 'not-a-date'), /valid date/);
});

test('project model validates the durable run snapshot without requiring a database', async () => {
  const Project = require('../models/project');
  const ownerId = new (require('mongoose').Types.ObjectId)();
  const valid = new Project({
    name: 'status-test',
    user_id: ownerId,
    processingRun: startProcessingRun(13, ['video-a']),
  });
  await valid.validate();
  assert.equal(valid.processingRun.state, 'running');

  const invalid = new Project({
    name: 'status-test-invalid',
    user_id: ownerId,
    processingRun: { ...startProcessingRun(14), state: 'unknown' },
  });
  await assert.rejects(invalid.validate(), /processingRun.state/);
});
