const express = require('express');
const router = express.Router();
const escalationController = require('../controllers/escalationController');

router.get('/', escalationController.getEscalations);
router.post('/', escalationController.createEscalation);
router.put('/:id', escalationController.updateEscalation);
router.delete('/:id', escalationController.deleteEscalation);

module.exports = router;
