const pool = require("../config/db");

/* =========================
   CLIENTES FRECUENTES
========================= */
exports.getClientesFrecuentes = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        p.docId,
        CONCAT(p.nombres, ' ', p.apellidos) AS cliente,
        COUNT(r.id) AS total_reservas,
        SUM(r.precio) AS total_gastado
      FROM Persona p
      INNER JOIN Reserva r ON p.docId = r.docIdCliente
      WHERE r.estado IN ('FINALIZADA', 'CHECKIN', 'CONFIRMADA')
      GROUP BY p.docId, p.nombres, p.apellidos
      ORDER BY total_reservas DESC
      LIMIT 10
    `);

    res.json(rows);
  } catch (error) {
    console.error("Error en getClientesFrecuentes:", error);
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   HABITACIONES MÁS USADAS
========================= */
exports.getHabitacionesMasUsadas = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        h.id,
        h.tipo,
        COUNT(r.id) AS veces_reservada
      FROM Habitacion h
      INNER JOIN Reserva r ON h.id = r.idHabitacion
      GROUP BY h.id, h.tipo
      ORDER BY veces_reservada DESC
      LIMIT 10
    `);

    res.json(rows);
  } catch (error) {
    console.error("Error en getHabitacionesMasUsadas:", error);
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   SERVICIOS MÁS VENDIDOS
========================= */
exports.getServiciosMasVendidos = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        s.tipo AS nombre,
        SUM(ds.cantidad) AS cantidad_vendida,
        SUM(ds.subTotal) AS total_generado
      FROM DetalleServicio ds
      INNER JOIN Servicio s ON ds.idServicio = s.id
      GROUP BY s.id, s.tipo
      ORDER BY cantidad_vendida DESC
      LIMIT 10
    `);

    res.json(rows);
  } catch (error) {
    console.error("Error en getServiciosMasVendidos:", error);
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   OCUPACIÓN POR SUCURSAL
========================= */
exports.getOcupacionSucursal = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        s.nombre AS sucursal,
        COUNT(h.id) AS total_habitaciones,
        SUM(CASE WHEN h.estado = 'OCUPADA' THEN 1 ELSE 0 END) AS ocupadas,
        SUM(CASE WHEN h.estado = 'DISPONIBLE' THEN 1 ELSE 0 END) AS disponibles
      FROM Sucursal s
      INNER JOIN Habitacion h ON s.id = h.idSucursal
      GROUP BY s.id, s.nombre
    `);

    res.json(rows);
  } catch (error) {
    console.error("Error en getOcupacionSucursal:", error);
    res.status(500).json({ error: error.message });
  }
};

/* =========================
   INGRESOS MENSUALES
========================= */
exports.getIngresosMensuales = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        YEAR(fecha) AS anio,
        MONTH(fecha) AS mes,
        SUM(monto) AS total_ingresos
      FROM Pago
      GROUP BY YEAR(fecha), MONTH(fecha)
      ORDER BY anio DESC, mes DESC
      LIMIT 12
    `);

    // Convertir número de mes a nombre
    const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    const resultados = rows.map(row => ({
      anio: row.anio,
      mes: meses[row.mes - 1],
      mes_numero: row.mes,
      total_ingresos: parseFloat(row.total_ingresos) || 0
    }));

    res.json(resultados);
  } catch (error) {
    console.error("Error en getIngresosMensuales:", error);
    res.status(500).json({ error: error.message });
  }
};