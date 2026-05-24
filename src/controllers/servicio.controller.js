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

    const [cols] = await pool.query("SHOW COLUMNS FROM Servicio LIKE 'precio'");
    const tienePrecio = cols.length > 0;
    let precioServicio = tienePrecio ? parseFloat(precio) || 0 : undefined;
    
    // Asegurar que el precio sea positivo
    if (tienePrecio) {
      precioServicio = Math.max(0, Math.abs(precioServicio));
    }

    let result;
    if (tienePrecio) {
      [result] = await pool.query(`
        INSERT INTO Servicio(tipo, descripcion, estado, precio)
        VALUES(?, ?, 'ACTIVO', ?)
      `, [nombre, descripcion || nombre, precioServicio]);
    } else {
      [result] = await pool.query(`
        INSERT INTO Servicio(tipo, descripcion, estado)
        VALUES(?, ?, 'ACTIVO')
      `, [nombre, descripcion || nombre]);
    }

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
    const { nombre, estado, descripcion, precio } = req.body;

    const [cols] = await pool.query("SHOW COLUMNS FROM Servicio LIKE 'precio'");
    const tienePrecio = cols.length > 0;
    let precioServicio = tienePrecio ? parseFloat(precio) || 0 : undefined;
    
    // Asegurar que el precio sea positivo
    if (tienePrecio) {
      precioServicio = Math.max(0, Math.abs(precioServicio));
    }

    if (tienePrecio) {
      await pool.query(`
        UPDATE Servicio
        SET tipo=?,
            descripcion=?,
            estado=?,
            precio=?
        WHERE id=?
      `, [nombre, descripcion || nombre, estado, precioServicio, id]);
    } else {
      await pool.query(`
        UPDATE Servicio
        SET tipo=?,
            descripcion=?,
            estado=?
        WHERE id=?
      `, [nombre, descripcion || nombre, estado, id]);
    }

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

    // Intentar insertar en DetalleServicio
    let insertado = false;
    let ultimoError = null;

    // Intento 1: con 'subtotal' minúscula
    try {
      await pool.query(`
        INSERT INTO DetalleServicio(
          idReserva,
          idServicio,
          cantidad,
          precio,
          subtotal
        )
        VALUES(?,?,?,?,?)
      `, [
        idReserva,
        idServicio,
        cantidad,
        precio,
        subtotal
      ]);
      insertado = true;
    } catch (err1) {
      ultimoError = err1;
      // Intento 2: con 'subTotal' camelCase
      try {
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
        insertado = true;
      } catch (err2) {
        ultimoError = err2;
      }
    }

    if (!insertado) {
      console.error("Error al insertar en DetalleServicio:", ultimoError);
      throw new Error(`Error al registrar consumo: ${ultimoError.message}`);
    }

    res.status(201).json({
      message: "Consumo registrado"
    });

  } catch (error) {
    console.error("Error en consumo:", error);
    res.status(500).json({ 
      error: error.message,
      message: "Error al registrar consumo"
    });
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
        ds.subtotal as subtotal,
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
      SELECT IFNULL(SUM(subtotal),0) AS total
      FROM DetalleServicio
      WHERE idReserva = ?
    `, [id]);

    res.json(rows[0]);

  } catch (error) {
    console.error("Error en totalReserva:", error);
    res.status(500).json({ error: error.message });
  }
};