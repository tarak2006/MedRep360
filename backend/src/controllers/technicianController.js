const Technician = require('../models/Technician');

exports.getTechnicians = async (req, res) => {
  try {
    const technicians = await Technician.find();
    res.json(technicians);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createTechnician = async (req, res) => {
  try {
    const { name, email } = req.body;
    if (!name || !email) {
      return res.status(400).json({ message: 'Name and email are required' });
    }
    
    // Check if technician already exists by name
    let technician = await Technician.findOne({ name });
    if (technician) {
      return res.status(200).json(technician);
    }
    
    technician = new Technician({ name, email });
    const newTechnician = await technician.save();
    res.status(201).json(newTechnician);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};
