const Doctor = require('../models/Doctor');
const Interaction = require('../models/Interaction');
const Escalation = require('../models/Escalation');

exports.getDashboardAnalytics = async (req, res) => {
  try {
    const totalDoctors = await Doctor.countDocuments();
    const totalInteractions = await Interaction.countDocuments();
    const totalEscalations = await Escalation.countDocuments();
    
    const pendingEscalations = await Escalation.countDocuments({ status: 'Pending' });

    res.json({
      totalDoctors,
      totalInteractions,
      totalEscalations,
      pendingEscalations
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
