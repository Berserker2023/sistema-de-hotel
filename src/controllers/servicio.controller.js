const pool = require("../config/db");

/* =========================
   LISTAR SERVICIOS
========================= */
exports.getAll = async (req, res) => {
  try {
    // Comprobar si la columna `precio` existe en la tabla Servicio
    const [cols] = await pool.query("SHOW COLUMNS FROM Servicio LIKE 'precio'");
    const tienePrecio = cols.length > 0;

    const selectPrecio = tienePrecio ? 'IFNULL(precio,0) as precio' : '0 as precio';

    const [rows] = await pool.query(`
      SELECT id, tipo as nombre, descripcion, estado, ${selectPrecio}
      FROM Servicio
      ORDER BY descripcion
    `);

    res.json(rows);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   BUSCAR POR ID
========================= */
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;

    const [cols] = await pool.query("SHOW COLUMNS FROM Servicio LIKE 'precio'");
    const tienePrecio = cols.length > 0;
    const selectPrecio = tienePrecio ? 'IFNULL(precio,0) as precio' : '0 as precio';

    const [rows] = await pool.query(`
      SELECT id, tipo as nombre, descripcion, estado, ${selectPrecio}
      FROM Servicio
      WHERE id = ?
    `, [id]);

    if (rows.length === 0) {
      return res.status(404).json({
        message: "Servicio no encontrado"
      });
    }

    res.json(rows[0]);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   CREAR SERVICIO
========================= */
exports.create = async (req, res) => {
  try {
    const { nombre, precio, descripcion } = req.body;

    const [result] = await pool.query(`
      INSERT INTO Servicio(tipo, descripcion, estado)
      VALUES(?, ?, 'ACTIVO')
    `, [nombre, descripcion || nombre]);

    res.status(201).json({
      message: "Servicio creado",
      id: result.insertId
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   ACTUALIZAR
========================= */
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, estado, descripcion } = req.body;

    await pool.query(`
      UPDATE Servicio
      SET tipo=?,
          descripcion=?,
          estado=?
      WHERE id=?
    `, [nombre, descripcion || nombre, estado, id]);

    res.json({
      message: "Servicio actualizado"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   ELIMINAR
========================= */
exports.remove = async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(`
      DELETE FROM Servicio
      WHERE id=?
    `, [id]);

    res.json({
      message: "Servicio eliminado"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   REGISTRAR CONSUMO
========================= */
exports.consumo = async (req, res) => {
  try {
    const {
      idReserva,
      idServicio,
      cantidad
    } = req.body;

    // Verificar que el servicio existe
    const [servicio] = await pool.query(`
      SELECT *
      FROM Servicio
      WHERE id = ?
    `, [idServicio]);

    if (servicio.length === 0) {
      return res.status(404).json({
        message: "Servicio no existe"
      });
    }

    // Intentar obtener precio desde la tabla Servicio si existe la columna
    const [cols] = await pool.query("SHOW COLUMNS FROM Servicio LIKE 'precio'");
    const tienePrecio = cols.length > 0;

    let precio = 0;
    if (tienePrecio) {
      precio = parseFloat(servicio[0].precio) || 0;
    } else if (req.body.precio) {
      precio = parseFloat(req.body.precio) || 0;
    }

    const subtotal = precio * (cantidad || 0);

    await pool.query(`
      INSERT INTO DetalleServicio(
        idReserva,
        idServicio,
        cantidad,
        precio,
        subTotal
      )
      VALUES(?,?,?,?,?)
    `, [
      idReserva,
      idServicio,
      cantidad,
      precio,
      subtotal
    ]);

    res.status(201).json({
      message: "Consumo registrado"
    });

  } catch (error) {
    console.error("Error en consumo:", error);
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   SERVICIOS POR RESERVA
========================= */
exports.getByReserva = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(`
      SELECT
        ds.idReserva as id,
        s.tipo as descripcion,
        ds.cantidad,
        ds.precio as precioUnitario,
        ds.subTotal as subtotal,
        NOW() as fecha
      FROM DetalleServicio ds
      INNER JOIN Servicio s
        ON ds.idServicio = s.id
      WHERE ds.idReserva = ?
      ORDER BY ds.idReserva DESC
    `, [id]);

    res.json(rows);

  } catch (error) {
    console.error("Error en getByReserva:", error);
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   TOTAL SERVICIOS RESERVA
========================= */
exports.totalReserva = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(`
      SELECT IFNULL(SUM(subTotal),0) AS total
      FROM DetalleServicio
      WHERE idReserva = ?
    `, [id]);

    res.json(rows[0]);

  } catch (error) {
    console.error("Error en totalReserva:", error);
    res.status(500).json({ error: error.message });
  }
};