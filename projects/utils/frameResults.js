const fs = require('fs');
const path = require('path');

// Validate every file before uploading anything, and keep each video's names unique
// in the shared result ZIP. Paths must stay inside this job's output directory.
function frameFiles(output, process, appRoot = path.resolve(__dirname, '..')) {
  if (!Array.isArray(output.frames) || output.frames.length < 1 || output.frames.length > 100) {
    throw new Error('Frame extraction must return between 1 and 100 images');
  }
  const parent = fs.realpathSync(path.dirname(path.resolve(appRoot, process.new_img_uri)));
  const directory = fs.realpathSync(path.resolve(appRoot, output.imageURI));
  if (!directory.startsWith(parent + path.sep) || !fs.statSync(directory).isDirectory()) {
    throw new Error('Invalid frame output directory');
  }
  const seen = new Set();
  return output.frames.map((frame) => {
    if (typeof frame.file !== 'string' || !Number.isFinite(frame.time) || frame.time < 0) {
      throw new Error('Invalid extracted frame');
    }
    const file = fs.realpathSync(path.resolve(appRoot, frame.file));
    if (!file.startsWith(directory + path.sep) || !fs.statSync(file).isFile() ||
        !/\.(png|jpe?g)$/i.test(file) || seen.has(file)) {
      throw new Error('Invalid extracted frame path');
    }
    seen.add(file);
    return { file, name: `${process.img_id}-${path.basename(file)}` };
  });
}

async function persistFrameResults(output, process, persist, appRoot) {
  const files = frameFiles(output, process, appRoot);
  for (const [index, { file, name }] of files.entries()) {
    await persist({ file, name, type: 'image', slot: `frame-${index}` });
  }
}

module.exports = { frameFiles, persistFrameResults };
