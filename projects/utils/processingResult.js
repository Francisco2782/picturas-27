async function persistProcessingResult(process, output, { find, upload, create, removeImage }) {
  const deliveryKey = `${process._id}:${output.slot}`;
  if (await find(deliveryKey)) return;

  const key = await upload(output.file, output.name);
  try {
    await create({
      type: output.type,
      file_name: output.name,
      img_key: key,
      img_id: process.img_id,
      project_id: process.project_id,
      user_id: process.user_id,
      token: process.token || 0,
      delivery_key: deliveryKey,
    });
  } catch (error) {
    // A concurrent delivery may already own the result. Only discard this upload.
    const alreadyStored = error.code === 11000 && error.keyPattern?.delivery_key === 1;
    if (alreadyStored || error.name === 'ValidationError') {
      try {
        await removeImage(key);
      } catch (cleanupError) {
        console.error('Error removing unused processing output:', cleanupError.message);
      }
    }
    if (!alreadyStored) throw error;
  }
}

module.exports = { persistProcessingResult };
