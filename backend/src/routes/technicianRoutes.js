const express = require('express');
const router = express.Router();
const technicianController = require('../controllers/technicianController');

router.get('/', technicianController.getTechnicians);
router.post('/', technicianController.createTechnician);

module.exports = router;
