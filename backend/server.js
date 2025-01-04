const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server);

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB Atlas'))
  .catch(err => console.error('MongoDB connection error:', err));

// Quotation Schema
const quotationSchema = new mongoose.Schema({
  clientName: String,
  companyName: String,
  eventDate: Date,
  startTime: String,
  endTime: String,
  numberOfGuests: Number,
  servicesRequested: [String],
  createdAt: { type: Date, default: Date.now }
});

const Quotation = mongoose.model('Quotation', quotationSchema);

// Routes
app.get('/api/quotations', async (req, res) => {
  try {
    const quotations = await Quotation.find().sort({ eventDate: 1 });
    res.json(quotations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/quotations/by-created-date', async (req, res) => {
  try {
    const quotations = await Quotation.find().sort({ createdAt: -1 });
    res.json(quotations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/quotations', async (req, res) => {
  try {
    const quotation = new Quotation(req.body);
    await quotation.save();
    io.emit('newQuotation', quotation); // Emit to all connected clients
    res.status(201).json(quotation);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Socket.IO Connection
io.on('connection', (socket) => {
  console.log('Client connected');
  
  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

// Start server
const PORT = process.env.PORT || 8888;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});