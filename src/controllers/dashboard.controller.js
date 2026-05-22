const pool = require("../config/db");

/* =========================
   DASHBOARD GENERAL
   Usa: sp_dashboard_general()
========================= */
exports.getGeneral = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL sp_dashboard_general()");
    
    // El SP devuelve los resultados en rows[0][0]
    const data = rows[0][0] || {};
    
    res.json({
      success: true,
      total_reservas: data.total_reservas || 0,
      total_clientes: data.total_clientes || 0,
      habitaciones_ocupadas: data.habitaciones_ocupadas || 0,
      ingresos_totales: parseFloat(data.ingresos_totales) || 0,
      ventas_servicios: parseFloat(data.ventas_servicios) || 0
    });
  } catch (error) {
    console.error("Error en getGeneral:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   INGRESOS POR FECHA ESPECÍFICA
   Usa: sp_ingresos_por_fecha(p_fecha)
========================= */
exports.getIngresosPorFecha = async (req, res) => {
  try {
    const { fecha } = req.query;
    const fechaBuscar = fecha || new Date().toISOString().split("T")[0];
    
    const [rows] = await pool.query("CALL sp_ingresos_por_fecha(?)", [fechaBuscar]);
    
    res.json({
      success: true,
      fecha: fechaBuscar,
      ingresos: rows[0] || []
    });
  } catch (error) {
    console.error("Error en getIngresosPorFecha:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   INGRESOS ÚLTIMOS 7 DÍAS
   (Para el gráfico del dashboard)
========================= */
exports.getIngresosUltimos7Dias = async (req, res) => {
  try {
    const ingresos = [];
    
    for (let i = 6; i >= 0; i--) {
      const fecha = new Date();
      fecha.setDate(fecha.getDate() - i);
      const fechaStr = fecha.toISOString().split("T")[0];
      
      const [rows] = await pool.query("CALL sp_ingresos_por_fecha(?)", [fechaStr]);
      const total = rows[0] && rows[0][0] ? parseFloat(rows[0][0].total_ingresado) || 0 : 0;
      
      ingresos.push({
        fecha: fechaStr,
        total_ingresado: total
      });
    }
    
    res.json({
      success: true,
      ingresos
    });
  } catch (error) {
    console.error("Error en getIngresosUltimos7Dias:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   RESERVAS ACTIVAS (CONFIRMADA o CHECKIN)
   Usa: sp_reservas_activas()
========================= */
exports.getReservasActivas = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL sp_reservas_activas()");
    
    const reservas = (rows[0] || []).map(r => ({
      id: r.id,
      fecha: r.fecha,
      fechaEntrada: r.fechaEntrada,
      fechaSalida: r.fechaSalida,
      estado: r.estado,
      precio: parseFloat(r.precio),
      cliente: r.cliente,
      docIdCliente: r.docIdCliente,
      idHabitacion: r.idHabitacion
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

/* =========================
   BUSCAR RESERVA POR ID
   Usa: sp_buscar_reserva(p_idReserva)
========================= */
exports.getReservaById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query("CALL sp_buscar_reserva(?)", [id]);
    
    if (!rows[0] || rows[0].length === 0) {
      return res.status(404).json({
        success: false,
        message: "Reserva no encontrada"
      });
    }
    
    const reserva = rows[0][0];
    
    // Obtener saldo pendiente
    const [saldoRows] = await pool.query("CALL sp_saldo_pendiente_reserva(?)", [id]);
    const saldoPendiente = saldoRows[0] && saldoRows[0][0] ? parseFloat(saldoRows[0][0].saldo_pendiente) || 0 : 0;
    
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
      saldoPendiente: saldoPendiente
    });
  } catch (error) {
    console.error("Error en getReservaById:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/* =========================
   ESTADO DE CUENTA DE RESERVA
   Usa: sp_estado_cuenta_reserva(p_idReserva)
========================= */
exports.getEstadoCuenta = async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query("CALL sp_estado_cuenta_reserva(?)", [id]);
    
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
      total_consumido: parseFloat(data.total_consumido),
      total_pagado: parseFloat(data.total_pagado),
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