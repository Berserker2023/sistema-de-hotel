const express = require("express");
const pagoController = require("../controllers/pago.controller");
const { verificarToken } = require("../middlewares/auth.middleware");

const router = express.Router();

// Todas las rutas requieren autenticación
router.use(verificarToken);

// Registrar pago
router.post("/registrar", pagoController.registrarPago);

// Reporte de caja diaria
router.get("/caja", pagoController.getCajaDiaria);

// Reservas activas (para combo)
router.get("/reservas/activas", pagoController.getReservasActivas);

// Por reserva específica
router.get("/reserva/:id", pagoController.getReservaParaPago);
router.get("/reserva/:idReserva/historial", pagoController.getHistorialByReserva);
router.get("/reserva/:idReserva/total-pagado", pagoController.getTotalPagadoByReserva);
router.get("/reserva/:idReserva/saldo", pagoController.getSaldoPendiente);
router.get("/reserva/:idReserva/estado-cuenta", pagoController.getEstadoCuenta);

module.exports = router;