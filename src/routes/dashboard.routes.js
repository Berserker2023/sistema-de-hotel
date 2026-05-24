const express = require('express');
const dashboardController = require('../controllers/dashboard.controller');
const { verificarToken } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(verificarToken);

router.get('/general', dashboardController.getGeneral);
router.get('/ingresos', dashboardController.getIngresosPorFecha);
router.get('/ingresos/semana', dashboardController.getIngresosUltimos7Dias);

module.exports = router;