require('dotenv').config();
const { Client, Databases } = require('node-appwrite');

const client = new Client()
    .setEndpoint('https://nyc.cloud.appwrite.io/v1')
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(client);

databases.listDocuments('68f3c29000072cae03e0', 'tasks-storage')
    .then(res => {
        const task = res.documents[0];
        console.log('Testing task:', task.taskName, task.$id);
        return databases.updateDocument('68f3c29000072cae03e0', 'tasks-storage', task.$id, {
            isCompleted: true
        }).then(() => {
            return databases.getDocument('68f3c29000072cae03e0', 'tasks-storage', task.$id);
        });
    })
    .then(updatedTask => console.log('Fetched immediately after update:', updatedTask.isCompleted))
    .catch(console.error);
