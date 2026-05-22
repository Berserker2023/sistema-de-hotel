require('dotenv').config(); // ← ESTA LÍNEA PRIMERO

const app = require('./app');

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(`Servidor activo en puerto ${PORT}`);
});