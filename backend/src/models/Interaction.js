const mongoose = require('mongoose');

const interactionSchema = new mongoose.Schema({
  doctor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
    required: true,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  notes: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['In-person', 'Virtual', 'Phone', 'Email'],
    default: 'In-person'
  }
}, { timestamps: true });

module.exports = mongoose.model('Interaction', interactionSchema);
