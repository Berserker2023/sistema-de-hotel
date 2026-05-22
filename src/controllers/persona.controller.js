const pool = require("../config/db");

/* LISTAR */
exports.getAll = async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM Persona ORDER BY apellidos, nombres"
    );

    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* BUSCAR POR ID */
exports.getById = async (req, res) => {
  try {
    const { docId } = req.params;

    const [rows] = await pool.query(
      "SELECT * FROM Persona WHERE docId = ?",
      [docId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: "Cliente no encontrado"
      });
    }

    res.json(rows[0]);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* REGISTRAR */
exports.create = async (req, res) => {
  try {
    const {
      docId,
      nombres,
      apellidos,
      correo,
      nacionalidad,
      fechaNac,
      sexo
    } = req.body;

    await pool.query(
      `INSERT INTO Persona
      (docId,nombres,apellidos,correo,nacionalidad,fechaNac,sexo)
      VALUES (?,?,?,?,?,?,?)`,
      [
        docId,
        nombres,
        apellidos,
        correo,
        nacionalidad,
        fechaNac,
        sexo
      ]
    );

    res.status(201).json({
      message: "Cliente registrado correctamente"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* ACTUALIZAR */
exports.update = async (req, res) => {
  try {
    const { docId } = req.params;

    const {
      nombres,
      apellidos,
      correo,
      nacionalidad,
      fechaNac,
      sexo
    } = req.body;

    await pool.query(
      `UPDATE Persona
       SET nombres=?,
           apellidos=?,
           correo=?,
           nacionalidad=?,
           fechaNac=?,
           sexo=?
       WHERE docId=?`,
      [
        nombres,
        apellidos,
        correo,
        nacionalidad,
        fechaNac,
        sexo,
        docId
      ]
    );

    res.json({
      message: "Cliente actualizado"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/* ELIMINAR */
exports.remove = async (req, res) => {
  try {
    const { docId } = req.params;

    await pool.query(
      "DELETE FROM Persona WHERE docId = ?",
      [docId]
    );

    res.json({
      message: "Cliente eliminado"
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};