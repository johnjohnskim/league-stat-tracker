function parseDataset({ dataset: { x, y } }) {
  return { x: x / 1000, y: +y };
}

function formatDuration(duration) {
  const minutes = Math.floor(duration / 60);
  const seconds = duration % 60 <= 1 ? 0 : duration % 60;
  return `${minutes}:${seconds < 10 ? "0" : ""}${seconds}`;
}

export { parseDataset, formatDuration };
