const pool = require('./src/config/db');

async function diagnoseDatabase() {
  try {
    console.log('\n🔍 Verificando estructura de base de datos...\n');

    // Verificar tabla DetalleServicio
    console.log('📋 Tabla: DetalleServicio');
    try {
      const [cols] = await pool.query("SHOW COLUMNS FROM DetalleServicio");
      console.log('✅ Tabla existe. Columnas:');
      cols.forEach(col => {
        console.log(`   - ${col.Field} (${col.Type})`);
      });
    } catch (err) {
      console.log(`❌ Tabla no existe: ${err.message}`);
    }

    // Verificar tabla Servicio
    console.log('\n📋 Tabla: Servicio');
    try {
      const [cols] = await pool.query("SHOW COLUMNS FROM Servicio");
      console.log('✅ Tabla existe. Columnas:');
      cols.forEach(col => {
        console.log(`   - ${col.Field} (${col.Type})`);
      });
    } catch (err) {
      console.log(`❌ Tabla no existe: ${err.message}`);
    }

    // Verificar datos en Servicio
    console.log('\n📊 Datos en tabla Servicio:');
    try {
      const [servicios] = await pool.query("SELECT * FROM Servicio LIMIT 3");
      if (servicios.length > 0) {
        console.log(`✅ Hay ${servicios.length} servicio(s):`);
        servicios.forEach((s, i) => {
          console.log(`   ${i+1}. ID: ${s.id}, Tipo: ${s.tipo}, Precio: ${s.precio}`);
        });
      } else {
        console.log('⚠️  No hay servicios registrados');
      }
    } catch (err) {
      console.log(`❌ Error: ${err.message}`);
    }

    // Verificar datos en DetalleServicio
    console.log('\n📊 Datos en tabla DetalleServicio:');
    try {
      const [detalles] = await pool.query("SELECT * FROM DetalleServicio LIMIT 3");
      if (detalles.length > 0) {
        console.log(`✅ Hay ${detalles.length} consumo(s):`);
        detalles.forEach((d, i) => {
          console.log(`   ${i+1}. Reserva: ${d.idReserva}, Servicio: ${d.idServicio}, Cantidad: ${d.cantidad}`);
        });
      } else {
        console.log('⚠️  No hay consumos registrados');
      }
    } catch (err) {
      console.log(`❌ Error: ${err.message}`);
    }

    console.log('\n✅ Diagnóstico completado\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error general:', error.message);
    process.exit(1);
  }
}

diagnoseDatabase();
