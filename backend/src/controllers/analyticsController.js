const Doctor = require('../models/Doctor');
const Interaction = require('../models/Interaction');
const Lead = require('../models/Lead');

exports.getDashboardAnalytics = async (req, res) => {
  try {
    const totalDoctors = await Doctor.countDocuments();
    const totalInteractions = await Interaction.countDocuments();
    const totalLeads = await Lead.countDocuments();
    
    const pendingLeads = await Lead.countDocuments({ status: 'Pending' });

    res.json({
      totalDoctors,
      totalInteractions,
      totalLeads,
      pendingLeads,
      totalEscalations: totalLeads,
      pendingEscalations: pendingLeads
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
