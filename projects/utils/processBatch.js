// Publish only after every source has a persisted Process record. A fast worker
// must never see an incomplete batch when deciding whether the run is finished.
async function dispatchProcessBatch(jobs, { create, remove, send }) {
  const created = [];
  try {
    for (const job of jobs) created.push(await create(job.process));
    for (const job of jobs) await send(job);
  } catch (error) {
    await Promise.allSettled(created.map(remove));
    throw error;
  }
}

// Keep each Process row until its output is stored. Concurrent completions can
// both see zero pending rows. The conditional commit allows only one to win.
async function persistAndSettleProcess(process, {
  persistResult,
  isCurrent,
  remove,
  countPending,
  commit,
  cleanupStale,
}) {
  await persistResult(process);

  if (isCurrent && !(await isCurrent(process))) {
    await remove(process);
    if (cleanupStale) await cleanupStale(process);
    return { stale: true, remaining: null, committed: false };
  }

  await remove(process);
  const remaining = await countPending(process.project_id, process.token || 0);
  if (remaining > 0) return { stale: false, remaining, committed: false };

  const committed = await commit(process);
  if (!committed && cleanupStale) await cleanupStale(process);
  return { stale: !committed, remaining: 0, committed: Boolean(committed) };
}

module.exports = { dispatchProcessBatch, persistAndSettleProcess };
