const { Databases, Query, ID } = require("node-appwrite");
const client = require("../appwriteClient");
const pendingActions = require("./pendingActions");
const databases = new Databases(client);
const fetch = (...args) =>
  import("node-fetch").then(({ default: fetch }) => fetch(...args));

const DATABASE_ID = "68f3c29000072cae03e0";
const TASKS_COLLECTION_ID = "tasks-storage";
const HABITS_COLLECTION_ID = "habits-storage";
const undoStore = require("./undoStore");
const agentMemory = require("./agentMemory");

async function callLLM(systemPrompt, messages) {
  const response = await fetch("http://localhost:11434/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "phi3:latest",
      messages: [
        { role: "system", content: systemPrompt },
        ...messages.map((m) => ({
          role: m.role,
          content: m.content,
        })),
      ],
      stream: false,
    }),
  });

  const data = await response.json();
  return data.message?.content || "I’m thinking… try again.";
}

function isCompletedToday(habit) {
  if (!habit.lastCompletedDate) return false;
  const today = new Date();
  const completed = new Date(habit.lastCompletedDate);
  return (
    completed.getUTCFullYear() === today.getUTCFullYear() &&
    completed.getUTCMonth() === today.getUTCMonth() &&
    completed.getUTCDate() === today.getUTCDate()
  );
}

async function processMessage(userId, message, context = []) {
  const msg = message.toLowerCase().trim();

  // -------- HABIT COMPLETION VIA CHAT --------
  if (
    msg.includes("completed") ||
    msg.includes("done") ||
    msg.includes("finished")
  ) {
    const habitsRes = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [Query.equal("userId", userId)]
    );

    const matched = habitsRes.documents.find((h) =>
      msg.includes(h.habitName.toLowerCase())
    );

    if (!matched) {
      return "Which habit did you complete?";
    }

    // already completed today?
    if (isCompletedToday(matched)) {
      return `You already completed "${matched.habitName}" today 👍`;
    }

    pendingActions.setPending(userId, {
      execute: async () => {
        // mark habit completed (reuse your existing logic)
        await databases.updateDocument(
          DATABASE_ID,
          HABITS_COLLECTION_ID,
          matched.$id,
          {
            lastCompletedDate: new Date().toISOString(),
            currentStreak: (matched.currentStreak || 0) + 1,
          }
        );
      },
      successMessage: `"${matched.habitName}" marked as completed for today.`,
    });

    return `Nice! Want me to mark "${matched.habitName}" as completed for today? (yes / no)`;
  }

  // -------- HABIT DELETE VIA CHAT --------
  if (msg.startsWith("delete habit") || msg.startsWith("remove habit")) {
    const raw = msg
      .replace("delete habit", "")
      .replace("remove habit", "")
      .trim();

    if (!raw) return "Which habit do you want to delete?";

    const habitsRes = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [Query.equal("userId", userId)]
    );

    const habit = habitsRes.documents.find((h) =>
      raw.includes(h.habitName.toLowerCase())
    );

    if (!habit) {
      return `I couldn’t find a habit named "${raw}".`;
    }

    pendingActions.setPending(userId, {
      execute: async () => {
        await databases.deleteDocument(
          DATABASE_ID,
          HABITS_COLLECTION_ID,
          habit.$id
        );

        undoStore.setUndo(userId, {
          collectionId: HABITS_COLLECTION_ID,
          documentId: habit.$id,
        });
      },
      successMessage: `Habit "${habit.habitName}" deleted. Type "undo" to restore.`,
    });

    return `Are you sure you want to delete "${habit.habitName}"? (yes / no)`;
  }

  // -------- PENDING ACTIONS --------

  const pending = pendingActions.getPending(userId);

  if (pending) {
    if (msg === "yes") {
      pendingActions.clearPending(userId);
      await pending.execute();
      return pending.successMessage;
    }

    if (msg === "no") {
      pendingActions.clearPending(userId);
      return "Okay, cancelled.";
    }

    return "Please reply with yes or no.";
  }

  // If user is chatting normally → use LLM
  if (
    !msg.startsWith("add") &&
    !msg.startsWith("create") &&
    !msg.startsWith("update") &&
    !msg.startsWith("undo")
  ) {
    const historyText = context.map((c) => ({
      role: c.role === "user" ? "user" : "assistant",
      content: c.text,
    }));

    agentMemory.updateMemory(userId, message);
    const mem = agentMemory.getMemory(userId);

    const habitsRes = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [Query.equal("userId", userId)]
    );

    const tasksRes = await databases.listDocuments(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      [Query.equal("userId", userId)]
    );

    const habitContext = habitsRes.documents.map((h) => {
      const completedToday = isCompletedToday(h);
      return `- ${h.habitName} (streak: ${h.currentStreak}, completed today: ${
        completedToday ? "yes" : "no"
      })`;
    });

    const taskContext = tasksRes.documents.map((t) => {
      return `- ${t.taskName} (${t.isRecurring ? "recurring" : "one-time"})`;
    });

    const systemPrompt = `
      You are Habitster Coach.

      User habits:
      ${habitContext.length ? habitContext.join("\n") : "No habits"}

      User tasks:
      ${taskContext.length ? taskContext.join("\n") : "No tasks"}

      User struggles: ${mem.struggles.join(", ") || "unknown"}
      User goals: ${mem.goals.join(", ") || "unknown"}

      Use habits/tasks ONLY if relevant.

     Identity:
        - You are an AI habit coach built specifically for the Habitster app.
        - You help users build habits, stay consistent, and reflect.
        - You were designed and built by Safeer, a friend of Uviaz, the CEO of Habitster.

      Core principles (habit psychology):
        - Consistency beats intensity.
        - Motivation follows action, not the other way around.
        - Habits fail when they are too big, not when people are weak.
        - Missed days are feedback, not failure.
        - Environment and cues matter more than willpower.

      Rules:
        - Introduce yourself only if the user asks who you are.
        - If asked who created you, say you were built by the creators of Habitster.
        - Do not exaggerate abilities.
        - Do not claim consciousness, emotions, or authority.
        - Do NOT mention being an LLM unless explicitly asked.
        - Speak like a calm, supportive human coach.

      How you should respond:
        - Speak like a calm, supportive human coach.
        - Be practical, not philosophical.
        - Give small, actionable suggestions.
        - Explain causes in simple terms when helpful.
        - Encourage restarting gently after breaks.
        - Praise consistency, not perfection.
        - Never invent data.

      Context:
        - User habits and tasks are provided for awareness.
        - Use them only when relevant.
        - If a user mentions feeling better, sharper, or more focused,
          consider whether existing habits could explain it.
        - If a user says they completed something,
          ask whether they want it marked complete in the app.
      `;

    return await callLLM(
      systemPrompt,
      historyText.concat({
        role: "user",
        content: message,
      })
    );
  }

  // -------- UNDO ACTION --------
  if (msg === "undo") {
    const undo = undoStore.getUndo(userId);
    if (!undo) return "Nothing to undo.";

    await databases.deleteDocument(
      DATABASE_ID,
      undo.collectionId,
      undo.documentId
    );

    undoStore.clearUndo(userId);
    return "Last action undone.";
  }

  // -------- HABIT UPDATE --------
  if (msg.startsWith("update habit") || msg.startsWith("change habit")) {
    let raw = msg
      .replace("update habit", "")
      .replace("change habit", "")
      .trim();

    if (!raw) return "Tell me which habit to update.";

    // Split: "habitName to schedule"
    const parts = raw.split(" to ");
    if (parts.length < 2) {
      return "Use format: change habit <name> to <schedule>";
    }

    const habitName = parts[0].trim();
    const schedule = parts[1].trim();

    // Fetch habit
    const response = await databases.listDocuments(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      [Query.equal("userId", userId), Query.equal("habitName", habitName)]
    );

    if (response.documents.length === 0) {
      return `I couldn’t find a habit named "${habitName}".`;
    }

    let frequencyType = "daily";
    let frequencyValue = null;

    // every X days
    const everyMatch = schedule.match(/every (\d+) days?/);
    if (everyMatch) {
      frequencyType = "every_x_days";
      frequencyValue = everyMatch[1];
    }

    // specific days
    if (
      schedule.includes("mon") ||
      schedule.includes("tue") ||
      schedule.includes("wed") ||
      schedule.includes("thu") ||
      schedule.includes("fri") ||
      schedule.includes("sat") ||
      schedule.includes("sun")
    ) {
      const map = { mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6, sun: 7 };
      const days = [];

      Object.keys(map).forEach((d) => {
        if (schedule.includes(d)) days.push(map[d]);
      });

      if (days.length > 0) {
        frequencyType = "specific_days";
        frequencyValue = JSON.stringify(days);
      }
    }

    // daily
    if (schedule.includes("daily")) {
      frequencyType = "daily";
      frequencyValue = null;
    }

    await databases.updateDocument(
      DATABASE_ID,
      HABITS_COLLECTION_ID,
      response.documents[0].$id,
      {
        frequencyType,
        frequencyValue,
      }
    );

    return `Habit "${habitName}" updated successfully.`;
  }

  // -------- TASK CREATION --------
  if (
    msg.startsWith("add task") ||
    msg.startsWith("create task") ||
    msg.startsWith("task:")
  ) {
    let raw = msg
      .replace("add task", "")
      .replace("create task", "")
      .replace("task:", "")
      .trim();

    if (!raw) return "Tell me what task to add.";

    let dueDate = new Date();
    let isRecurring = false;
    let recurrenceDays = null;

    // ---- time ----
    if (raw.includes("tomorrow")) {
      dueDate.setDate(dueDate.getDate() + 1);
      raw = raw.replace("tomorrow", "").trim();
    }

    // ---- recurrence ----
    if (raw.includes("every day") || raw.includes("daily")) {
      isRecurring = true;
      recurrenceDays = 1;
      raw = raw.replace("every day", "").replace("daily", "").trim();
    }

    const everyMatch = raw.match(/every (\d+) days?/);
    if (everyMatch) {
      isRecurring = true;
      recurrenceDays = parseInt(everyMatch[1]);
      raw = raw.replace(everyMatch[0], "").trim();
    }

    if (raw.includes("weekly")) {
      isRecurring = true;
      recurrenceDays = 7;
      raw = raw.replace("weekly", "").trim();
    }

    dueDate.setHours(23, 59, 0, 0);
    const taskName = raw;

    pendingActions.setPending(userId, {
      execute: async () => {
        const doc = await databases.createDocument(
          DATABASE_ID,
          TASKS_COLLECTION_ID,
          ID.unique(),
          {
            taskName,
            dueDate: dueDate.toISOString(),
            priority: 0,
            label: null,
            isRecurring,
            recurrenceDays,
            userId,
          }
        );

        undoStore.setUndo(userId, {
          collectionId: TASKS_COLLECTION_ID,
          documentId: doc.$id,
        });
      },
      successMessage: `Task "${taskName}" created. Type "undo" to revert.`,
    });

    return `Do you want me to create the task "${taskName}"? (yes / no)`;
  }

  // -------- TASK UPDATE --------
  if (msg.startsWith("update task") || msg.startsWith("change task")) {
    let raw = msg.replace("update task", "").replace("change task", "").trim();

    if (!raw) return "Tell me which task to update.";

    const parts = raw.split(" to ");
    if (parts.length < 2) {
      return "Use format: update task <name> to <schedule>";
    }

    const taskName = parts[0].trim();
    const schedule = parts[1].trim();

    const response = await databases.listDocuments(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      [Query.equal("userId", userId), Query.equal("taskName", taskName)]
    );

    if (response.documents.length === 0) {
      return `I couldn’t find a task named "${taskName}".`;
    }

    let dueDate = new Date();
    let isRecurring = false;
    let recurrenceDays = null;

    // tomorrow
    if (schedule.includes("tomorrow")) {
      dueDate.setDate(dueDate.getDate() + 1);
    }

    // every X days
    const everyMatch = schedule.match(/every (\d+) days?/);
    if (everyMatch) {
      isRecurring = true;
      recurrenceDays = parseInt(everyMatch[1]);
    }

    // weekly
    if (schedule.includes("weekly")) {
      isRecurring = true;
      recurrenceDays = 7;
    }

    // daily
    if (schedule.includes("daily")) {
      isRecurring = true;
      recurrenceDays = 1;
    }

    dueDate.setHours(23, 59, 0, 0);

    await databases.updateDocument(
      DATABASE_ID,
      TASKS_COLLECTION_ID,
      response.documents[0].$id,
      {
        dueDate: dueDate.toISOString(),
        isRecurring,
        recurrenceDays,
      }
    );

    return `Task "${taskName}" updated successfully.`;
  }

  // -------- HABIT CREATION --------
  if (
    msg.startsWith("create habit") ||
    msg.startsWith("start habit") ||
    msg.startsWith("habit:")
  ) {
    const raw = msg
      .replace("create habit", "")
      .replace("start habit", "")
      .replace("habit:", "")
      .trim();

    if (!raw) return "Tell me the habit name.";

    let habitName = raw;
    let frequencyType = "daily";
    let frequencyValue = null;

    // ---- detect frequency ----
    if (raw.includes("every")) {
      const match = raw.match(/every (\d+) days?/);
      if (match) {
        frequencyType = "every_x_days";
        frequencyValue = match[1];
        habitName = raw.replace(match[0], "").trim();
      }
    }

    if (
      raw.includes("mon") ||
      raw.includes("tue") ||
      raw.includes("wed") ||
      raw.includes("thu") ||
      raw.includes("fri") ||
      raw.includes("sat") ||
      raw.includes("sun")
    ) {
      const map = {
        mon: 1,
        tue: 2,
        wed: 3,
        thu: 4,
        fri: 5,
        sat: 6,
        sun: 7,
      };

      const days = [];
      Object.keys(map).forEach((d) => {
        if (raw.includes(d)) days.push(map[d]);
      });

      if (days.length > 0) {
        frequencyType = "specific_days";
        frequencyValue = JSON.stringify(days);
        habitName = raw.replace(/mon|tue|wed|thu|fri|sat|sun/g, "").trim();
      }
    }

    pendingActions.setPending(userId, {
      execute: async () => {
        const doc = await databases.createDocument(
          DATABASE_ID,
          HABITS_COLLECTION_ID,
          ID.unique(),
          {
            userId,
            habitName,
            startDate: new Date().toISOString(),
            durationValue: 30,
            durationUnit: "days",
            frequencyType,
            frequencyValue,
            currentStreak: 0,
            longestStreak: 0,
            lastCompletedDate: null,
            nextDueDate: new Date().toISOString(),
            isHidden: false,
          }
        );

        undoStore.setUndo(userId, {
          collectionId: HABITS_COLLECTION_ID,
          documentId: doc.$id,
        });
      },

      successMessage: `Habit "${habitName}" created. Type "undo" to revert.`,
    });

    return `Do you want me to create the habit "${habitName}"? (yes / no)`;
  }
}

async function autoIntervene(userId) {
  const habits = await databases.listDocuments(
    DATABASE_ID,
    HABITS_COLLECTION_ID,
    [Query.equal("userId", userId)]
  );

  if (habits.documents.length === 0) return null;

  const broken = habits.documents.filter((h) => h.currentStreak === 0);
  const active = habits.documents.filter((h) => h.currentStreak > 0);

  if (broken.length > 0) {
    return "Looks like a habit was missed recently. Want to restart today with something small?";
  }

  const maxStreak = Math.max(...active.map((h) => h.currentStreak));
  if (maxStreak >= 5) {
    return "Your consistency is building nicely. Keep it steady today.";
  }

  return null;
}

module.exports = { processMessage, autoIntervene };
