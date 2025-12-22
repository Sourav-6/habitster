const undoMap = new Map();

function setUndo(userId, data) {
  undoMap.set(userId, data);
}

function getUndo(userId) {
  return undoMap.get(userId);
}

function clearUndo(userId) {
  undoMap.delete(userId);
}

module.exports = { setUndo, getUndo, clearUndo };
