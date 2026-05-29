const mongoose = require('mongoose');

const escalationSchema = new mongoose.Schema({
  doctor_name: {
    type: String,
    required: true,
  },
  query: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    default: 'Pending',
    enum: ['Pending', 'In Progress', 'Resolved']
  },
  assigned_to: {
    type: String,
  }
}, { timestamps: true });

module.exports = mongoose.model('Escalation', escalationSchema);
