var Project = require("../models/project");
const ProjectModel = require("../models/project");
const { finishProcessingRun } = require("../utils/processingRun");

// DELETE condicional por versão
module.exports.deleteIfVersion = async (user_id, project_id, expectedVersion) => {
  const res = await Project.deleteOne({
    user_id: user_id,
    _id: project_id,
    version: expectedVersion,
  });

  return res.deletedCount === 1;
};

// Adicionar share link (atómico + versão)
module.exports.addShareLinkIfVersion = async (
  user_id,
  project_id,
  newLink,
  expectedVersion
) => {
  return await Project.findOneAndUpdate(
    { user_id: user_id, _id: project_id, version: expectedVersion },
    { $push: { sharedLinks: newLink }, $inc: { version: 1 } },
    { new: true }
  ).exec();
};

// Revogar share link (atómico + versão)
module.exports.revokeShareLinkIfVersion = async (
  user_id,
  project_id,
  shareId,
  expectedVersion
) => {
  return await Project.findOneAndUpdate(
    {
      user_id: user_id,
      _id: project_id,
      version: expectedVersion,
      "sharedLinks.id": shareId,
    },
    { $set: { "sharedLinks.$.revoked": true }, $inc: { version: 1 } },
    { new: true }
  ).exec();
};

module.exports.getAll = async (user_id) => {
  return await Project.find({ user_id: user_id }).sort({ _id: 1 }).exec();
};

module.exports.getOne = async (user_id, project_id, { includeQuota = false } = {}) => {
  const query = Project.findOne({ user_id: user_id, _id: project_id });
  if (includeQuota) query.select("+processingQuota");
  return query.exec();
};

module.exports.create = async (project) => {
  return await Project.create(project);
};

module.exports.update = (user_id, project_id, project) => {
  return Project.updateOne({ user_id: user_id, _id: project_id }, project);
};

module.exports.delete = (user_id, project_id) => {
  return Project.deleteOne({ user_id: user_id, _id: project_id });
};

// Devolve o projeto que contém este shareId
module.exports.getOneByShareId = (shareId) =>
  Project.findOne({ "sharedLinks.id": shareId }).exec();

module.exports.updateIfVersion = async (user_id, project_id, project, expectedVersion, conditions = {}) => {
  // Worker updates do not increment the editor's version. Copy only the
  // fields changed by this request so stale snapshots cannot overwrite them.
  const modified = new Set(project.directModifiedPaths().map(path => path.split(".", 1)[0]));
  const { _id, user_id: _uid, version, __v, sharedLinks, ...fields } = project.toObject();
  const changes = Object.fromEntries(Object.entries(fields).filter(([name]) => modified.has(name)));

  return await Project.findOneAndUpdate(
    { user_id: user_id, _id: project_id, version: expectedVersion, ...conditions },
    { $set: changes, $inc: { version: 1 } },
    { new: true } // devolve documento já com versão incrementada
  ).exec();
};

module.exports.updateRaw = async (user_id, project_id, update) => {
  return await ProjectModel.updateOne(
    { user_id, _id: project_id },
    update
  ).exec();
};

module.exports.updateVideoProgressIfActive = async ({
  userId, projectId, runToken, mediaId, percent, preview, timestamp,
}) => {
  return Project.findOneAndUpdate(
    {
      user_id: userId,
      _id: projectId,
      activeToken: runToken,
      "processingRun.runToken": runToken,
      "processingRun.state": "running",
      "processingRun.videos": {
        $elemMatch: {
          mediaId: String(mediaId),
          progress: { $lt: percent },
          updatedAt: { $lte: timestamp },
        },
      },
    },
    {
      $max: { "processingRun.updatedAt": timestamp },
      $set: {
        "processingRun.videos.$.progress": percent,
        "processingRun.videos.$.preview": preview,
        "processingRun.videos.$.updatedAt": timestamp,
      },
    },
    { new: true }
  ).exec();
};


// Commit only if cancellation/new processing has not changed the active run.
module.exports.commitRunIfActive = async (user_id, project_id, token, tools) => {
  const current = await Project.findOne({ user_id, _id: project_id, activeToken: token }).exec();
  if (!current) return null;

  const processingRun = current.processingRun;
  const hasCurrentRun = processingRun && processingRun.runToken === token;
  const nextRun = hasCurrentRun
    ? finishProcessingRun(processingRun, token, "completed")
    : null;

  // A failed run must never be changed to completed by a slower sibling job.
  if (hasCurrentRun && !nextRun) return null;

  const filter = { user_id, _id: project_id, activeToken: token };
  const update = {
    committedToken: token,
    resultsToken: token,
    committedTools: tools,
  };
  if (hasCurrentRun) {
    filter["processingRun.runToken"] = token;
    filter["processingRun.state"] = "running";
    update.processingRun = nextRun;
  } else {
    // Backward compatibility for runs that were already in flight during rollout.
    filter["processingRun.runToken"] = { $exists: false };
  }

  return Project.findOneAndUpdate(
    filter,
    { $set: update },
    { new: true }
  ).exec();
};

module.exports.failRunIfActive = async (user_id, project_id, token) => {
  const now = new Date();
  return Project.findOneAndUpdate(
    {
      user_id,
      _id: project_id,
      activeToken: token,
      "processingRun.runToken": token,
      "processingRun.state": "running",
    },
    { $set: {
      "processingRun.state": "failed",
      "processingRun.outcome": "failed",
      "processingRun.updatedAt": now,
      "processingRun.finishedAt": now,
    }, $inc: { activeToken: 1 } },
    { new: true }
  ).exec();
};
