const { Databases, Query, ID } = require("node-appwrite");
const client = require("../appwriteClient");
const pendingActions = require("./pendingActions");
const databases = new Databases(client);
const Groq = require("groq-sdk");
require("dotenv").config();

const DATABASE_ID = "68f3c29000072cae03e0";
const TASKS_COLLECTION_ID = "tasks-storage";
const HABITS_COLLECTION_ID = "habits-storage";
const undoStore = require("./undoStore");
const agentMemory = require("./agentMemory");

const groq = new Groq({ apiKey: (process.env.GROQ_API_KEY || "").trim() });

const tools = [
  {
    type: "function",
    function: {
      name: "createTask",
      description: "Create a new task with a name and due date.",
      parameters: {
        type: "object",
        properties: {
          taskName: { type: "string", description: "Name/title of the task" },
          dueDate: { type: "string", description: "ISO date string for when it's due" },
          isRecurring: { type: "boolean", description: "If the task repeats" },
          recurrenceDays: { type: "number", description: "Days between repeats" }
        },
        required: ["taskName", "dueDate"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "createHabit",
      description: "Start a new habit to track consistency.",
      parameters: {
        type: "object",
        properties: {
          habitName: { type: "string", description: "Name of the habit" },
          frequencyType: { type: "string", enum: ["daily", "specific_days", "every_x_days"] },
          frequencyValue: { type: "string", description: "E.g. '[1,3,5]' for specific_days" }
        },
        required: ["habitName", "frequencyType"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "listMyData",
      description: "Get current tasks and habits for context.",
      parameters: { type: "object", properties: {} }
    }
  },
  {
    type: "function",
    function: {
      name: "deleteTask",
      description: "Remove a task by its ID.",
      parameters: {
        type: "object",
        properties: {
          taskId: { type: "string" }
        },
        required: ["taskId"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "deleteHabit",
      description: "Remove a habit by its ID.",
      parameters: {
        type: "object",
        properties: {
          habitId: { type: "string" }
        },
        required: ["habitId"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "updateTask",
      description: "Update an existing task's properties.",
      parameters: {
        type: "object",
        properties: {
          taskId: { type: "string" },
          taskName: { type: "string" },
          dueDate: { type: "string" },
          priority: { type: "number" },
          isCompleted: { type: "boolean" }
        },
        required: ["taskId"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "completeTask",
      description: "Mark a task as completed.",
      parameters: {
        type: "object",
        properties: {
          taskId: { type: "string" }
        },
        required: ["taskId"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "updateHabit",
      description: "Update an existing habit's properties.",
      parameters: {
        type: "object",
        properties: {
          habitId: { type: "string" },
          habitName: { type: "string" },
          frequencyType: { type: "string" },
          frequencyValue: { type: "string" },
          difficulty: { type: "string" },
          category: { type: "string" }
        },
        required: ["habitId"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "completeHabit",
      description: "Mark a habit as completed for today, updating streaks and XP.",
      parameters: {
        type: "object",
        properties: {
          habitId: { type: "string" },
          notes: { type: "string" }
        },
        required: ["habitId"]
      }
    }
  }
];

function calculateNextDueDate(lastDueDate, frequencyType, frequencyValue) {
  let nextDate = new Date(lastDueDate);
  nextDate.setUTCHours(0, 0, 0, 0);
  switch (frequencyType) {
    case "daily": nextDate.setUTCDate(nextDate.getUTCDate() + 1); break;
    case "every_x_days":
      const days = parseInt(frequencyValue, 10);
      nextDate.setUTCDate(nextDate.getUTCDate() + (isNaN(days) ? 1 : days));
      break;
    case "specific_days":
      try {
        const scheduled = JSON.parse(frequencyValue || "[]").map(Number).map(d => d % 7).sort((a, b) => a - b);
        if (scheduled.length === 0) { nextDate.setUTCDate(nextDate.getUTCDate() + 1); break; }
        nextDate.setUTCDate(nextDate.getUTCDate() + 1);
        while (!scheduled.includes(nextDate.getUTCDay())) { nextDate.setUTCDate(nextDate.getUTCDate() + 1); }
      } catch (e) { nextDate.setUTCDate(nextDate.getUTCDate() + 1); }
      break;
    default: nextDate.setUTCDate(nextDate.getUTCDate() + 1);
  }
  return nextDate;
}

const GROQ_MODEL_FALLBACK = [
  "llama-3.3-70b-versatile",
  "llama-3.1-70b-versatile",
  "llama-3.1-8b-instant",
  "mixtral-8x7b-32768"
];

async function callLLM(userId, message, history = []) {
  let lastError = null;

  // Pre-flight: Fetch context so the AI knows IDs instantly
  let userContextString = "No current habits or tasks found.";
  try {
    const habits = await databases.listDocuments(DATABASE_ID, HABITS_COLLECTION_ID, [Query.equal("userId", userId)]);
    const tasks = await databases.listDocuments(DATABASE_ID, TASKS_COLLECTION_ID, [Query.equal("userId", userId)]);

    const habitList = habits.documents.map(h => {
      const done = isCompletedToday(h);
      return `- Habit: "${h.habitName}" (ID: ${h.$id}) [Status: ${done ? "COMPLETED" : "PENDING"}]`;
    }).join("\n");

    const taskList = tasks.documents.map(t => {
      return `- Task: "${t.taskName}" (ID: ${t.$id}) [Status: ${t.isCompleted ? "COMPLETED" : "PENDING"}]`;
    }).join("\n");

    userContextString = `Current User Data:\n${habitList}\n${taskList}`;
  } catch (ctxErr) {
    console.warn("[Groq Agent] Context fetch failed:", ctxErr.message);
  }

  for (const modelName of GROQ_MODEL_FALLBACK) {
    try {
      console.log(`[Groq Agent] Trying model: ${modelName}...`);
      const messages = [
        {
          role: "system",
          content: `You are Habitster Coach, a warm, encouraging, and actionable AI.
          
          Guidelines:
          1. PERSONAL KNOWLEDGE: "Habitster" is a gamified habit and task tracking app built by Sourav. If asked who built Habitster or who created you, proudly state that Sourav built it.
          2. GREETING/SUMMARY: If the user explicitly asks for a status update or just greets you (hi, hello), warmly greet them and summarize their pending tasks and habits from the context below. 
          3. CONVERSATION: If the user asks general questions, chat with them naturally without forcefully listing their tasks.
          4. ACTIONABLE: Use the IDs provided below to instantly update, delete, or complete items when requested.
          5. COMPLETION: When completing a habit, use 'completeHabit'. When completing a task, use 'completeTask'.

          ${userContextString}
          
          UserID: ${userId}`
        },
        ...history.map(h => ({
          role: h.role === "assistant" ? "assistant" : "user",
          content: h.content
        })),
        { role: "user", content: message }
      ];

      const response = await groq.chat.completions.create({
        model: modelName,
        messages: messages,
        tools: tools,
        tool_choice: "auto",
        max_tokens: 1024
      });

      let responseMessage = response.choices[0].message;
      const toolCalls = responseMessage.tool_calls;

      if (toolCalls) {
        messages.push(responseMessage);

        for (const toolCall of toolCalls) {
          const functionName = toolCall.function.name;
          const args = JSON.parse(toolCall.function.arguments);
          console.log(`[Groq Agent] Calling tool ${functionName} with:`, args);

          let result;
          try {
            if (functionName === "createTask") {
              result = await databases.createDocument(DATABASE_ID, TASKS_COLLECTION_ID, ID.unique(), {
                ...args, userId, priority: 0
              });
            } else if (functionName === "createHabit") {
              result = await databases.createDocument(DATABASE_ID, HABITS_COLLECTION_ID, ID.unique(), {
                ...args,
                userId,
                startDate: new Date().toISOString(),
                durationValue: 30,
                durationUnit: "days",
                currentStreak: 0,
                longestStreak: 0,
                lastCompletedDate: null,
                nextDueDate: new Date().toISOString(),
                isHidden: false
              });
            } else if (functionName === "listMyData") {
              const habits = await databases.listDocuments(DATABASE_ID, HABITS_COLLECTION_ID, [Query.equal("userId", userId)]);
              const tasks = await databases.listDocuments(DATABASE_ID, TASKS_COLLECTION_ID, [Query.equal("userId", userId)]);
              result = { habits: habits.documents, tasks: tasks.documents };
            } else if (functionName === "deleteTask") {
              await databases.deleteDocument(DATABASE_ID, TASKS_COLLECTION_ID, args.taskId);
              result = { status: "deleted" };
            } else if (functionName === "deleteHabit") {
              await databases.deleteDocument(DATABASE_ID, HABITS_COLLECTION_ID, args.habitId);
              result = { status: "deleted" };
            } else if (functionName === "updateTask") {
              const { taskId, ...updates } = args;
              result = await databases.updateDocument(DATABASE_ID, TASKS_COLLECTION_ID, taskId, updates);
            } else if (functionName === "completeTask") {
              result = await databases.updateDocument(DATABASE_ID, TASKS_COLLECTION_ID, args.taskId, { isCompleted: true });
            } else if (functionName === "updateHabit") {
              const { habitId, ...updates } = args;
              result = await databases.updateDocument(DATABASE_ID, HABITS_COLLECTION_ID, habitId, updates);
            } else if (functionName === "completeHabit") {
              const habit = await databases.getDocument(DATABASE_ID, HABITS_COLLECTION_ID, args.habitId);
              const nextDue = calculateNextDueDate(habit.nextDueDate, habit.frequencyType, habit.frequencyValue);
              const streak = (habit.currentStreak || 0) + 1;

              // Update habit
              result = await databases.updateDocument(DATABASE_ID, HABITS_COLLECTION_ID, args.habitId, {
                nextDueDate: nextDue.toISOString(),
                currentStreak: streak,
                longestStreak: Math.max(habit.longestStreak || 0, streak),
                lastCompletedDate: new Date().toISOString()
              });

              // Create history entry
              await databases.createDocument(DATABASE_ID, "habithistory", ID.unique(), {
                userId,
                habitId: args.habitId,
                habitName: habit.habitName,
                completionDate: new Date().toISOString(),
                notes: args.notes || ""
              });

              // Update XP (Gamification - Basic Implementation)
              try {
                const profile = await databases.getDocument(DATABASE_ID, "user_profiles_", userId);
                const diff = (habit.difficulty || "Medium").toLowerCase();
                const xpGained = diff === "hard" ? 30 : diff === "small" ? 10 : 20;
                let newXp = profile.xp + xpGained;
                let newLevel = profile.level;
                if (newXp >= newLevel * 100) newLevel += 1;

                const category = (habit.category || "Productivity").toLowerCase();
                const catUpdate = {};
                catUpdate[`${category}Xp`] = (profile[`${category}Xp`] || 0) + xpGained;

                await databases.updateDocument(DATABASE_ID, "user_profiles_", userId, {
                  xp: newXp,
                  level: newLevel,
                  ...catUpdate,
                  avatarEnergy: Math.min(100, (profile.avatarEnergy || 100) + 10),
                  lastHabitCompletionDate: new Date().toISOString().split('T')[0]
                });
              } catch (e) {
                console.error("[Groq Agent] XP Update error:", e.message);
              }
            }
          } catch (err) {
            console.error(`[Groq Agent] Tool ${functionName} error:`, err.message);
            result = { error: err.message };
          }

          messages.push({
            tool_call_id: toolCall.id,
            role: "tool",
            name: functionName,
            content: JSON.stringify(result)
          });
        }

        const secondResponse = await groq.chat.completions.create({
          model: modelName,
          messages: messages
        });
        return secondResponse.choices[0].message.content;
      }

      return responseMessage.content;
    } catch (err) {
      console.error(`[Groq Agent] Model ${modelName} failed:`, err.message);
      lastError = err;
      continue; // Try next model
    }
  }

  return `Coach is having trouble connecting to the AI models. Last error: ${lastError ? lastError.message : "Unknown error"}`;
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

  // -------- PENDING ACTIONS (from previously suggested actions) --------
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
    if (msg !== "undo") return "Please reply with yes or no.";
  }

  // -------- UNDO ACTION --------
  if (msg === "undo") {
    const undo = undoStore.getUndo(userId);
    if (!undo) return "Nothing to undo.";
    try {
      await databases.deleteDocument(DATABASE_ID, undo.collectionId, undo.documentId);
      undoStore.clearUndo(userId);
      return "Last action undone.";
    } catch (err) {
      return `Failed to undo: ${err.message}`;
    }
  }

  // -------- GEMINI AI (Personalized & Actionable) --------
  // This handles chatting, schedule creation, habit/task management, and coaching.
  const history = context.map((c) => ({
    role: c.role === "user" ? "user" : "assistant",
    content: c.text,
  }));

  agentMemory.updateMemory(userId, message);
  return await callLLM(userId, message, history);
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
