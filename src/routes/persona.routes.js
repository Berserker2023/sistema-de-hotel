// Importa el framework Express
const express = require("express");

// Crea una instancia del enrutador de Express
const router = express.Router();

// Importa el controlador de persona (contiene la lógica de cada endpoint)
const controller = require("../controllers/persona.controller");
const { verificarToken } = require("../middlewares/auth.middleware");

// Aplicar middleware de autenticación a todas las rutas
router.use(verificarToken);

// Ruta GET "/" → obtiene todas las personas
router.get("/", controller.getAll);

// Ruta GET "/:docId" → obtiene una persona por su ID (docId)
router.get("/:docId", controller.getById);

// Ruta POST "/" → crea una nueva persona
router.post("/", controller.create);

// Ruta PUT "/:docId" → actualiza una persona existente por su ID
router.put("/:docId", controller.update);

// Ruta DELETE "/:docId" → elimina una persona por su ID
router.delete("/:docId", controller.remove);

// Exporta el router para usarlo en otras partes de la aplicación
module.exports = router;