const pool = require("../config/db");

/* LISTAR TODAS */
exports.getAll = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        r.*,
        CONCAT(p.nombres,' ',p.apellidos) AS cliente,
        h.tipo AS tipoHabitacion
      FROM Reserva r
      INNER JOIN Persona p
        ON r.docIdCliente = p.docId
      INNER JOIN Habitacion h
        ON r.idHabitacion = h.id
      ORDER BY r.id DESC
    `);

    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* ACTIVAS */
exports.getActivas = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT *
      FROM vw_reservas_activas
      ORDER BY id DESC
    `);

    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* BUSCAR POR ID */
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(`
      SELECT * FROM Reserva
      WHERE id = ?
    `, [id]);

    if (rows.length === 0) {
      return res.status(404).json({
        message: "Reserva no encontrada"
      });
    }

    res.json(rows[0]);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* BUSCAR POR RESERVA, DNI O HABITACION */
exports.search = async (req, res) => {
  try {
    const { query } = req.query;

    if (!query) {
      return res.status(400).json({
        message: "Parámetro 'query' es requerido"
      });
    }

    const [rows] = await pool.query(`
      SELECT
        r.*,
        CONCAT(p.nombres,' ',p.apellidos) AS cliente,
        h.tipo AS tipoHabitacion
      FROM Reserva r
      INNER JOIN Persona p
        ON r.docIdCliente = p.docId
      INNER JOIN Habitacion h
        ON r.idHabitacion = h.id
      WHERE 
        r.id = ? OR
        r.docIdCliente = ? OR
        r.idHabitacion = ?
      ORDER BY r.id DESC
    `, [query, query, query]);

    res.json(rows);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* REGISTRAR */
exports.create = async (req, res) => {
  try {
    const {
      fechaEntrada,
      fechaSalida,
      precio,
      idEmpleado,
      docIdCliente,
      idHabitacion
    } = req.body;

    const [result] = await pool.query(`
      INSERT INTO Reserva(
        fecha,
        fechaEntrada,
        fechaSalida,
        estado,
        precio,
        idEmpleado,
        docIdCliente,
        idHabitacion
      )
      VALUES(
        NOW(),
        ?, ?, 'CONFIRMADA',
        ?, ?, ?, ?
      )
    `, [
      fechaEntrada,
      fechaSalida,
      precio,
      idEmpleado,
      docIdCliente,
      idHabitacion
    ]);

    res.status(201).json({
      message: "Reserva registrada",
      idReserva: result.insertId
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* CHECKIN */
exports.checkin = async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(`
      UPDATE Reserva
      SET estado='CHECKIN'
      WHERE id=?
    `, [id]);

    await pool.query(`
      UPDATE Habitacion h
      INNER JOIN Reserva r
        ON h.id = r.idHabitacion
      SET h.estado='OCUPADA'
      WHERE r.id=?
    `, [id]);

    res.json({
      message: "Check-in realizado"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* CHECKOUT */
exports.checkout = async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(`
      UPDATE Reserva
      SET estado='FINALIZADA'
      WHERE id=?
    `, [id]);

    res.json({
      message: "Checkout realizado"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* CANCELAR */
exports.cancelar = async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(`
      UPDATE Reserva
      SET estado='CANCELADA'
      WHERE id=?
    `, [id]);

    res.json({
      message: "Reserva cancelada"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* EDITAR/ACTUALIZAR */
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      fechaEntrada,
      fechaSalida,
      precio,
      idEmpleado,
      docIdCliente,
      idHabitacion
    } = req.body;

    // Validar que al menos tenemos los datos obligatorios
    if (!fechaEntrada || !fechaSalida || !precio || !idEmpleado || !docIdCliente || !idHabitacion) {
      return res.status(400).json({
        message: "Faltan datos obligatorios",
        campos_requeridos: ['fechaEntrada', 'fechaSalida', 'precio', 'idEmpleado', 'docIdCliente', 'idHabitacion']
      });
    }

    // Validar que la fecha de entrada sea anterior a la de salida
    if (new Date(fechaEntrada) >= new Date(fechaSalida)) {
      return res.status(400).json({
        message: "La fecha de entrada debe ser anterior a la fecha de salida"
      });
    }

    const [result] = await pool.query(`
      UPDATE Reserva
      SET
        fechaEntrada = ?,
        fechaSalida = ?,
        precio = ?,
        idEmpleado = ?,
        docIdCliente = ?,
        idHabitacion = ?
      WHERE id = ?
    `, [
      fechaEntrada,
      fechaSalida,
      precio,
      idEmpleado,
      docIdCliente,
      idHabitacion,
      id
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: "Reserva no encontrada"
      });
    }

    res.json({
      message: "Reserva actualizada correctamente"
    });

  } catch (error) {
    console.error('Error en update:', error);
    res.status(500).json({ error: error.message });
  }
};

/* ELIMINAR */
exports.remove = async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(
      "DELETE FROM Reserva WHERE id=?",
      [id]
    );

    res.json({
      message: "Reserva eliminada"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};