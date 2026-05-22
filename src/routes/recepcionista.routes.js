const express = require("express");
const recepcionistaController = require("../controllers/recepcionista.controller");
const { verificarToken } = require("../middlewares/auth.middleware");

const router = express.Router();

// Todas las rutas requieren autenticación
router.use(verificarToken);

// Rutas principales
router.get("/", recepcionistaController.getAll);
router.get("/activos", recepcionistaController.getActivos);
router.get("/:id", recepcionistaController.getById);
router.post("/", recepcionistaController.create);
router.put("/:id", recepcionistaController.update);
router.delete("/:id", recepcionistaController.remove);

// Rutas específicas para cambiar estado y turno
router.patch("/:id/estado", recepcionistaController.changeEstado);
router.patch("/:id/turno", recepcionistaController.changeTurno);

module.exports = router;