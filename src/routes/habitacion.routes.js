//GET    /api/habitaciones
//GET    /api/habitaciones/disponibles
//GET    /api/habitaciones/estado/:estado
//GET    /api/habitaciones/:id
//POST   /api/habitaciones
//PUT    /api/habitaciones/:id
//PATCH  /api/habitaciones/:id/estado
//DELETE /api/habitaciones/:id
const express = require("express");

const router = express.Router();

const controller = require("../controllers/habitacion.controller");

router.get("/", controller.getAll);
router.get("/disponibles", controller.getDisponibles);
router.get("/estado/:estado", controller.getByEstado);
router.get("/:id", controller.getById);
router.post("/", controller.create);
router.put("/:id", controller.update);
router.patch("/:id/estado", controller.changeEstado);
router.delete("/:id", controller.remove);

module.exports = router;