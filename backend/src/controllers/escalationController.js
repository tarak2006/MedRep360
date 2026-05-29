const Escalation = require('../models/Escalation');

exports.getEscalations = async (req, res) => {
  try {
    const escalations = await Escalation.find();
    res.json(escalations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createEscalation = async (req, res) => {
  const escalation = new Escalation(req.body);
  try {
    const newEscalation = await escalation.save();
    res.status(201).json(newEscalation);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.updateEscalation = async (req, res) => {
  try {
    const escalation = await Escalation.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!escalation) return res.status(404).json({ message: 'Escalation not found' });
    res.json(escalation);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.deleteEscalation = async (req, res) => {
  try {
    const escalation = await Escalation.findByIdAndDelete(req.params.id);
    if (!escalation) return res.status(404).json({ message: 'Escalation not found' });
    res.json({ message: 'Escalation deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
