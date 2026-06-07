const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  mobile: {
    type: String,
    required: true,
  },
  specialty: {
    type: String,
    required: false,
    default: '',
  },
  email: {
    type: String,
    required: false,
    default: '',
  },
  region: {
    type: String,
    required: false,
    default: '',
  },
  address: {
    type: String,
    required: false,
    default: '',
  },
  status: {
    type: String,
    required: false,
    default: 'Saved',
  },
  scheduledTime: {
    type: Date,
    required: false,
    default: null,
  },
  availableFrom: {
    type: String,
    default: '',
  },
  availableTo: {
    type: String,
    default: '',
  },
  customFields: {
    type: Map,
    of: String,
    default: {},
  }
}, { timestamps: true });

module.exports = mongoose.model('Doctor', doctorSchema);
