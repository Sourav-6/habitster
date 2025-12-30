const memory = new Map();

function updateMemory(userId, message) {
  const text = message.toLowerCase();
  const m = memory.get(userId) || { struggles: [], goals: [] };

  if (text.includes("procrast") || text.includes("lazy")) {
    if (!m.struggles.includes("procrastination"))
      m.struggles.push("procrastination");
  }

  if (text.includes("discipline") || text.includes("consistent")) {
    if (!m.goals.includes("consistency"))
      m.goals.push("consistency");
  }

  memory.set(userId, m);
}

function getMemory(userId) {
  return memory.get(userId) || { struggles: [], goals: [] };
}

module.exports = { updateMemory, getMemory };
