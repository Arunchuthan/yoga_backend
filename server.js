const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const apiRoutes = require('./routes/api');

const app = express();

// Establish core configuration middleware
connectDB();
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Higher cap threshold to support base64 imagery profiles

app.use('/api', apiRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server dispatch operations online on port ${PORT}`));