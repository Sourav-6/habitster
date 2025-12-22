const pending = new Map();

function setPending(userId, action) {
  pending.set(userId, action);
}

function getPending(userId) {
  return pending.get(userId);
}

function clearPending(userId) {
  pending.delete(userId);
}

module.exports = { setPending, getPending, clearPending };
