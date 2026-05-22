const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

const authRoutes = require('./routes/auth.routes');
const personaRoutes = require('./routes/persona.routes');
const habitacionRoutes = require('./routes/habitacion.routes');
const reservaRoutes = require('./routes/reserva.routes');
const servicioRoutes = require('./routes/servicio.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const recepcionistaRoutes = require("./routes/recepcionista.routes");
const pagoRoutes = require("./routes/pago.routes");
const reporteRoutes = require("./routes/reporte.routes"); // ← AGREGAR ESTA LÍNEA

const app = express();

app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir archivos estáticos (HTML, CSS, JS)
app.use(express.static(path.join(__dirname, '../public')));

app.get('/', (req, res) => {
  res.json({ 
    message: 'API HotelDB funcionando correctamente',
    endpoints: {
      auth: '/api/auth/login',
      personas: '/api/personas',
      habitaciones: '/api/habitaciones',
      reservas: '/api/reservas',
      servicios: '/api/servicios'
    }
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/personas', personaRoutes);
app.use('/api/habitaciones', habitacionRoutes);
app.use('/api/reservas', reservaRoutes);
app.use('/api/servicios', servicioRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use("/api/recepcionistas", recepcionistaRoutes);
app.use("/api/pagos", pagoRoutes);
app.use("/api/reportes", reporteRoutes); // ← AGREGAR ESTA LÍNEA

app.use((req, res) => {
  res.status(404).json({ message: 'Ruta no encontrada' });
});

module.exports = app;