const pool = require("../config/db");

/* =========================
   LISTAR TODOS LOS RECEPCIONISTAS
   Usa: sp_listar_recepcionistas()
========================= */
exports.getAll = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL sp_listar_recepcionistas()");
    
    // El SP devuelve los resultados en rows[0]
    const recepcionistas = (rows[0] || []).map(r => ({
      idEmpleado: r.idEmpleado,
      docId: r.docId,
      empleado: r.empleado,
      correo: r.correo,
      turno: r.turno,
      estado: r.estado
    }));
    
    res.json(recepcionistas);
  } catch (error) {
    console.error("Error en getAll recepcionistas:", error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

/* =========================
   BUSCAR RECEPCIONISTA POR ID
   Usa: sp_buscar_recepcionista(p_idEmpleado)
========================= */
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query("CALL sp_buscar_recepcionista(?)", [id]);
    
    if (!rows[0] || rows[0].length === 0) {
      return res.status(404).json({
        success: false,
        message: "Recepcionista no encontrado"
      });
    }
    
    const recepcionista = rows[0][0];
    
    res.json({
      success: true,
      idEmpleado: recepcionista.idEmpleado,
      docId: recepcionista.docId,
      nombres: recepcionista.nombres,
      apellidos: recepcionista.apellidos,
      correo: recepcionista.correo,
      turno: recepcionista.turno,
      estado: recepcionista.estado
    });
  } catch (error) {
    console.error("Error en getById recepcionista:", error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
};

/* =========================
   REGISTRAR NUEVO RECEPCIONISTA
   Usa: sp_registrar_recepcionista(p_docId, p_correo, p_turno)
========================= */
exports.create = async (req, res) => {
  try {
    const { docId, correo, turno } = req.body;
    
    // Validaciones básicas
    if (!docId || !correo || !turno) {
      return res.status(400).json({
        success: false,
        message: "Faltan datos: docId, correo y turno son requeridos"
      });
    }
    
    // Validar que el turno sea válido
    const turnosValidos = ["Mañana", "Tarde", "Noche"];
    if (!turnosValidos.includes(turno)) {
      return res.status(400).json({
        success: false,
        message: "Turno inválido. Use: Mañana, Tarde o Noche"
      });
    }
    
    await pool.query("CALL sp_registrar_recepcionista(?, ?, ?)", [
      docId,
      correo,
      turno
    ]);
    
    res.status(201).json({
      success: true,
      message: "Recepcionista registrado correctamente"
    });
  } catch (error) {
    console.error("Error en create recepcionista:", error);
    
    // Mensajes de error más amigables
    let mensaje = error.message;
    if (mensaje.includes("La persona no existe")) {
      mensaje = "La persona con ese documento no existe en la base de datos";
    } else if (mensaje.includes("La persona ya es recepcionista")) {
      mensaje = "Esta persona ya está registrada como recepcionista";
    } else if (mensaje.includes("Correo ya registrado")) {
      mensaje = "Este correo ya está registrado para otro recepcionista";
    }
    
    res.status(500).json({
      success: false,
      message: mensaje
    });
  }
};

/* =========================
   ACTUALIZAR RECEPCIONISTA (DATOS COMPLETOS)
========================= */
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { docId, correo, turno, estado } = req.body;
    
    // Verificar que existe
    const [existe] = await pool.query(
      "SELECT * FROM Recepcionista WHERE idEmpleado = ?",
      [id]
    );
    
    if (existe.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Recepcionista no encontrado"
      });
    }
    
    // Actualizar datos básicos si se proporcionan
    if (docId) {
      await pool.query(
        "UPDATE Recepcionista SET docId = ? WHERE idEmpleado = ?",
        [docId, id]
      );
    }
    
    if (correo) {
      await pool.query(
        "UPDATE Recepcionista SET correo = ? WHERE idEmpleado = ?",
        [correo, id]
      );
    }
    
    if (turno) {
      await pool.query(
        "UPDATE Recepcionista SET turno = ? WHERE idEmpleado = ?",
        [turno, id]
      );
    }
    
    if (estado) {
      await pool.query(
        "UPDATE Recepcionista SET estado = ? WHERE idEmpleado = ?",
        [estado, id]
      );
    }
    
    res.json({
      success: true,
      message: "Recepcionista actualizado correctamente"
    });
  } catch (error) {
    console.error("Error en update recepcionista:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   CAMBIAR ESTADO DEL RECEPCIONISTA
   Usa: sp_cambiar_estado_recepcionista(p_idEmpleado, p_estado)
========================= */
exports.changeEstado = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;
    
    if (!estado) {
      return res.status(400).json({
        success: false,
        message: "El estado es requerido"
      });
    }
    
    // Validar estado
    const estadosValidos = ["ACTIVO", "INACTIVO"];
    if (!estadosValidos.includes(estado.toUpperCase())) {
      return res.status(400).json({
        success: false,
        message: "Estado inválido. Use: ACTIVO o INACTIVO"
      });
    }
    
    await pool.query("CALL sp_cambiar_estado_recepcionista(?, ?)", [
      id,
      estado.toUpperCase()
    ]);
    
    res.json({
      success: true,
      message: `Estado cambiado a ${estado.toUpperCase()} correctamente`
    });
  } catch (error) {
    console.error("Error en changeEstado recepcionista:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   CAMBIAR TURNO DEL RECEPCIONISTA
   Usa: sp_cambiar_turno(p_idEmpleado, p_turno)
========================= */
exports.changeTurno = async (req, res) => {
  try {
    const { id } = req.params;
    const { turno } = req.body;
    
    if (!turno) {
      return res.status(400).json({
        success: false,
        message: "El turno es requerido"
      });
    }
    
    // Validar turno
    const turnosValidos = ["Mañana", "Tarde", "Noche"];
    if (!turnosValidos.includes(turno)) {
      return res.status(400).json({
        success: false,
        message: "Turno inválido. Use: Mañana, Tarde o Noche"
      });
    }
    
    await pool.query("CALL sp_cambiar_turno(?, ?)", [id, turno]);
    
    res.json({
      success: true,
      message: `Turno cambiado a ${turno} correctamente`
    });
  } catch (error) {
    console.error("Error en changeTurno recepcionista:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   ELIMINAR RECEPCIONISTA
   (Solo si no tiene reservas asociadas)
========================= */
exports.remove = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar si tiene reservas asociadas
    const [reservas] = await pool.query(
      "SELECT COUNT(*) as total FROM Reserva WHERE idEmpleado = ?",
      [id]
    );
    
    if (reservas[0].total > 0) {
      return res.status(400).json({
        success: false,
        message: `No se puede eliminar el recepcionista porque tiene ${reservas[0].total} reservas asociadas. Cámbielo a estado INACTIVO en su lugar.`
      });
    }
    
    await pool.query("DELETE FROM Recepcionista WHERE idEmpleado = ?", [id]);
    
    res.json({
      success: true,
      message: "Recepcionista eliminado correctamente"
    });
  } catch (error) {
    console.error("Error en remove recepcionista:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   OBTENER RECEPCIONISTAS ACTIVOS
   (Para selects y asignaciones)
========================= */
exports.getActivos = async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT r.idEmpleado, CONCAT(p.nombres, ' ', p.apellidos) as nombreCompleto, r.turno " +
      "FROM Recepcionista r " +
      "INNER JOIN Persona p ON r.docId = p.docId " +
      "WHERE r.estado = 'ACTIVO' " +
      "ORDER BY p.nombres"
    );
    
    res.json(rows);
  } catch (error) {
    console.error("Error en getActivos recepcionistas:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};