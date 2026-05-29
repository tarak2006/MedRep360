const express = require('express');
const router = express.Router();
const interactionController = require('../controllers/interactionController');

router.get('/', interactionController.getInteractions);
router.post('/', interactionController.createInteraction);
router.put('/:id', interactionController.updateInteraction);
router.delete('/:id', interactionController.deleteInteraction);

module.exports = router;
