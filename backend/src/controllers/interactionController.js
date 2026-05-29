const Interaction = require('../models/Interaction');

exports.getInteractions = async (req, res) => {
  try {
    const interactions = await Interaction.find().populate('doctor');
    res.json(interactions);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createInteraction = async (req, res) => {
  const interaction = new Interaction(req.body);
  try {
    const newInteraction = await interaction.save();
    res.status(201).json(newInteraction);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.updateInteraction = async (req, res) => {
  try {
    const interaction = await Interaction.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!interaction) return res.status(404).json({ message: 'Interaction not found' });
    res.json(interaction);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.deleteInteraction = async (req, res) => {
  try {
    const interaction = await Interaction.findByIdAndDelete(req.params.id);
    if (!interaction) return res.status(404).json({ message: 'Interaction not found' });
    res.json({ message: 'Interaction deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
