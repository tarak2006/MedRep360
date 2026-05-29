require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

// Import routes
const doctorRoutes = require('./routes/doctorRoutes');
const escalationRoutes = require('./routes/escalationRoutes');
const interactionRoutes = require('./routes/interactionRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const technicianRoutes = require('./routes/technicianRoutes');

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/doctors', doctorRoutes);
app.use('/api/escalations', escalationRoutes);
app.use('/api/interactions', interactionRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/technicians', technicianRoutes);

app.get('/', (req, res) => {
  res.send('MedRep360 API is running...');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
