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

// Ruta GET "/" → obtiene todas las personas
router.get("/", controller.getAll);

// Ruta GET "/:id" → obtiene un servicio por su ID
router.get("/:id", controller.getById);

// Ruta POST "/" → crea un nuevo servicio
router.post("/", controller.create);

// Ruta PUT "/:id" → actualiza un servicio existente por su ID
router.put("/:id", controller.update);

// Ruta DELETE "/:id" → elimina un servicio por su ID
router.delete("/:id", controller.remove);

// Ruta POST "/consumo" → registra un consumo de servicio 
router.post("/consumo", controller.consumo);

//ruta GET "/:id/servicios" → obtener los servicios por reserva
router.get("/:id/servicios", controller.getByReserva);

//ruta get ":id/total-servicios" → Obtiene el total ($) servicios por reserva
router.get("/:id/total-servicios", controller.totalReserva);
// Exporta el router para usarlo en otras partes de la aplicación
module.exports = router;