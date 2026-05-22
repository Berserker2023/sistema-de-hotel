const mysql = require("mysql2/promise");
require("dotenv").config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'hotel_db',
  waitForConnections: true,
  connectionLimit: 10
});

// Verificar conexión al iniciar
(async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Base de datos conectada exitosamente');
    console.log(`   Host: ${process.env.DB_HOST || 'localhost'}`);
    console.log(`   Base de datos: ${process.env.DB_NAME || 'hotel_db'}`);
    connection.release();
  } catch (error) {
    console.error('❌ Error conectando a la base de datos:');
    console.error(`   ${error.message}`);
    console.log('\n📝 Verifica:');
    console.log('   1. MySQL está corriendo en Laragon');
    console.log('   2. La contraseña en .env es correcta');
    console.log('   3. La base de datos hotel_db existe');
  }
})();

module.exports = pool;