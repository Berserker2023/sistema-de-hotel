const { promisePool } = require('../config/db');

const loginRecepcionista = async (correo) => {
    try {
        const [rows] = await promisePool.execute(
            'CALL sp_login_recepcionista(?)',
            [correo]
        );
        
        // Los SP devuelven múltiples resultados, el primero es el dataset
        if (rows[0] && rows[0].length > 0) {
            return rows[0][0];
        }
        return null;
    } catch (error) {
        console.error('Error en login service:', error);
        throw error;
    }
};

module.exports = { loginRecepcionista };