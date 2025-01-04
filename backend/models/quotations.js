const mongoose = require('mongoose');

const quotationSchema = new mongoose.Schema({
  clientName: {
    type: String,
    required: true
  },
  companyName: {
    type: String,
    required: true
  },
  eventDate: {
    type: Date,
    required: true
  },
  startTime: {
    type: String,
    required: true
  },
  endTime: {
    type: String,
    required: true
  },
  numberOfGuests: {
    type: Number,
    required: true
  },
  servicesRequested: {
    type: [String],
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Quotation', quotationSchema);