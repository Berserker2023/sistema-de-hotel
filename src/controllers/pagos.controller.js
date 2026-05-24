const pool = require("../config/db");

/* =========================
   REGISTRAR PAGO
   Usa: sp_registrar_pago(p_idReserva, p_monto, p_metodoPago, p_observacion)
========================= */
exports.registrarPago = async (req, res) => {
  try {
    const { idReserva, monto, metodoPago, observacion } = req.body;

    if (!idReserva || !monto || !metodoPago) {
      return res.status(400).json({
        success: false,
        message: "Faltan datos: idReserva, monto y metodoPago son requeridos"
      });
    }

    if (monto <= 0) {
      return res.status(400).json({
        success: false,
        message: "El monto debe ser mayor a 0"
      });
    }

    const metodosValidos = ["Efectivo", "Tarjeta", "Transferencia", "Yape/Plin"];
    if (!metodosValidos.includes(metodoPago)) {
      return res.status(400).json({
        success: false,
        message: "Método de pago inválido"
      });
    }

    await pool.query("CALL sp_registrar_pago(?, ?, ?, ?)", [
      idReserva,
      monto,
      metodoPago,
      observacion || null
    ]);

    res.status(201).json({
      success: true,
      message: "Pago registrado correctamente"
    });
  } catch (error) {
    console.error("Error en registrarPago:", error);
    let mensaje = error.message;
    if (mensaje.includes("Monto inválido")) {
      mensaje = "El monto debe ser mayor a 0";
    } else if (mensaje.includes("Reserva no existe")) {
      mensaje = "La reserva no existe";
    }
    res.status(500).json({
      success: false,
      message: mensaje
    });
  }
};

/* =========================
   HISTORIAL DE PAGOS POR RESERVA
   Usa: sp_historial_pagos_reserva(p_idReserva)
========================= */
exports.getHistorialByReserva = async (req, res) => {
  try {
    const { idReserva } = req.params;

    const [rows] = await pool.query("CALL sp_historial_pagos_reserva(?)", [idReserva]);

    const pagos = (rows[0] || []).map(p => ({
      id: p.id,
      fecha: p.fecha,
      monto: parseFloat(p.monto),
      metodoPago: p.metodoPago,
      observacion: p.observacion,
      estado: p.estado
    }));

    res.json(pagos);
  } catch (error) {
    console.error("Error en getHistorialByReserva:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   TOTAL PAGADO POR RESERVA
   Usa: sp_total_pagado_reserva(p_idReserva)
========================= */
exports.getTotalPagadoByReserva = async (req, res) => {
  try {
    const { idReserva } = req.params;

    const [rows] = await pool.query("CALL sp_total_pagado_reserva(?)", [idReserva]);
    const total = rows[0] && rows[0][0] ? parseFloat(rows[0][0].total_pagado) || 0 : 0;

    res.json({
      success: true,
      totalPagado: total
    });
  } catch (error) {
    console.error("Error en getTotalPagadoByReserva:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   SALDO PENDIENTE POR RESERVA
   Usa: sp_saldo_pendiente_reserva(p_idReserva)
========================= */
exports.getSaldoPendiente = async (req, res) => {
  try {
    const { idReserva } = req.params;

    const [rows] = await pool.query("CALL sp_saldo_pendiente_reserva(?)", [idReserva]);
    const saldo = rows[0] && rows[0][0] ? parseFloat(rows[0][0].saldo_pendiente) || 0 : 0;

    res.json({
      success: true,
      saldoPendiente: saldo
    });
  } catch (error) {
    console.error("Error en getSaldoPendiente:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   ESTADO DE CUENTA COMPLETO
   Usa: sp_estado_cuenta_reserva(p_idReserva)
========================= */
exports.getEstadoCuenta = async (req, res) => {
  try {
    const { idReserva } = req.params;

    const [rows] = await pool.query("CALL sp_estado_cuenta_reserva(?)", [idReserva]);

    if (!rows[0] || rows[0].length === 0) {
      return res.status(404).json({
        success: false,
        message: "Reserva no encontrada"
      });
    }

    const data = rows[0][0];

    res.json({
      success: true,
      reserva: data.reserva,
      hospedaje: parseFloat(data.hospedaje),
      servicios: parseFloat(data.servicios),
      totalConsumido: parseFloat(data.total_consumido),
      totalPagado: parseFloat(data.total_pagado),
      saldo: parseFloat(data.saldo)
    });
  } catch (error) {
    console.error("Error en getEstadoCuenta:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   REPORTE DE CAJA DIARIA
   Usa: sp_reporte_caja_diaria(p_fecha)
========================= */
exports.getCajaDiaria = async (req, res) => {
  try {
    const { fecha } = req.query;
    const fechaBuscar = fecha || new Date().toISOString().split("T")[0];

    const [rows] = await pool.query("CALL sp_reporte_caja_diaria(?)", [fechaBuscar]);

    const reporte = (rows[0] || []).map(r => ({
      fecha: r.fecha,
      metodoPago: r.metodoPago,
      operaciones: r.operaciones,
      total: parseFloat(r.total)
    }));

    const totalGeneral = reporte.reduce((sum, r) => sum + r.total, 0);

    res.json({
      success: true,
      fecha: fechaBuscar,
      detalle: reporte,
      totalGeneral: totalGeneral
    });
  } catch (error) {
    console.error("Error en getCajaDiaria:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   RESERVA CON SALDO PENDIENTE (Para el formulario de pago)
   Combina sp_buscar_reserva + sp_saldo_pendiente_reserva
========================= */
exports.getReservaParaPago = async (req, res) => {
  try {
    const { id } = req.params;

    // Obtener datos de la reserva
    const [reservaRows] = await pool.query("CALL sp_buscar_reserva(?)", [id]);

    if (!reservaRows[0] || reservaRows[0].length === 0) {
      return res.status(404).json({
        success: false,
        message: "Reserva no encontrada"
      });
    }

    const reserva = reservaRows[0][0];

    // Obtener saldo pendiente
    const [saldoRows] = await pool.query("CALL sp_saldo_pendiente_reserva(?)", [id]);
    const saldoPendiente = saldoRows[0] && saldoRows[0][0] ? parseFloat(saldoRows[0][0].saldo_pendiente) || 0 : 0;

    // Obtener total pagado
    const [pagadoRows] = await pool.query("CALL sp_total_pagado_reserva(?)", [id]);
    const totalPagado = pagadoRows[0] && pagadoRows[0][0] ? parseFloat(pagadoRows[0][0].total_pagado) || 0 : 0;

    res.json({
      success: true,
      id: reserva.id,
      fecha: reserva.fecha,
      fechaEntrada: reserva.fechaEntrada,
      fechaSalida: reserva.fechaSalida,
      estado: reserva.estado,
      precio: parseFloat(reserva.precio),
      cliente: reserva.cliente,
      habitacion: reserva.habitacion,
      totalPagado: totalPagado,
      saldoPendiente: saldoPendiente
    });
  } catch (error) {
    console.error("Error en getReservaParaPago:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   RESERVAS ACTIVAS (Para el combo de selección)
   Usa: sp_reservas_activas()
========================= */
exports.getReservasActivas = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL sp_reservas_activas()");

    const reservas = (rows[0] || []).map(r => ({
      id: r.id,
      cliente: r.cliente,
      docIdCliente: r.docIdCliente,
      idHabitacion: r.idHabitacion,
      fechaEntrada: r.fechaEntrada,
      fechaSalida: r.fechaSalida,
      estado: r.estado,
      precio: parseFloat(r.precio)
    }));

    res.json(reservas);
  } catch (error) {
    console.error("Error en getReservasActivas:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};