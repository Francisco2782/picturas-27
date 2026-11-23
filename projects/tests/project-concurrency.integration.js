const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const Project = require('../controllers/project');
const { startProcessingRun } = require('../utils/processingRun');

const userId = new mongoose.Types.ObjectId();
const startedAt = new Date('2026-11-23T10:00:00Z');
const later = new Date('2026-11-23T10:00:10Z');
const earlier = new Date('2026-11-23T10:00:09Z');

test.before(async () => {
  await mongoose.connect(process.env.PICTURAS_TEST_MONGO_URI || 'mongodb://projects_mongoDB:27018', {
    dbName: 'picturas_concurrency_test',
    serverSelectionTimeoutMS: 5000,
  });
});

test.after(async () => mongoose.disconnect());

async function runningProject(t) {
  const project = await Project.create({
    user_id: userId, name: 'Before edit', version: 3, activeToken: 5,
    processingRun: startProcessingRun(5, ['video-a', 'video-b'], startedAt),
  });
  t.after(() => Project.delete(userId, project._id));
  return project;
}

function progress(project, mediaId, percent, timestamp) {
  return Project.updateVideoProgressIfActive({
    userId, projectId: project._id, runToken: 5, mediaId, percent, timestamp, preview: false,
  });
}

test('an older event can advance another video without regressing the run timestamp', async (t) => {
  const project = await runningProject(t);
  assert.ok(await progress(project, 'video-a', 30, later));
  assert.ok(await progress(project, 'video-b', 20, earlier));
  assert.equal(await progress(project, 'video-b', 25, startedAt), null);
  assert.equal(await progress(project, 'video-b', 20, later), null);

  const saved = await Project.getOne(userId, project._id);
  assert.equal(saved.processingRun.updatedAt.getTime(), later.getTime());
  assert.deepEqual(saved.processingRun.videos.map(({ progress }) => progress), [30, 20]);
  assert.equal(saved.processingRun.videos[1].updatedAt.getTime(), earlier.getTime());
});

test('an edit read before completion preserves the terminal snapshot and result tokens', async (t) => {
  const project = await runningProject(t);
  const edit = await Project.getOne(userId, project._id);
  edit.name = 'After edit';

  const tools = [{ procedure: 'brightness', position: 0, params: { brightness: 1.1 } }];
  const committed = await Project.commitRunIfActive(userId, project._id, 5, tools);
  assert.ok(committed);
  assert.equal(committed.version, edit.version);

  const saved = await Project.updateIfVersion(userId, project._id, edit, edit.version);
  assert.equal(saved.name, 'After edit');
  assert.equal(saved.version, 4);
  assert.equal(saved.processingRun.state, 'completed');
  assert.equal(saved.committedToken, 5);
  assert.equal(saved.resultsToken, 5);
  assert.equal(saved.committedTools[0].procedure, 'brightness');
  assert.deepEqual(saved.processingRun.videos.map(({ progress }) => progress), [100, 100]);
});

test('an edit read before failure preserves the failed run and invalidated token', async (t) => {
  const project = await runningProject(t);
  const edit = await Project.getOne(userId, project._id);
  edit.tools.push({ procedure: 'rotate', position: 0, params: { degrees: 90 } });

  assert.ok(await Project.failRunIfActive(userId, project._id, 5));
  const saved = await Project.updateIfVersion(userId, project._id, edit, edit.version);
  assert.equal(saved.tools[0].procedure, 'rotate');
  assert.equal(saved.activeToken, 6);
  assert.equal(saved.processingRun.state, 'failed');
  assert.equal(await progress(project, 'video-a', 80, later), null);
});
