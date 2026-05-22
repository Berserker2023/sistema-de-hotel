const pool = require("../config/db");
const jwt = require('jsonwebtoken');

exports.login = async (req, res) => {
  try {
    const { correo } = req.body;

    if (!correo) {
      return res.status(400).json({
        success: false,
        message: 'El correo es requerido'
      });
    }

    // Llamar al SP sp_login_recepcionista
    const [rows] = await pool.query('CALL sp_login_recepcionista(?)', [correo]);
    const recepcionista = rows[0][0];

    if (!recepcionista) {
      return res.status(401).json({
        success: false,
        message: 'Credenciales inválidas o usuario inactivo'
      });
    }

    // Generar token JWT
    const token = jwt.sign(
      {
        idEmpleado: recepcionista.idEmpleado,
        nombres: recepcionista.nombres,
        apellidos: recepcionista.apellidos,
        correo: recepcionista.correo,
        turno: recepcionista.turno
      },
      process.env.JWT_SECRET || 'hotel_secret_key_2024',
      { expiresIn: '8h' }
    );

    res.json({
      success: true,
      message: 'Login exitoso',
      token,
      usuario: {
        idEmpleado: recepcionista.idEmpleado,
        nombres: recepcionista.nombres,
        apellidos: recepcionista.apellidos,
        correo: recepcionista.correo,
        turno: recepcionista.turno
      }
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

exports.getPerfil = async (req, res) => {
  try {
    res.json({
      success: true,
      usuario: req.usuario
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al obtener perfil'
    });
  }
};

exports.verifyToken = async (req, res) => {
  res.json({
    success: true,
    message: 'Token válido',
    usuario: req.usuario
  });
};