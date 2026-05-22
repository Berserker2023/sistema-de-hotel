const express = require('express');
const authController = require('../controllers/auth.controller');
const { verificarToken } = require('../middlewares/auth.middleware');

const router = express.Router();

// Ruta pública
router.post('/login', authController.login);

// Rutas protegidas
router.get('/perfil', verificarToken, authController.getPerfil);
router.get('/verify', verificarToken, authController.verifyToken);

module.exports = router;