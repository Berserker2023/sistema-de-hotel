//GET    /api/servicios
//GET    /api/servicios/:id
//POST   /api/servicios
//PUT    /api/servicios/:id
//DELETE /api/servicios/:id

//POST   /api/servicios/consumo
//GET    /api/reservas/:id/servicios
//GET    /api/reservas/:id/total-servicios

// Importa el framework Express
const express = require("express");

// Crea una instancia del enrutador de Express
const router = express.Router();

// Importa el controlador de servicio (contiene la lógica de cada endpoint)
const controller = require("../controllers/servicio.controller");

// Importa middleware de autenticación
const { verificarToken } = require("../middlewares/auth.middleware");

// Ruta GET "/" → obtiene todas las personas
router.get("/", verificarToken, controller.getAll);

// Ruta POST "/" → crea un nuevo servicio
router.post("/", verificarToken, controller.create);

// Ruta POST "/consumo" → registra un consumo de servicio (DEBE IR ANTES DE /:id)
router.post("/consumo", verificarToken, controller.consumo);

// Rutas con parámetro ID (estas van al final para no conflictuar)
// Ruta GET "/:id" → obtiene un servicio por su ID
router.get("/:id", verificarToken, controller.getById);

// Ruta PUT "/:id" → actualiza un servicio existente por su ID
router.put("/:id", verificarToken, controller.update);

// Ruta DELETE "/:id" → elimina un servicio por su ID
router.delete("/:id", verificarToken, controller.remove);

//ruta GET "/:id/servicios" → obtener los servicios por reserva
router.get("/:id/servicios", verificarToken, controller.getByReserva);

//ruta get ":id/total-servicios" → Obtiene el total ($) servicios por reserva
router.get("/:id/total-servicios", verificarToken, controller.totalReserva);
// Exporta el router para usarlo en otras partes de la aplicación
module.exports = router;