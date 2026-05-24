const express = require("express");
const router = express.Router();
const reporteController = require("../controllers/reporte.controller");
const { verificarToken } = require("../middlewares/auth.middleware");

// Todas las rutas requieren autenticación
router.use(verificarToken);

router.get("/clientes-frecuentes", reporteController.getClientesFrecuentes);
router.get("/habitaciones-mas-usadas", reporteController.getHabitacionesMasUsadas);
router.get("/servicios-mas-vendidos", reporteController.getServiciosMasVendidos);
router.get("/ocupacion-sucursal", reporteController.getOcupacionSucursal);
router.get("/ingresos-mensuales", reporteController.getIngresosMensuales);

module.exports = router;