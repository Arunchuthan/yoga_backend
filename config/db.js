const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        // Your exact working MongoDB Atlas connection string
        const conn = await mongoose.connect('mongodb://arunchuthan28_db_user:Yoga123@ac-tqiaxba-shard-00-00.oup5b0m.mongodb.net:27017,ac-tqiaxba-shard-00-01.oup5b0m.mongodb.net:27017,ac-tqiaxba-shard-00-02.oup5b0m.mongodb.net:27017/yoga_db?ssl=true&replicaSet=atlas-o7qmh1-shard-0&authSource=admin&appName=Cluster0');
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Database Connection Error: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;