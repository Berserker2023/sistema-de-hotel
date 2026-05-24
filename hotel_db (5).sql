-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 24-05-2026 a las 03:14:18
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `hotel_db`
--

CREATE DATABASE IF NOT EXISTS `hotel_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `hotel_db`;

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_habitacion` (IN `p_id` CHAR(4), IN `p_tipo` VARCHAR(15), IN `p_piso` INT, IN `p_idSucursal` INT)   BEGIN

    UPDATE Habitacion
    SET tipo = p_tipo,
        piso = p_piso,
        idSucursal = p_idSucursal
    WHERE id = p_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_persona` (IN `p_docId` VARCHAR(11), IN `p_nombres` VARCHAR(100), IN `p_apellidos` VARCHAR(100), IN `p_correo` VARCHAR(100), IN `p_nacionalidad` VARCHAR(20), IN `p_fechaNac` DATE, IN `p_sexo` CHAR(1))   BEGIN
    UPDATE Persona
    SET nombres = p_nombres,
        apellidos = p_apellidos,
        correo = p_correo,
        nacionalidad = p_nacionalidad,
        fechaNac = p_fechaNac,
        sexo = p_sexo
    WHERE docId = p_docId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_servicio` (IN `p_id` INT, IN `p_nombre` VARCHAR(100), IN `p_precio` DECIMAL(10,2))   BEGIN

    UPDATE Servicio
    SET nombre = p_nombre,
        precio = p_precio
    WHERE id = p_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_agregar_huesped_reserva` (IN `p_idReserva` INT, IN `p_docId` VARCHAR(11))   BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM Reserva
        WHERE id = p_idReserva
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Reserva no existe';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM Persona
        WHERE docId = p_docId
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Persona no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ReservaHuesped
        WHERE idReserva = p_idReserva
        AND docId = p_docId
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Huésped ya agregado';
    END IF;

    INSERT INTO ReservaHuesped(
        idReserva,
        docId
    )
    VALUES(
        p_idReserva,
        p_docId
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_agregar_servicio_reserva` (IN `p_idReserva` INT, IN `p_idServicio` INT, IN `p_cantidad` INT)   BEGIN

    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_estado VARCHAR(15);

    SELECT precio, estado
    INTO v_precio, v_estado
    FROM Servicio
    WHERE id = p_idServicio;

    IF v_precio IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Servicio no existe';
    END IF;

    IF v_estado <> 'ACTIVO' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Servicio inactivo';
    END IF;

    INSERT INTO DetalleServicio(
        idReserva,
        idServicio,
        cantidad,
        precioUnitario,
        subtotal,
        fecha
    )
    VALUES(
        p_idReserva,
        p_idServicio,
        p_cantidad,
        v_precio,
        p_cantidad * v_precio,
        NOW()
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_habitacion` (IN `p_id` CHAR(4))   BEGIN

    SELECT h.id,
           h.tipo,
           h.piso,
           h.estado,
           s.nombre AS sucursal
    FROM Habitacion h
    INNER JOIN Sucursal s
        ON h.idSucursal = s.id
    WHERE h.id = p_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_persona` (IN `p_docId` VARCHAR(11))   BEGIN
    SELECT *
    FROM Persona
    WHERE docId = p_docId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_recepcionista` (IN `p_idEmpleado` INT)   BEGIN

    SELECT r.idEmpleado,
           p.docId,
           p.nombres,
           p.apellidos,
           r.correo,
           r.turno,
           r.estado
    FROM Recepcionista r
    INNER JOIN Persona p
        ON r.docId = p.docId
    WHERE r.idEmpleado = p_idEmpleado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT r.id,
           r.fecha,
           r.fechaEntrada,
           r.fechaSalida,
           r.estado,
           r.precio,
           CONCAT(p.nombres,' ',p.apellidos) AS cliente,
           h.id AS habitacion
    FROM Reserva r
    INNER JOIN Persona p
        ON r.docIdCliente = p.docId
    INNER JOIN Habitacion h
        ON r.idHabitacion = h.id
    WHERE r.id = p_idReserva;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_estado_habitacion` (IN `p_id` CHAR(4), IN `p_estado` VARCHAR(20))   BEGIN

    UPDATE Habitacion
    SET estado = p_estado
    WHERE id = p_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_estado_recepcionista` (IN `p_idEmpleado` INT, IN `p_estado` VARCHAR(10))   BEGIN

    UPDATE Recepcionista
    SET estado = p_estado
    WHERE idEmpleado = p_idEmpleado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_estado_servicio` (IN `p_id` INT, IN `p_estado` VARCHAR(15))   BEGIN

    UPDATE Servicio
    SET estado = p_estado
    WHERE id = p_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_turno` (IN `p_idEmpleado` INT, IN `p_turno` VARCHAR(10))   BEGIN

    UPDATE Recepcionista
    SET turno = p_turno
    WHERE idEmpleado = p_idEmpleado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_reserva` (IN `p_idReserva` INT)   BEGIN

    UPDATE Reserva
    SET estado='CANCELADA'
    WHERE id = p_idReserva;

    UPDATE Habitacion
    SET estado='DISPONIBLE'
    WHERE id = (
        SELECT idHabitacion
        FROM Reserva
        WHERE id = p_idReserva
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_checkin_reserva` (IN `p_idReserva` INT)   BEGIN

    UPDATE Reserva
    SET estado='CHECKIN'
    WHERE id = p_idReserva;

    UPDATE Habitacion
    SET estado='OCUPADA'
    WHERE id = (
        SELECT idHabitacion
        FROM Reserva
        WHERE id = p_idReserva
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_checkout_reserva` (IN `p_idReserva` INT)   BEGIN

    UPDATE Reserva
    SET estado='FINALIZADA'
    WHERE id = p_idReserva;

    UPDATE Habitacion
    SET estado='LIMPIEZA'
    WHERE id = (
        SELECT idHabitacion
        FROM Reserva
        WHERE id = p_idReserva
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dashboard_general` ()   BEGIN

    SELECT
    (SELECT COUNT(*) FROM Reserva) AS total_reservas,
    (SELECT COUNT(*) FROM Persona) AS total_clientes,
    (SELECT COUNT(*) FROM Habitacion WHERE estado='OCUPADA') AS habitaciones_ocupadas,
    (SELECT IFNULL(SUM(monto),0) FROM Pago) AS ingresos_totales,
    (SELECT IFNULL(SUM(subtotal),0) FROM DetalleServicio) AS ventas_servicios;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_detalle_servicios_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT ds.id,
           s.nombre,
           ds.cantidad,
           ds.precioUnitario,
           ds.subtotal,
           ds.fecha
    FROM DetalleServicio ds
    INNER JOIN Servicio s
        ON ds.idServicio = s.id
    WHERE ds.idReserva = p_idReserva
    ORDER BY ds.fecha;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_persona` (IN `p_docId` VARCHAR(11))   BEGIN
    DELETE FROM Persona
    WHERE docId = p_docId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_estado_cuenta_reserva` (IN `p_idReserva` INT)   BEGIN

    DECLARE v_hospedaje DECIMAL(10,2);
    DECLARE v_servicios DECIMAL(10,2);
    DECLARE v_pagado DECIMAL(10,2);

    SELECT precio
    INTO v_hospedaje
    FROM Reserva
    WHERE id = p_idReserva;

    SELECT IFNULL(SUM(subtotal),0)
    INTO v_servicios
    FROM DetalleServicio
    WHERE idReserva = p_idReserva;

    SELECT IFNULL(SUM(monto),0)
    INTO v_pagado
    FROM Pago
    WHERE idReserva = p_idReserva;

    SELECT p_idReserva AS reserva,
           v_hospedaje AS hospedaje,
           v_servicios AS servicios,
           (v_hospedaje + v_servicios) AS total_consumido,
           v_pagado AS total_pagado,
           (v_hospedaje + v_servicios - v_pagado) AS saldo;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_habitaciones_disponibles` ()   BEGIN

    SELECT *
    FROM Habitacion
    WHERE estado = 'DISPONIBLE'
    ORDER BY piso,id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_habitaciones_ocupadas` ()   BEGIN

    SELECT *
    FROM Habitacion
    WHERE estado = 'OCUPADA'
    ORDER BY piso,id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_habitaciones_por_piso` (IN `p_piso` INT)   BEGIN

    SELECT *
    FROM Habitacion
    WHERE piso = p_piso
    ORDER BY id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_habitaciones_por_tipo` (IN `p_tipo` VARCHAR(15))   BEGIN

    SELECT *
    FROM Habitacion
    WHERE tipo = p_tipo
    ORDER BY id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_historial_cliente` (IN `p_docId` VARCHAR(11))   BEGIN

    SELECT *
    FROM Reserva
    WHERE docIdCliente = p_docId
    ORDER BY fecha DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_historial_pagos_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT *
    FROM Pago
    WHERE idReserva = p_idReserva
    ORDER BY fecha;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ingresos_por_fecha` (IN `p_fecha` DATE)   BEGIN

    SELECT DATE(fecha) AS fecha,
           SUM(monto) AS total_ingresado
    FROM Pago
    WHERE DATE(fecha) = p_fecha
    GROUP BY DATE(fecha);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_habitaciones` ()   BEGIN

    SELECT h.id,
           h.tipo,
           h.piso,
           h.estado,
           s.nombre AS sucursal
    FROM Habitacion h
    INNER JOIN Sucursal s
        ON h.idSucursal = s.id
    ORDER BY h.id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_huespedes_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT p.docId,
           p.nombres,
           p.apellidos,
           p.correo,
           p.nacionalidad
    FROM ReservaHuesped rh
    INNER JOIN Persona p
        ON rh.docId = p.docId
    WHERE rh.idReserva = p_idReserva
    ORDER BY p.apellidos;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_personas` ()   BEGIN
    SELECT *
    FROM Persona
    ORDER BY apellidos, nombres;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_recepcionistas` ()   BEGIN

    SELECT r.idEmpleado,
           p.docId,
           CONCAT(p.nombres,' ',p.apellidos) AS empleado,
           r.correo,
           r.turno,
           r.estado
    FROM Recepcionista r
    INNER JOIN Persona p
        ON r.docId = p.docId
    ORDER BY empleado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_servicios` ()   BEGIN

    SELECT *
    FROM Servicio
    ORDER BY nombre;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_recepcionista` (IN `p_correo` VARCHAR(100))   BEGIN

    SELECT r.idEmpleado,
           p.nombres,
           p.apellidos,
           r.correo,
           r.turno,
           r.estado
    FROM Recepcionista r
    INNER JOIN Persona p
        ON r.docId = p.docId
    WHERE r.correo = p_correo
      AND r.estado = 'ACTIVO';

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_quitar_huesped_reserva` (IN `p_idReserva` INT, IN `p_docId` VARCHAR(11))   BEGIN

    DELETE FROM ReservaHuesped
    WHERE idReserva = p_idReserva
      AND docId = p_docId;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_habitacion` (IN `p_id` CHAR(4), IN `p_tipo` VARCHAR(15), IN `p_piso` INT, IN `p_idSucursal` INT)   BEGIN

    IF EXISTS (
        SELECT 1 FROM Habitacion WHERE id = p_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='La habitación ya existe';
    END IF;

    INSERT INTO Habitacion(
        id,tipo,piso,estado,idSucursal
    )
    VALUES(
        p_id,
        p_tipo,
        p_piso,
        'DISPONIBLE',
        p_idSucursal
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_pago` (IN `p_idReserva` INT, IN `p_monto` DECIMAL(10,2), IN `p_metodoPago` VARCHAR(20), IN `p_observacion` VARCHAR(200))   BEGIN
    IF NOT EXISTS (SELECT 1 FROM Reserva WHERE id = p_idReserva) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Reserva no existe';
    END IF;

    INSERT INTO Pago(idReserva, fecha, monto, metodo, estado)
    VALUES(p_idReserva, NOW(), p_monto, p_metodoPago, 'Pagado');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_persona` (IN `p_docId` VARCHAR(11), IN `p_nombres` VARCHAR(100), IN `p_apellidos` VARCHAR(100), IN `p_correo` VARCHAR(100), IN `p_nacionalidad` VARCHAR(20), IN `p_fechaNac` DATE, IN `p_sexo` CHAR(1))   BEGIN
    IF EXISTS (SELECT 1 FROM Persona WHERE docId = p_docId) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El documento ya existe';
    ELSE
        INSERT INTO Persona(
            docId,nombres,apellidos,correo,
            nacionalidad,fechaNac,sexo
        )
        VALUES(
            p_docId,p_nombres,p_apellidos,p_correo,
            p_nacionalidad,p_fechaNac,p_sexo
        );
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_recepcionista` (IN `p_docId` VARCHAR(11), IN `p_correo` VARCHAR(100), IN `p_turno` VARCHAR(10))   BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM Persona WHERE docId = p_docId
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='La persona no existe';
    END IF;

    IF EXISTS (
        SELECT 1 FROM Recepcionista WHERE docId = p_docId
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='La persona ya es recepcionista';
    END IF;

    IF EXISTS (
        SELECT 1 FROM Recepcionista WHERE correo = p_correo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Correo ya registrado';
    END IF;

    INSERT INTO Recepcionista(
        docId, correo, turno, estado
    )
    VALUES(
        p_docId,
        p_correo,
        p_turno,
        'ACTIVO'
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_reserva` (IN `p_fechaEntrada` DATETIME, IN `p_fechaSalida` DATETIME, IN `p_precio` DECIMAL(10,2), IN `p_idEmpleado` INT, IN `p_docIdCliente` VARCHAR(11), IN `p_idHabitacion` CHAR(4))   BEGIN

    DECLARE v_estado VARCHAR(20);

    IF p_fechaSalida <= p_fechaEntrada THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Fecha salida inválida';
    END IF;

    SELECT estado INTO v_estado
    FROM Habitacion
    WHERE id = p_idHabitacion;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Habitación no existe';
    END IF;

    IF v_estado <> 'DISPONIBLE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Habitación no disponible';
    END IF;

    INSERT INTO Reserva(
        fecha,
        fechaEntrada,
        fechaSalida,
        estado,
        precio,
        idEmpleado,
        docIdCliente,
        idHabitacion
    )
    VALUES(
        NOW(),
        p_fechaEntrada,
        p_fechaSalida,
        'CONFIRMADA',
        p_precio,
        p_idEmpleado,
        p_docIdCliente,
        p_idHabitacion
    );

    UPDATE Habitacion
    SET estado='RESERVADA'
    WHERE id = p_idHabitacion;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_servicio` (IN `p_nombre` VARCHAR(100), IN `p_precio` DECIMAL(10,2))   BEGIN

    INSERT INTO Servicio(
        nombre,
        precio,
        estado
    )
    VALUES(
        p_nombre,
        p_precio,
        'ACTIVO'
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_caja_diaria` (IN `p_fecha` DATE)   BEGIN

    SELECT DATE(fecha) AS fecha,
           metodoPago,
           COUNT(*) AS operaciones,
           SUM(monto) AS total
    FROM Pago
    WHERE DATE(fecha)=p_fecha
    GROUP BY DATE(fecha), metodoPago;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_clientes_frecuentes` ()   BEGIN

    SELECT p.docId,
           CONCAT(p.nombres,' ',p.apellidos) AS cliente,
           COUNT(r.id) AS total_reservas,
           SUM(r.precio) AS total_hospedaje
    FROM Reserva r
    INNER JOIN Persona p
        ON r.docIdCliente = p.docId
    WHERE r.estado IN ('FINALIZADA','CHECKIN','CONFIRMADA')
    GROUP BY p.docId, cliente
    ORDER BY total_reservas DESC
    LIMIT 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_habitaciones_mas_usadas` ()   BEGIN

    SELECT h.id,
           h.tipo,
           COUNT(r.id) AS veces_reservada
    FROM Reserva r
    INNER JOIN Habitacion h
        ON r.idHabitacion = h.id
    GROUP BY h.id,h.tipo
    ORDER BY veces_reservada DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_ingresos_mensuales` ()   BEGIN

    SELECT YEAR(fecha) AS anio,
           MONTH(fecha) AS mes,
           SUM(monto) AS total_ingresos
    FROM Pago
    GROUP BY YEAR(fecha), MONTH(fecha)
    ORDER BY anio DESC, mes DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_ocupacion_sucursal` ()   BEGIN

    SELECT su.nombre AS sucursal,
           COUNT(h.id) AS total_habitaciones,
           SUM(CASE WHEN h.estado='OCUPADA' THEN 1 ELSE 0 END) AS ocupadas,
           SUM(CASE WHEN h.estado='DISPONIBLE' THEN 1 ELSE 0 END) AS disponibles
    FROM Sucursal su
    INNER JOIN Habitacion h
        ON su.id = h.idSucursal
    GROUP BY su.nombre;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_servicios_mas_vendidos` ()   BEGIN

    SELECT s.nombre,
           SUM(ds.cantidad) AS cantidad_vendida,
           SUM(ds.subtotal) AS total_generado
    FROM DetalleServicio ds
    INNER JOIN Servicio s
        ON ds.idServicio = s.id
    GROUP BY s.nombre
    ORDER BY cantidad_vendida DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reservas_activas` ()   BEGIN

    SELECT *
    FROM Reserva
    WHERE estado IN ('CONFIRMADA','CHECKIN')
    ORDER BY fechaEntrada;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reservas_activas_cliente` (IN `p_docIdCliente` VARCHAR(11))   BEGIN
    SELECT 
        r.id AS idReserva,
        r.fecha,
        r.fechaEntrada,
        r.fechaSalida,
        r.estado,
        r.precio,
        h.id AS habitacion,
        h.tipo AS tipoHabitacion,
        p.nombres,
        p.apellidos
    FROM Reserva r
    INNER JOIN Persona p 
        ON r.docIdCliente = p.docId
    INNER JOIN Habitacion h 
        ON r.idHabitacion = h.id
    WHERE r.docIdCliente = p_docIdCliente
      AND r.estado = 'Activa';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_saldo_pendiente_reserva` (IN `p_idReserva` INT)   BEGIN

    DECLARE v_hospedaje DECIMAL(10,2);
    DECLARE v_servicios DECIMAL(10,2);
    DECLARE v_pagado DECIMAL(10,2);

    SELECT precio
    INTO v_hospedaje
    FROM Reserva
    WHERE id = p_idReserva;

    SELECT IFNULL(SUM(subtotal),0)
    INTO v_servicios
    FROM DetalleServicio
    WHERE idReserva = p_idReserva;

    SELECT IFNULL(SUM(monto),0)
    INTO v_pagado
    FROM Pago
    WHERE idReserva = p_idReserva;

    SELECT (v_hospedaje + v_servicios - v_pagado) AS saldo_pendiente;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_total_huespedes_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT COUNT(*) AS total_huespedes
    FROM ReservaHuesped
    WHERE idReserva = p_idReserva;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_total_pagado_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT IFNULL(SUM(monto),0) AS total_pagado
    FROM Pago
    WHERE idReserva = p_idReserva;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_total_servicios_reserva` (IN `p_idReserva` INT)   BEGIN

    SELECT IFNULL(SUM(subtotal),0) AS total_servicios
    FROM DetalleServicio
    WHERE idReserva = p_idReserva;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoriapago`
--

CREATE TABLE `auditoriapago` (
  `id` int(11) NOT NULL,
  `idPago` int(11) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `monto` decimal(10,2) DEFAULT NULL,
  `metodo` varchar(20) DEFAULT NULL,
  `accion` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `auditoriapago`
--

INSERT INTO `auditoriapago` (`id`, `idPago`, `fecha`, `monto`, `metodo`, `accion`) VALUES
(1, 256, '2026-05-20 13:10:45', 0.00, 'Tarjeta', 'INSERT'),
(2, 257, '2026-05-20 14:27:39', 0.00, 'Tarjeta', 'INSERT'),
(3, 258, '2026-05-21 18:02:07', 0.00, 'Tarjeta', 'INSERT'),
(4, 259, '2026-05-21 19:29:14', 250.00, 'Transferencia', 'INSERT'),
(5, 260, '2026-05-21 20:33:16', 250.00, 'Transferencia', 'INSERT'),
(6, 261, '2026-05-21 20:34:05', 1000.00, 'Yape/Plin', 'INSERT'),
(7, 262, '2026-05-21 21:42:25', 225.00, 'Tarjeta', 'INSERT'),
(8, 263, '2026-05-21 21:45:36', 15.00, 'Tarjeta', 'INSERT'),
(9, 264, '2026-05-23 19:13:28', 440.00, 'Tarjeta', 'INSERT');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoriapersona`
--

CREATE TABLE `auditoriapersona` (
  `id` int(11) NOT NULL,
  `docId` varchar(11) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `accion` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalleservicio`
--

CREATE TABLE `detalleservicio` (
  `idReserva` int(11) NOT NULL,
  `idServicio` int(11) NOT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `subTotal` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalleservicio`
--

INSERT INTO `detalleservicio` (`idReserva`, `idServicio`, `cantidad`, `precio`, `subTotal`) VALUES
(1, 1, 2, 25.00, 50.00),
(1, 2, 1, 30.00, 30.00),
(2, 3, 1, 80.00, 80.00),
(2, 5, 3, 15.00, 45.00),
(3, 4, 1, 60.00, 60.00),
(4, 1, 2, 25.00, 50.00),
(4, 6, 1, 70.00, 70.00),
(5, 2, 2, 30.00, 60.00),
(5, 7, 1, 40.00, 40.00),
(6, 8, 1, 35.00, 35.00),
(7, 1, 1, 25.00, 25.00),
(7, 5, 2, 15.00, 30.00),
(8, 3, 1, 80.00, 80.00),
(8, 6, 1, 70.00, 70.00),
(9, 4, 2, 60.00, 120.00),
(10, 2, 1, 30.00, 30.00),
(10, 7, 1, 40.00, 40.00),
(120, 6, 1, 0.00, 0.00),
(149, 1, 2, 25.00, 50.00),
(149, 5, 1, 15.00, 15.00),
(149, 9, 3, 50.00, 150.00),
(157, 6, 3, 70.00, 210.00),
(157, 9, 4, 50.00, 200.00),
(158, 6, 2, 70.00, 140.00);

--
-- Disparadores `detalleservicio`
--
DELIMITER $$
CREATE TRIGGER `tr_detalleservicio_subtotal` BEFORE INSERT ON `detalleservicio` FOR EACH ROW BEGIN

    -- Antes de guardar un servicio consumido,
    -- se calcula automáticamente:
    -- subtotal = cantidad * precio unitario

    SET NEW.subtotal = NEW.cantidad * NEW.precio;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `habitacion`
--

CREATE TABLE `habitacion` (
  `id` char(4) NOT NULL,
  `tipo` varchar(15) DEFAULT NULL,
  `piso` int(11) DEFAULT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `idSucursal` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `habitacion`
--

INSERT INTO `habitacion` (`id`, `tipo`, `piso`, `estado`, `idSucursal`) VALUES
('H101', 'Simple', 1, 'RESERVADA', 1),
('H102', 'Doble', 1, 'Disponible', 1),
('H103', 'Suite', 1, 'Ocupado', 1),
('H104', 'Simple', 1, 'Disponible', 1),
('H105', 'Simple', 1, 'Disponible', 2),
('H106', 'Doble', 1, 'Disponible', 2),
('H107', 'Suite', 1, 'Disponible', 2),
('H108', 'Simple', 1, 'Mantenimiento', 2),
('H109', 'Simple', 1, 'Disponible', 3),
('H110', 'Doble', 1, 'Disponible', 3),
('H111', 'Suite', 1, 'Disponible', 3),
('H112', 'Simple', 1, 'Disponible', 3),
('H201', 'Doble', 2, 'Disponible', 1),
('H202', 'Suite', 2, 'Mantenimiento', 1),
('H203', 'Simple', 2, 'Disponible', 1),
('H204', 'Doble', 2, 'Disponible', 1),
('H205', 'Doble', 2, 'Disponible', 2),
('H206', 'Suite', 2, 'Ocupado', 2),
('H207', 'Simple', 2, 'Disponible', 2),
('H208', 'Doble', 2, 'Disponible', 2),
('H209', 'Doble', 2, 'Ocupado', 3),
('H210', 'Suite', 2, 'Disponible', 3),
('H211', 'Simple', 2, 'Disponible', 3),
('H212', 'Doble', 2, 'Mantenimiento', 3),
('H301', 'Suite', 3, 'Disponible', 1),
('H302', 'Simple', 3, 'Ocupado', 1),
('H303', 'Doble', 3, 'Disponible', 1),
('H304', 'Suite', 3, 'Disponible', 1),
('H305', 'Suite', 3, 'Disponible', 2),
('H306', 'Simple', 3, 'Disponible', 2),
('H307', 'Doble', 3, 'Ocupado', 2),
('H308', 'Suite', 3, 'Disponible', 2),
('H309', 'Suite', 3, 'Disponible', 3),
('H310', 'Simple', 3, 'Disponible', 3),
('H311', 'Doble', 3, 'Disponible', 3),
('H312', 'Suite', 3, 'Ocupado', 3),
('H314', 'Doble', 4, 'LIMPIEZA', 3),
('H500', 'Doble', 2, 'OCUPADA', 3);

--
-- Disparadores `habitacion`
--
DELIMITER $$
CREATE TRIGGER `tr_habitacion_validar_estado` BEFORE UPDATE ON `habitacion` FOR EACH ROW BEGIN

    -- Antes de actualizar una habitación,
    -- se valida que el nuevo estado sea válido

    IF NEW.estado NOT IN (
        'DISPONIBLE',
        'OCUPADA',
        'RESERVADA',
        'LIMPIEZA',
        'MANTENIMIENTO'
    ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Estado inválido para habitación';

    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pago`
--

CREATE TABLE `pago` (
  `id` int(11) NOT NULL,
  `fecha` datetime DEFAULT NULL,
  `monto` decimal(10,2) DEFAULT NULL,
  `metodo` varchar(20) DEFAULT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `idReserva` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pago`
--

INSERT INTO `pago` (`id`, `fecha`, `monto`, `metodo`, `estado`, `idReserva`) VALUES
(1, '2024-01-05 15:00:00', 200.00, 'Efectivo', 'Pagado', 1),
(2, '2024-01-06 15:00:00', 300.00, 'Tarjeta', 'Pagado', 2),
(3, '2024-01-07 15:00:00', 450.00, 'Transferencia', 'Pagado', 3),
(4, '2024-01-08 15:00:00', 200.00, 'Efectivo', 'Pagado', 4),
(5, '2024-01-09 15:00:00', 300.00, 'Tarjeta', 'Pagado', 5),
(6, '2024-01-10 15:00:00', 450.00, 'Transferencia', 'Pagado', 6),
(7, '2024-01-11 15:00:00', 200.00, 'Efectivo', 'Pagado', 7),
(8, '2024-01-12 15:00:00', 300.00, 'Tarjeta', 'Pagado', 8),
(9, '2024-01-13 15:00:00', 450.00, 'Transferencia', 'Pagado', 9),
(10, '2024-01-14 15:00:00', 200.00, 'Efectivo', 'Pagado', 10),
(11, '2024-01-15 15:00:00', 300.00, 'Tarjeta', 'Pagado', 11),
(12, '2024-01-16 15:00:00', 450.00, 'Transferencia', 'Pagado', 12),
(13, '2024-01-17 15:00:00', 200.00, 'Efectivo', 'Pagado', 13),
(14, '2024-01-18 15:00:00', 300.00, 'Tarjeta', 'Pagado', 14),
(15, '2024-01-19 15:00:00', 450.00, 'Transferencia', 'Pagado', 15),
(16, '2024-01-20 15:00:00', 200.00, 'Efectivo', 'Pagado', 16),
(17, '2024-01-21 15:00:00', 300.00, 'Tarjeta', 'Pagado', 17),
(18, '2024-01-22 15:00:00', 450.00, 'Transferencia', 'Pagado', 18),
(19, '2024-01-23 15:00:00', 200.00, 'Efectivo', 'Pagado', 19),
(20, '2024-01-24 15:00:00', 300.00, 'Tarjeta', 'Pagado', 20),
(21, '2024-01-25 15:00:00', 450.00, 'Transferencia', 'Pagado', 21),
(22, '2024-01-26 15:00:00', 200.00, 'Efectivo', 'Pagado', 22),
(23, '2024-01-27 15:00:00', 300.00, 'Tarjeta', 'Pagado', 23),
(24, '2024-01-28 15:00:00', 450.00, 'Transferencia', 'Pagado', 24),
(25, '2024-01-29 15:00:00', 200.00, 'Efectivo', 'Pagado', 25),
(26, '2024-01-30 15:00:00', 300.00, 'Tarjeta', 'Pagado', 26),
(27, '2024-01-31 15:00:00', 450.00, 'Transferencia', 'Pagado', 27),
(28, '2024-02-01 15:00:00', 200.00, 'Efectivo', 'Pagado', 28),
(29, '2024-02-02 15:00:00', 300.00, 'Tarjeta', 'Pagado', 29),
(30, '2024-02-03 15:00:00', 450.00, 'Transferencia', 'Pagado', 30),
(31, '2024-02-04 15:00:00', 200.00, 'Efectivo', 'Pagado', 31),
(32, '2024-02-05 15:00:00', 300.00, 'Tarjeta', 'Pagado', 32),
(33, '2024-02-06 15:00:00', 450.00, 'Transferencia', 'Pagado', 33),
(34, '2024-02-07 15:00:00', 200.00, 'Efectivo', 'Pagado', 34),
(35, '2024-02-08 15:00:00', 300.00, 'Tarjeta', 'Pagado', 35),
(36, '2024-02-09 15:00:00', 450.00, 'Transferencia', 'Pagado', 36),
(37, '2024-02-10 15:00:00', 200.00, 'Efectivo', 'Pagado', 37),
(38, '2024-02-11 15:00:00', 300.00, 'Tarjeta', 'Pagado', 38),
(39, '2024-02-12 15:00:00', 450.00, 'Transferencia', 'Pagado', 39),
(40, '2024-02-13 15:00:00', 200.00, 'Efectivo', 'Pagado', 40),
(41, '2024-02-14 15:00:00', 300.00, 'Tarjeta', 'Pagado', 41),
(42, '2024-02-15 15:00:00', 450.00, 'Transferencia', 'Pagado', 42),
(43, '2024-02-16 15:00:00', 200.00, 'Efectivo', 'Pagado', 43),
(44, '2024-02-17 15:00:00', 300.00, 'Tarjeta', 'Pagado', 44),
(45, '2024-02-18 15:00:00', 450.00, 'Transferencia', 'Pagado', 45),
(46, '2024-02-19 15:00:00', 200.00, 'Efectivo', 'Pagado', 46),
(47, '2024-02-20 15:00:00', 300.00, 'Tarjeta', 'Pagado', 47),
(48, '2024-02-21 15:00:00', 450.00, 'Transferencia', 'Pagado', 48),
(49, '2024-02-22 15:00:00', 200.00, 'Efectivo', 'Pagado', 49),
(50, '2024-02-23 15:00:00', 300.00, 'Tarjeta', 'Pagado', 50),
(51, '2024-02-24 15:00:00', 450.00, 'Transferencia', 'Pagado', 51),
(52, '2024-02-25 15:00:00', 200.00, 'Efectivo', 'Pagado', 52),
(53, '2024-02-26 15:00:00', 300.00, 'Tarjeta', 'Pagado', 53),
(54, '2024-02-27 15:00:00', 450.00, 'Transferencia', 'Pagado', 54),
(55, '2024-02-28 15:00:00', 200.00, 'Efectivo', 'Pagado', 55),
(56, '2024-02-29 15:00:00', 300.00, 'Tarjeta', 'Pagado', 56),
(57, '2024-03-01 15:00:00', 450.00, 'Transferencia', 'Pagado', 57),
(58, '2024-03-02 15:00:00', 200.00, 'Efectivo', 'Pagado', 58),
(59, '2024-03-03 15:00:00', 300.00, 'Tarjeta', 'Pagado', 59),
(60, '2024-03-04 15:00:00', 450.00, 'Transferencia', 'Pagado', 60),
(61, '2024-03-05 15:00:00', 200.00, 'Efectivo', 'Pagado', 61),
(62, '2024-03-06 15:00:00', 300.00, 'Tarjeta', 'Pagado', 62),
(63, '2024-03-07 15:00:00', 450.00, 'Transferencia', 'Pagado', 63),
(64, '2024-03-08 15:00:00', 200.00, 'Efectivo', 'Pagado', 64),
(65, '2024-03-09 15:00:00', 300.00, 'Tarjeta', 'Pagado', 65),
(66, '2024-03-10 15:00:00', 450.00, 'Transferencia', 'Pagado', 66),
(67, '2024-03-11 15:00:00', 200.00, 'Efectivo', 'Pagado', 67),
(68, '2024-03-12 15:00:00', 300.00, 'Tarjeta', 'Pagado', 68),
(69, '2024-03-13 15:00:00', 450.00, 'Transferencia', 'Pagado', 69),
(70, '2024-03-14 15:00:00', 200.00, 'Efectivo', 'Pagado', 70),
(71, '2024-03-15 15:00:00', 300.00, 'Tarjeta', 'Pagado', 71),
(72, '2024-03-16 15:00:00', 450.00, 'Transferencia', 'Pagado', 72),
(73, '2024-03-17 15:00:00', 200.00, 'Efectivo', 'Pagado', 73),
(74, '2024-03-18 15:00:00', 300.00, 'Tarjeta', 'Pagado', 74),
(75, '2024-03-19 15:00:00', 450.00, 'Transferencia', 'Pagado', 75),
(76, '2024-03-20 15:00:00', 200.00, 'Efectivo', 'Pagado', 76),
(77, '2024-03-21 15:00:00', 300.00, 'Tarjeta', 'Pagado', 77),
(78, '2024-03-22 15:00:00', 450.00, 'Transferencia', 'Pagado', 78),
(79, '2024-03-23 15:00:00', 200.00, 'Efectivo', 'Pagado', 79),
(80, '2024-03-24 15:00:00', 300.00, 'Tarjeta', 'Pagado', 80),
(81, '2024-03-25 15:00:00', 450.00, 'Transferencia', 'Pagado', 81),
(82, '2024-03-26 15:00:00', 200.00, 'Efectivo', 'Pagado', 82),
(83, '2024-03-27 15:00:00', 300.00, 'Tarjeta', 'Pagado', 83),
(84, '2024-03-28 15:00:00', 450.00, 'Transferencia', 'Pagado', 84),
(85, '2024-03-29 15:00:00', 200.00, 'Efectivo', 'Pagado', 85),
(86, '2024-03-30 15:00:00', 300.00, 'Tarjeta', 'Pagado', 86),
(87, '2024-03-31 15:00:00', 450.00, 'Transferencia', 'Pagado', 87),
(88, '2024-04-01 15:00:00', 200.00, 'Efectivo', 'Pagado', 88),
(89, '2024-04-02 15:00:00', 300.00, 'Tarjeta', 'Pagado', 89),
(90, '2024-04-03 15:00:00', 450.00, 'Transferencia', 'Pagado', 90),
(91, '2024-04-04 15:00:00', 200.00, 'Efectivo', 'Pagado', 91),
(92, '2024-04-05 15:00:00', 300.00, 'Tarjeta', 'Pagado', 92),
(93, '2024-04-06 15:00:00', 450.00, 'Transferencia', 'Pagado', 93),
(94, '2024-04-07 15:00:00', 200.00, 'Efectivo', 'Pagado', 94),
(95, '2024-04-08 15:00:00', 300.00, 'Tarjeta', 'Pagado', 95),
(96, '2024-04-09 15:00:00', 450.00, 'Transferencia', 'Pagado', 96),
(97, '2024-04-10 15:00:00', 200.00, 'Efectivo', 'Pagado', 97),
(98, '2024-04-11 15:00:00', 300.00, 'Tarjeta', 'Pagado', 98),
(99, '2024-04-12 15:00:00', 450.00, 'Transferencia', 'Pagado', 99),
(100, '2024-04-13 15:00:00', 200.00, 'Efectivo', 'Pagado', 100),
(101, '2024-04-14 15:00:00', 300.00, 'Tarjeta', 'Pagado', 101),
(102, '2024-04-15 15:00:00', 450.00, 'Transferencia', 'Pagado', 102),
(103, '2024-04-16 15:00:00', 200.00, 'Efectivo', 'Pagado', 103),
(104, '2024-04-17 15:00:00', 300.00, 'Tarjeta', 'Pagado', 104),
(105, '2024-04-18 15:00:00', 450.00, 'Transferencia', 'Pagado', 105),
(106, '2024-04-19 15:00:00', 200.00, 'Efectivo', 'Pagado', 106),
(107, '2024-04-20 15:00:00', 300.00, 'Tarjeta', 'Pagado', 107),
(108, '2024-04-21 15:00:00', 450.00, 'Transferencia', 'Pagado', 108),
(109, '2024-04-22 15:00:00', 200.00, 'Efectivo', 'Pagado', 109),
(110, '2024-04-23 15:00:00', 300.00, 'Tarjeta', 'Pagado', 110),
(111, '2024-04-24 15:00:00', 450.00, 'Transferencia', 'Pagado', 111),
(112, '2024-04-25 15:00:00', 200.00, 'Efectivo', 'Pagado', 112),
(113, '2024-04-26 15:00:00', 300.00, 'Tarjeta', 'Pagado', 113),
(114, '2024-04-27 15:00:00', 450.00, 'Transferencia', 'Pagado', 114),
(115, '2024-04-28 15:00:00', 200.00, 'Efectivo', 'Pagado', 115),
(116, '2024-04-29 15:00:00', 300.00, 'Tarjeta', 'Pagado', 116),
(117, '2024-04-30 15:00:00', 450.00, 'Transferencia', 'Pagado', 117),
(118, '2024-05-01 15:00:00', 200.00, 'Efectivo', 'Pagado', 118),
(119, '2024-05-02 15:00:00', 300.00, 'Tarjeta', 'Pagado', 119),
(120, '2024-05-03 15:00:00', 450.00, 'Transferencia', 'Pagado', 120),
(121, '2024-05-04 15:00:00', 200.00, 'Efectivo', 'Pagado', 1),
(122, '2024-05-05 15:00:00', 300.00, 'Tarjeta', 'Pagado', 2),
(123, '2024-05-06 15:00:00', 450.00, 'Transferencia', 'Pagado', 3),
(124, '2024-05-07 15:00:00', 200.00, 'Efectivo', 'Pagado', 4),
(125, '2024-05-08 15:00:00', 300.00, 'Tarjeta', 'Pagado', 5),
(126, '2024-05-09 15:00:00', 450.00, 'Transferencia', 'Pagado', 6),
(127, '2024-05-10 15:00:00', 200.00, 'Efectivo', 'Pagado', 7),
(128, '2024-05-11 15:00:00', 300.00, 'Tarjeta', 'Pagado', 8),
(129, '2024-05-12 15:00:00', 450.00, 'Transferencia', 'Pagado', 9),
(130, '2024-05-13 15:00:00', 200.00, 'Efectivo', 'Pagado', 10),
(131, '2024-05-14 15:00:00', 300.00, 'Tarjeta', 'Pagado', 11),
(132, '2024-05-15 15:00:00', 450.00, 'Transferencia', 'Pagado', 12),
(133, '2024-05-16 15:00:00', 200.00, 'Efectivo', 'Pagado', 13),
(134, '2024-05-17 15:00:00', 300.00, 'Tarjeta', 'Pagado', 14),
(135, '2024-05-18 15:00:00', 450.00, 'Transferencia', 'Pagado', 15),
(136, '2024-05-19 15:00:00', 200.00, 'Efectivo', 'Pagado', 16),
(137, '2024-05-20 15:00:00', 300.00, 'Tarjeta', 'Pagado', 17),
(138, '2024-05-21 15:00:00', 450.00, 'Transferencia', 'Pagado', 18),
(139, '2024-05-22 15:00:00', 200.00, 'Efectivo', 'Pagado', 19),
(140, '2024-05-23 15:00:00', 300.00, 'Tarjeta', 'Pagado', 20),
(141, '2024-05-24 15:00:00', 450.00, 'Transferencia', 'Pagado', 21),
(142, '2024-05-25 15:00:00', 200.00, 'Efectivo', 'Pagado', 22),
(143, '2024-05-26 15:00:00', 300.00, 'Tarjeta', 'Pagado', 23),
(144, '2024-05-27 15:00:00', 450.00, 'Transferencia', 'Pagado', 24),
(145, '2024-05-28 15:00:00', 200.00, 'Efectivo', 'Pagado', 25),
(146, '2024-05-29 15:00:00', 300.00, 'Tarjeta', 'Pagado', 26),
(147, '2024-05-30 15:00:00', 450.00, 'Transferencia', 'Pagado', 27),
(148, '2024-05-31 15:00:00', 200.00, 'Efectivo', 'Pagado', 28),
(149, '2024-06-01 15:00:00', 300.00, 'Tarjeta', 'Pagado', 29),
(150, '2024-06-02 15:00:00', 450.00, 'Transferencia', 'Pagado', 30),
(256, '2026-05-20 13:10:45', 0.00, 'Tarjeta', 'Pagado', 120),
(257, '2026-05-20 14:27:39', 0.00, 'Tarjeta', 'Pagado', 119),
(258, '2026-05-21 18:02:07', 0.00, 'Tarjeta', 'Pagado', 119),
(259, '2026-05-21 19:29:14', 250.00, 'Transferencia', 'Pagado', 150),
(260, '2026-05-21 20:33:16', 250.00, 'Transferencia', 'Pagado', 157),
(261, '2026-05-21 20:34:05', 1000.00, 'Yape/Plin', 'Pagado', 157),
(262, '2026-05-21 21:42:25', 225.00, 'Tarjeta', 'Pagado', 149),
(263, '2026-05-21 21:45:36', 15.00, 'Tarjeta', 'Pagado', 149),
(264, '2026-05-23 19:13:28', 440.00, 'Tarjeta', 'Pagado', 158);

--
-- Disparadores `pago`
--
DELIMITER $$
CREATE TRIGGER `tr_pago_auditoria` AFTER INSERT ON `pago` FOR EACH ROW BEGIN

    -- Cada nuevo pago realizado se registra
    -- automáticamente en la tabla AuditoriaPago

    INSERT INTO AuditoriaPago(
        idPago,
        fecha,
        monto,
        metodo,
        accion
    )
    VALUES(
        NEW.id,
        NOW(),
        NEW.monto,
        NEW.metodo,
        'INSERT'
    );

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `persona`
--

CREATE TABLE `persona` (
  `docId` varchar(11) NOT NULL,
  `nombres` varchar(100) DEFAULT NULL,
  `apellidos` varchar(100) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `nacionalidad` varchar(20) DEFAULT NULL,
  `fechaNac` date DEFAULT NULL,
  `sexo` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `persona`
--

INSERT INTO `persona` (`docId`, `nombres`, `apellidos`, `correo`, `nacionalidad`, `fechaNac`, `sexo`) VALUES
('10000001', 'Juan', 'Perez', 'juan.perez1@mail.com', 'Peruana', '1990-01-15', 'M'),
('10000002', 'Maria', 'Gomez', 'maria.gomez2@mail.com', 'Peruana', '1988-03-22', 'F'),
('10000003', 'Carlos', 'Lopez', 'carlos.lopez3@mail.com', 'Peruana', '1995-07-10', 'M'),
('10000004', 'Ana', 'Torres', 'ana.torres4@mail.com', 'Peruana', '1992-11-05', 'F'),
('10000005', 'Luis', 'Ramirez', 'luis.ramirez5@mail.com', 'Peruana', '1987-06-18', 'M'),
('10000006', 'Sofia', 'Castro', 'sofia.castro6@mail.com', 'Peruana', '1993-09-25', 'F'),
('10000007', 'Jorge', 'Vargas', 'jorge.vargas7@mail.com', 'Peruana', '1985-12-30', 'M'),
('10000008', 'Lucia', 'Rojas', 'lucia.rojas8@mail.com', 'Peruana', '1996-04-12', 'F'),
('10000009', 'Diego', 'Mendoza', 'diego.mendoza9@mail.com', 'Peruana', '1991-08-08', 'M'),
('10000010', 'Elena', 'Silva', 'elena.silva10@mail.com', 'Peruana', '1989-02-14', 'F'),
('10000011', 'Pedro', 'Flores', 'pedro.flores11@mail.com', 'Peruana', '1994-05-19', 'M'),
('10000012', 'Valeria', 'Reyes', 'valeria.reyes12@mail.com', 'Peruana', '1997-07-23', 'F'),
('10000013', 'Miguel', 'Ortega', 'miguel.ortega13@mail.com', 'Peruana', '1986-10-01', 'M'),
('10000014', 'Camila', 'Nunez', 'camila.nunez14@mail.com', 'Peruana', '1998-12-11', 'F'),
('10000015', 'Ricardo', 'Delgado', 'ricardo.delgado15@mail.com', 'Peruana', '1990-03-03', 'M'),
('10000016', 'Daniela', 'Cruz', 'daniela.cruz16@mail.com', 'Peruana', '1993-06-06', 'F'),
('10000017', 'Fernando', 'Paredes', 'fernando.paredes17@mail.com', 'Peruana', '1984-09-09', 'M'),
('10000018', 'Gabriela', 'Huaman', 'gabriela.huaman18@mail.com', 'Peruana', '1995-01-27', 'F'),
('10000019', 'Andres', 'Salazar', 'andres.salazar19@mail.com', 'Peruana', '1992-04-04', 'M'),
('10000020', 'Patricia', 'Campos', 'patricia.campos20@mail.com', 'Peruana', '1988-08-21', 'F'),
('10000021', 'Raul', 'Sanchez', 'raul.sanchez21@mail.com', 'Peruana', '1991-11-13', 'M'),
('10000022', 'Claudia', 'Espinoza', 'claudia.espinoza22@mail.com', 'Peruana', '1996-02-28', 'F'),
('10000023', 'Oscar', 'Rios', 'oscar.rios23@mail.com', 'Peruana', '1987-07-17', 'M'),
('10000024', 'Rosa', 'Quispe', 'rosa.quispe24@mail.com', 'Peruana', '1994-10-05', 'F'),
('10000025', 'Victor', 'Alvarez', 'victor.alvarez25@mail.com', 'Peruana', '1985-01-09', 'M'),
('10000026', 'Paola', 'Chavez', 'paola.chavez26@mail.com', 'Peruana', '1993-03-30', 'F'),
('10000027', 'Hector', 'Benitez', 'hector.benitez27@mail.com', 'Peruana', '1990-05-05', 'M'),
('10000028', 'Karla', 'Medina', 'karla.medina28@mail.com', 'Peruana', '1997-09-19', 'F'),
('10000029', 'Alberto', 'Navarro', 'alberto.navarro29@mail.com', 'Peruana', '1986-12-12', 'M'),
('10000030', 'Ruth', 'Vega', 'ruth.vega30@mail.com', 'Peruana', '1995-08-08', 'F'),
('10000031', 'Julio', 'Cordero', 'julio.cordero31@mail.com', 'Peruana', '1989-04-14', 'M'),
('10000032', 'Andrea', 'Morales', 'andrea.morales32@mail.com', 'Peruana', '1998-06-06', 'F'),
('10000033', 'Cesar', 'Guerrero', 'cesar.guerrero33@mail.com', 'Peruana', '1991-02-02', 'M'),
('10000034', 'Natalia', 'Peña', 'natalia.pena34@mail.com', 'Peruana', '1993-07-07', 'F'),
('10000035', 'Eduardo', 'Fuentes', 'eduardo.fuentes35@mail.com', 'Peruana', '1987-10-10', 'M'),
('10000036', 'Veronica', 'Soto', 'veronica.soto36@mail.com', 'Peruana', '1996-11-11', 'F'),
('10000037', 'Martin', 'Ramos', 'martin.ramos37@mail.com', 'Peruana', '1992-12-12', 'M'),
('10000038', 'Silvia', 'Aguilar', 'silvia.aguilar38@mail.com', 'Peruana', '1988-05-05', 'F'),
('10000039', 'Gustavo', 'Mora', 'gustavo.mora39@mail.com', 'Peruana', '1994-03-03', 'M'),
('10000040', 'Lidia', 'Carrasco', 'lidia.carrasco40@mail.com', 'Peruana', '1997-01-01', 'F'),
('10000041', 'Mario', 'Ponce', 'mario.ponce41@mail.com', 'Peruana', '1985-08-08', 'M'),
('10000042', 'Rocio', 'Tapia', 'rocio.tapia42@mail.com', 'Peruana', '1993-09-09', 'F'),
('10000043', 'Bruno', 'Luna', 'bruno.luna43@mail.com', 'Peruana', '1991-06-06', 'M'),
('10000044', 'Yolanda', 'Zapata', 'yolanda.zapata44@mail.com', 'Peruana', '1989-02-02', 'F'),
('10000045', 'Kevin', 'Bravo', 'kevin.bravo45@mail.com', 'Peruana', '1998-04-04', 'M'),
('10000046', 'Diana', 'Mejia', 'diana.mejia46@mail.com', 'Peruana', '1995-05-05', 'F'),
('10000047', 'Samuel', 'Arias', 'samuel.arias47@mail.com', 'Peruana', '1986-03-03', 'M'),
('10000048', 'Lorena', 'Cabrera', 'lorena.cabrera48@mail.com', 'Peruana', '1992-07-07', 'F'),
('10000049', 'Alex', 'Valdez', 'alex.valdez49@mail.com', 'Peruana', '1990-10-10', 'M'),
('10000050', 'Monica', 'Ibarra', 'monica.ibarra50@mail.com', 'Peruana', '1994-11-11', 'F'),
('10000051', 'Diego', 'Montoya', 'diego.montoya51@mail.com', 'Peruana', '1991-01-01', 'M'),
('10000052', 'Paula', 'Escobar', 'paula.escobar52@mail.com', 'Peruana', '1996-02-02', 'F'),
('10000053', 'Adrian', 'Cornejo', 'adrian.cornejo53@mail.com', 'Peruana', '1988-03-03', 'M'),
('10000054', 'Tatiana', 'Figueroa', 'tatiana.figueroa54@mail.com', 'Peruana', '1997-04-04', 'F'),
('10000055', 'Ivan', 'Zegarra', 'ivan.zegarra55@mail.com', 'Peruana', '1987-05-05', 'M'),
('10000056', 'Noelia', 'Palacios', 'noelia.palacios56@mail.com', 'Peruana', '1993-06-06', 'F'),
('10000057', 'Renato', 'Valle', 'renato.valle57@mail.com', 'Peruana', '1992-07-07', 'M'),
('10000058', 'Maribel', 'Solano', 'maribel.solano58@mail.com', 'Peruana', '1995-08-08', 'F'),
('10000059', 'Cristian', 'Acosta', 'cristian.acosta59@mail.com', 'Peruana', '1989-09-09', 'M'),
('10000060', 'Angela', 'Peralta', 'angela.peralta60@mail.com', 'Peruana', '1998-10-10', 'F'),
('10000061', 'Pablo', 'Maldonado', 'pablo.maldonado61@mail.com', 'Peruana', '1985-11-11', 'M'),
('10000062', 'Jessica', 'Cordova', 'jessica.cordova62@mail.com', 'Peruana', '1994-12-12', 'F'),
('10000063', 'Luis', 'Villar', 'luis.villar63@mail.com', 'Peruana', '1991-01-21', 'M'),
('10000064', 'Carla', 'Ojeda', 'carla.ojeda64@mail.com', 'Peruana', '1996-02-18', 'F'),
('10000065', 'Marco', 'Pizarro', 'marco.pizarro65@mail.com', 'Peruana', '1987-03-15', 'M'),
('10000066', 'Cecilia', 'Huerta', 'cecilia.huerta66@mail.com', 'Peruana', '1993-04-12', 'F'),
('10000067', 'Jhon', 'Arce', 'jhon.arce67@mail.com', 'Peruana', '1990-05-09', 'M'),
('10000068', 'Milagros', 'Galvez', 'milagros.galvez68@mail.com', 'Peruana', '1997-06-06', 'F'),
('10000069', 'Frank', 'Carrillo', 'frank.carrillo69@mail.com', 'Peruana', '1986-07-07', 'M'),
('10000070', 'Sandra', 'Renteria', 'sandra.renteria70@mail.com', 'Peruana', '1995-08-08', 'F'),
('10000071', 'Alonso', 'Tello', 'alonso.tello71@mail.com', 'Peruana', '1992-09-09', 'M'),
('10000072', 'Daniela', 'Barrios', 'daniela.barrios72@mail.com', 'Peruana', '1998-10-10', 'F'),
('10000073', 'Roberto', 'Mamani', 'roberto.mamani73@mail.com', 'Peruana', '1988-11-11', 'M'),
('10000074', 'Fiorella', 'Cueva', 'fiorella.cueva74@mail.com', 'Peruana', '1996-12-12', 'F'),
('10000075', 'Sebastian', 'Quinteros', 'sebastian.quinteros75@mail.com', 'Peruana', '1991-01-01', 'M'),
('10000076', 'Lucero', 'Espitia', 'lucero.espitia76@mail.com', 'Peruana', '1997-02-02', 'F'),
('10000077', 'Mauricio', 'Zamora', 'mauricio.zamora77@mail.com', 'Peruana', '1985-03-03', 'M'),
('10000078', 'Estefania', 'Roldan', 'estefania.roldan78@mail.com', 'Peruana', '1994-04-04', 'F'),
('10000079', 'Victor', 'Salinas', 'victor.salinas79@mail.com', 'Peruana', '1990-05-05', 'M'),
('10000080', 'Daniel', 'Arroyo', 'daniel.arroyo80@mail.com', 'Peruana', '1993-06-06', 'M'),
('12345678', 'juan', 'perez', 'lui483@gmail.com', 'peruano', '2000-02-15', 'M'),
('70000001', 'Juan', 'Pérez', 'juan.perez@mail.com', 'Peruana', '1990-01-15', 'M'),
('70000002', 'María', 'Gómez', 'maria.gomez@mail.com', 'Peruana', '1988-03-22', 'F'),
('70000003', 'Carlos', 'López', 'carlos.lopez@mail.com', 'Peruana', '1995-07-10', 'M'),
('70000004', 'Ana', 'Torres', 'ana.torres@mail.com', 'Peruana', '1992-11-05', 'F'),
('70000005', 'Luis', 'Ramírez', 'luis.ramirez@mail.com', 'Peruana', '1987-06-18', 'M'),
('70000006', 'Sofía', 'Castro', 'sofia.castro@mail.com', 'Peruana', '1993-09-25', 'F'),
('70000007', 'Jorge', 'Vargas', 'jorge.vargas@mail.com', 'Peruana', '1985-12-30', 'M'),
('70000008', 'Lucía', 'Rojas', 'lucia.rojas@mail.com', 'Peruana', '1996-04-12', 'F'),
('70000009', 'Diego', 'Mendoza', 'diego.mendoza@mail.com', 'Peruana', '1991-08-08', 'M'),
('70000010', 'Elena', 'Silva', 'elena.silva@mail.com', 'Peruana', '1989-02-14', 'F'),
('70000011', 'Pedro', 'Flores', 'pedro.flores@mail.com', 'Peruana', '1994-05-19', 'M'),
('70000012', 'Valeria', 'Reyes', 'valeria.reyes@mail.com', 'Peruana', '1997-07-23', 'F'),
('70000013', 'Miguel', 'Ortega', 'miguel.ortega@mail.com', 'Peruana', '1986-10-01', 'M'),
('70000014', 'Camila', 'Núñez', 'camila.nunez@mail.com', 'Peruana', '1998-12-11', 'F'),
('70000015', 'Ricardo', 'Delgado', 'ricardo.delgado@mail.com', 'Peruana', '1990-03-03', 'M'),
('70000016', 'Daniela', 'Cruz', 'daniela.cruz@mail.com', 'Peruana', '1993-06-06', 'F'),
('70000017', 'Fernando', 'Paredes', 'fernando.paredes@mail.com', 'Peruana', '1984-09-09', 'M'),
('70000018', 'Gabriela', 'Huamán', 'gabriela.huaman@mail.com', 'Peruana', '1995-01-27', 'F'),
('70000019', 'Andrés', 'Salazar', 'andres.salazar@mail.com', 'Peruana', '1992-04-04', 'M'),
('70000020', 'Patricia', 'Campos', 'patricia.campos@mail.com', 'Peruana', '1988-08-21', 'F'),
('70000021', 'Raúl', 'Sánchez', 'raul.sanchez@mail.com', 'Peruana', '1991-11-13', 'M'),
('70000022', 'Claudia', 'Espinoza', 'claudia.espinoza@mail.com', 'Peruana', '1996-02-28', 'F'),
('70000023', 'Óscar', 'Ríos', 'oscar.rios@mail.com', 'Peruana', '1987-07-17', 'M'),
('70000024', 'Rosa', 'Quispe', 'rosa.quispe@mail.com', 'Peruana', '1994-10-05', 'F'),
('70000025', 'Víctor', 'Álvarez', 'victor.alvarez@mail.com', 'Peruana', '1985-01-09', 'M'),
('70000026', 'Paola', 'Chávez', 'paola.chavez@mail.com', 'Peruana', '1993-03-30', 'F'),
('70000027', 'Héctor', 'Benítez', 'hector.benitez@mail.com', 'Peruana', '1990-05-05', 'M'),
('70000028', 'Karla', 'Medina', 'karla.medina@mail.com', 'Peruana', '1997-09-19', 'F'),
('70000029', 'Alberto', 'Navarro', 'alberto.navarro@mail.com', 'Peruana', '1986-12-12', 'M'),
('70000030', 'Ruth', 'Vega', 'ruth.vega@mail.com', 'Peruana', '1995-08-08', 'F'),
('70000031', 'Julio', 'Cordero', 'julio.cordero@mail.com', 'Peruana', '1989-04-14', 'M'),
('70000032', 'Andrea', 'Morales', 'andrea.morales@mail.com', 'Peruana', '1998-06-06', 'F'),
('70000033', 'César', 'Guerrero', 'cesar.guerrero@mail.com', 'Peruana', '1991-02-02', 'M'),
('70000034', 'Natalia', 'Peña', 'natalia.pena@mail.com', 'Peruana', '1993-07-07', 'F'),
('70000035', 'Eduardo', 'Fuentes', 'eduardo.fuentes@mail.com', 'Peruana', '1987-10-10', 'M'),
('70000036', 'Verónica', 'Soto', 'veronica.soto@mail.com', 'Peruana', '1996-11-11', 'F'),
('70000037', 'Martín', 'Ramos', 'martin.ramos@mail.com', 'Peruana', '1992-12-12', 'M'),
('70000038', 'Silvia', 'Aguilar', 'silvia.aguilar@mail.com', 'Peruana', '1988-05-05', 'F'),
('70000039', 'Gustavo', 'Mora', 'gustavo.mora@mail.com', 'Peruana', '1994-03-03', 'M'),
('70000040', 'Lidia', 'Carrasco', 'lidia.carrasco@mail.com', 'Peruana', '1997-01-01', 'F'),
('70000041', 'Mario', 'Ponce', 'mario.ponce@mail.com', 'Peruana', '1985-08-08', 'M'),
('70000042', 'Rocío', 'Tapia', 'rocio.tapia@mail.com', 'Peruana', '1993-09-09', 'F'),
('70000043', 'Bruno', 'Luna', 'bruno.luna@mail.com', 'Peruana', '1991-06-06', 'M'),
('70000044', 'Yolanda', 'Zapata', 'yolanda.zapata@mail.com', 'Peruana', '1989-02-02', 'F'),
('70000045', 'Kevin', 'Bravo', 'kevin.bravo@mail.com', 'Peruana', '1998-04-04', 'M'),
('70000046', 'Diana', 'Mejía', 'diana.mejia@mail.com', 'Peruana', '1995-05-05', 'F'),
('70000047', 'Samuel', 'Arias', 'samuel.arias@mail.com', 'Peruana', '1986-03-03', 'M'),
('70000048', 'Lorena', 'Cabrera', 'lorena.cabrera@mail.com', 'Peruana', '1992-07-07', 'F'),
('70000049', 'Alex', 'Valdez', 'alex.valdez@mail.com', 'Peruana', '1990-10-10', 'M'),
('70000050', 'Mónica', 'Ibarra', 'monica.ibarra@mail.com', 'Peruana', '1994-11-11', 'F'),
('70000051', 'Diego', 'Montoya', 'diego.montoya@mail.com', 'Peruana', '1991-01-01', 'M'),
('70000052', 'Paula', 'Escobar', 'paula.escobar@mail.com', 'Peruana', '1996-02-02', 'F'),
('70000053', 'Adrián', 'Cornejo', 'adrian.cornejo@mail.com', 'Peruana', '1988-03-03', 'M'),
('70000054', 'Tatiana', 'Figueroa', 'tatiana.figueroa@mail.com', 'Peruana', '1997-04-04', 'F'),
('70000055', 'Iván', 'Zegarra', 'ivan.zegarra@mail.com', 'Peruana', '1987-05-05', 'M'),
('70000056', 'Noelia', 'Palacios', 'noelia.palacios@mail.com', 'Peruana', '1993-06-06', 'F'),
('70000057', 'Renato', 'Valle', 'renato.valle@mail.com', 'Peruana', '1992-07-07', 'M'),
('70000058', 'Maribel', 'Solano', 'maribel.solano@mail.com', 'Peruana', '1995-08-08', 'F'),
('70000059', 'Cristian', 'Acosta', 'cristian.acosta@mail.com', 'Peruana', '1989-09-09', 'M'),
('70000060', 'Ángela', 'Peralta', 'angela.peralta@mail.com', 'Peruana', '1998-10-10', 'F'),
('70000061', 'Pablo', 'Maldonado', 'pablo.maldonado@mail.com', 'Peruana', '1985-11-11', 'M'),
('70000062', 'Jessica', 'Córdova', 'jessica.cordova@mail.com', 'Peruana', '1994-12-12', 'F'),
('70000063', 'Luis', 'Villar', 'luis.villar@mail.com', 'Peruana', '1991-01-21', 'M'),
('70000064', 'Carla', 'Ojeda', 'carla.ojeda@mail.com', 'Peruana', '1996-02-18', 'F'),
('70000065', 'Marco', 'Pizarro', 'marco.pizarro@mail.com', 'Peruana', '1987-03-15', 'M'),
('70000066', 'Cecilia', 'Huerta', 'cecilia.huerta@mail.com', 'Peruana', '1993-04-12', 'F'),
('70000067', 'Jhon', 'Arce', 'jhon.arce@mail.com', 'Peruana', '1990-05-09', 'M'),
('70000068', 'Milagros', 'Gálvez', 'milagros.galvez@mail.com', 'Peruana', '1997-06-06', 'F'),
('70000069', 'Frank', 'Carrillo', 'frank.carrillo@mail.com', 'Peruana', '1986-07-07', 'M'),
('70000070', 'Sandra', 'Rentería', 'sandra.renteria@mail.com', 'Peruana', '1995-08-08', 'F'),
('70000071', 'Alonso', 'Tello', 'alonso.tello@mail.com', 'Peruana', '1992-09-09', 'M'),
('70000072', 'Daniela', 'Barrios', 'daniela.barrios@mail.com', 'Peruana', '1998-10-10', 'F'),
('70000073', 'Roberto', 'Mamani', 'roberto.mamani@mail.com', 'Peruana', '1988-11-11', 'M'),
('70000074', 'Fiorella', 'Cueva', 'fiorella.cueva@mail.com', 'Peruana', '1996-12-12', 'F'),
('70000075', 'Sebastián', 'Quinteros', 'sebastian.quinteros@mail.com', 'Peruana', '1991-01-01', 'M'),
('70000076', 'Lucero', 'Espitia', 'lucero.espitia@mail.com', 'Peruana', '1997-02-02', 'F'),
('70000077', 'Mauricio', 'Zamora', 'mauricio.zamora@mail.com', 'Peruana', '1985-03-03', 'M'),
('70000078', 'Estefanía', 'Roldán', 'estefania.roldan@mail.com', 'Peruana', '1994-04-04', 'F'),
('70000079', 'Víctor', 'Salinas', 'victor.salinas@mail.com', 'Peruana', '1990-05-05', 'M'),
('70000080', 'Daniel', 'Arroyo', 'daniel.arroyo@mail.com', 'Peruana', '1993-06-06', 'M'),
('71594542', 'luis anthony', 'baca ccallo', 'luisbaca483@gmail.com', 'peruano', '2004-06-19', 'M'),
('87654321', 'pedro', 'campos', 'pp@gmail.com', 'peruano', '0000-00-00', 'm'),
('87654321.', 'J', 'S', 'S', 'Ñ', '2026-05-23', 'F');

--
-- Disparadores `persona`
--
DELIMITER $$
CREATE TRIGGER `tr_persona_log_update` AFTER UPDATE ON `persona` FOR EACH ROW BEGIN

    -- Cada modificación en datos del cliente
    -- se almacena en AuditoriaPersona

    INSERT INTO AuditoriaPersona(
        docId,
        fecha,
        accion
    )
    VALUES(
        NEW.docId,
        NOW(),
        'UPDATE'
    );

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `recepcionista`
--

CREATE TABLE `recepcionista` (
  `idEmpleado` int(11) NOT NULL,
  `docId` varchar(11) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `turno` varchar(10) DEFAULT NULL,
  `estado` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `recepcionista`
--

INSERT INTO `recepcionista` (`idEmpleado`, `docId`, `correo`, `turno`, `estado`) VALUES
(1, '70000001', 'recep1@hotel.com', 'Mañana', 'Activo'),
(2, '70000002', 'recep2@hotel.com', 'Tarde', 'Activo'),
(3, '70000003', 'recep3@hotel.com', 'Noche', 'Activo'),
(4, '70000004', 'recep4@hotel.com', 'Mañana', 'Activo'),
(5, '70000005', 'recep5@hotel.com', 'Tarde', 'Activo'),
(6, '70000006', 'recep6@hotel.com', 'Noche', 'Activo'),
(7, '70000007', 'recep7@hotel.com', 'Mañana', 'Activo'),
(8, '71594542', 'luisbaca483@gmail.com', 'Mañana', 'ACTIVO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reserva`
--

CREATE TABLE `reserva` (
  `id` int(11) NOT NULL,
  `fecha` datetime DEFAULT NULL,
  `fechaEntrada` datetime DEFAULT NULL,
  `fechaSalida` datetime DEFAULT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `idEmpleado` int(11) DEFAULT NULL,
  `docIdCliente` varchar(11) DEFAULT NULL,
  `idHabitacion` char(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `reserva`
--

INSERT INTO `reserva` (`id`, `fecha`, `fechaEntrada`, `fechaSalida`, `estado`, `precio`, `idEmpleado`, `docIdCliente`, `idHabitacion`) VALUES
(1, '2024-01-01 10:00:00', '2024-01-05 14:00:00', '2024-01-08 12:00:00', 'Activa', 200.00, 1, '70000001', 'H101'),
(2, '2024-01-02 10:00:00', '2024-01-06 14:00:00', '2024-01-10 12:00:00', 'Confirmada', 300.00, 2, '70000002', 'H102'),
(3, '2024-01-03 10:00:00', '2024-01-07 14:00:00', '2024-01-12 12:00:00', 'Confirmada', 450.00, 3, '70000003', 'H103'),
(4, '2024-01-04 10:00:00', '2024-01-08 14:00:00', '2024-01-11 12:00:00', 'Completada', 200.00, 4, '70000004', 'H104'),
(5, '2024-01-05 10:00:00', '2024-01-09 14:00:00', '2024-01-13 12:00:00', 'Confirmada', 300.00, 5, '70000005', 'H201'),
(6, '2024-01-06 10:00:00', '2024-01-10 14:00:00', '2024-01-15 12:00:00', 'Confirmada', 450.00, 6, '70000006', 'H202'),
(7, '2024-01-07 10:00:00', '2024-01-11 14:00:00', '2024-01-14 12:00:00', 'Completada', 200.00, 7, '70000007', 'H203'),
(8, '2024-01-08 10:00:00', '2024-01-12 14:00:00', '2024-01-16 12:00:00', 'Confirmada', 300.00, 1, '70000008', 'H204'),
(9, '2024-01-09 10:00:00', '2024-01-13 14:00:00', '2024-01-18 12:00:00', 'Confirmada', 450.00, 2, '70000009', 'H301'),
(10, '2024-01-10 10:00:00', '2024-01-14 14:00:00', '2024-01-17 12:00:00', 'Completada', 200.00, 3, '70000010', 'H302'),
(11, '2024-01-11 10:00:00', '2024-01-15 14:00:00', '2024-01-19 12:00:00', 'Confirmada', 300.00, 4, '70000011', 'H303'),
(12, '2024-01-12 10:00:00', '2024-01-16 14:00:00', '2024-01-21 12:00:00', 'Confirmada', 450.00, 5, '70000012', 'H304'),
(13, '2024-01-13 10:00:00', '2024-01-17 14:00:00', '2024-01-20 12:00:00', 'Completada', 200.00, 6, '70000013', 'H101'),
(14, '2024-01-14 10:00:00', '2024-01-18 14:00:00', '2024-01-22 12:00:00', 'Confirmada', 300.00, 7, '70000014', 'H102'),
(15, '2024-01-15 10:00:00', '2024-01-19 14:00:00', '2024-01-24 12:00:00', 'Confirmada', 450.00, 1, '70000015', 'H103'),
(16, '2024-01-16 10:00:00', '2024-01-20 14:00:00', '2024-01-23 12:00:00', 'Completada', 200.00, 2, '70000016', 'H104'),
(17, '2024-01-17 10:00:00', '2024-01-21 14:00:00', '2024-01-25 12:00:00', 'Confirmada', 300.00, 3, '70000017', 'H201'),
(18, '2024-01-18 10:00:00', '2024-01-22 14:00:00', '2024-01-27 12:00:00', 'Confirmada', 450.00, 4, '70000018', 'H202'),
(19, '2024-01-19 10:00:00', '2024-01-23 14:00:00', '2024-01-26 12:00:00', 'Completada', 200.00, 5, '70000019', 'H203'),
(20, '2024-01-20 10:00:00', '2024-01-24 14:00:00', '2024-01-28 12:00:00', 'Confirmada', 300.00, 6, '70000020', 'H204'),
(21, '2024-01-21 10:00:00', '2024-01-25 14:00:00', '2024-01-30 12:00:00', 'Confirmada', 450.00, 7, '70000021', 'H301'),
(22, '2024-01-22 10:00:00', '2024-01-26 14:00:00', '2024-01-29 12:00:00', 'Completada', 200.00, 1, '70000022', 'H302'),
(23, '2024-01-23 10:00:00', '2024-01-27 14:00:00', '2024-01-31 12:00:00', 'Confirmada', 300.00, 2, '70000023', 'H303'),
(24, '2024-01-24 10:00:00', '2024-01-28 14:00:00', '2024-02-02 12:00:00', 'Confirmada', 450.00, 3, '70000024', 'H304'),
(25, '2024-01-25 10:00:00', '2024-01-29 14:00:00', '2024-02-01 12:00:00', 'Completada', 200.00, 4, '70000025', 'H101'),
(26, '2024-01-26 10:00:00', '2024-01-30 14:00:00', '2024-02-03 12:00:00', 'Confirmada', 300.00, 5, '70000026', 'H102'),
(27, '2024-01-27 10:00:00', '2024-01-31 14:00:00', '2024-02-05 12:00:00', 'Confirmada', 450.00, 6, '70000027', 'H103'),
(28, '2024-01-28 10:00:00', '2024-02-01 14:00:00', '2024-02-04 12:00:00', 'Completada', 200.00, 7, '70000028', 'H104'),
(29, '2024-01-29 10:00:00', '2024-02-02 14:00:00', '2024-02-06 12:00:00', 'Confirmada', 300.00, 1, '70000029', 'H201'),
(30, '2024-01-30 10:00:00', '2024-02-03 14:00:00', '2024-02-08 12:00:00', 'Confirmada', 450.00, 2, '70000030', 'H202'),
(31, '2024-01-31 10:00:00', '2024-02-04 14:00:00', '2024-02-07 12:00:00', 'Completada', 200.00, 3, '70000031', 'H203'),
(32, '2024-02-01 10:00:00', '2024-02-05 14:00:00', '2024-02-09 12:00:00', 'Confirmada', 300.00, 4, '70000032', 'H204'),
(33, '2024-02-02 10:00:00', '2024-02-06 14:00:00', '2024-02-11 12:00:00', 'Confirmada', 450.00, 5, '70000033', 'H301'),
(34, '2024-02-03 10:00:00', '2024-02-07 14:00:00', '2024-02-10 12:00:00', 'Completada', 200.00, 6, '70000034', 'H302'),
(35, '2024-02-04 10:00:00', '2024-02-08 14:00:00', '2024-02-12 12:00:00', 'Confirmada', 300.00, 7, '70000035', 'H303'),
(36, '2024-02-05 10:00:00', '2024-02-09 14:00:00', '2024-02-14 12:00:00', 'Confirmada', 450.00, 1, '70000036', 'H304'),
(37, '2024-02-06 10:00:00', '2024-02-10 14:00:00', '2024-02-13 12:00:00', 'Completada', 200.00, 2, '70000037', 'H101'),
(38, '2024-02-07 10:00:00', '2024-02-11 14:00:00', '2024-02-15 12:00:00', 'Confirmada', 300.00, 3, '70000038', 'H102'),
(39, '2024-02-08 10:00:00', '2024-02-12 14:00:00', '2024-02-17 12:00:00', 'Confirmada', 450.00, 4, '70000039', 'H103'),
(40, '2024-02-09 10:00:00', '2024-02-13 14:00:00', '2024-02-16 12:00:00', 'Completada', 200.00, 5, '70000040', 'H104'),
(41, '2024-02-10 10:00:00', '2024-02-14 14:00:00', '2024-02-18 12:00:00', 'Confirmada', 300.00, 6, '70000041', 'H201'),
(42, '2024-02-11 10:00:00', '2024-02-15 14:00:00', '2024-02-20 12:00:00', 'Confirmada', 450.00, 7, '70000042', 'H202'),
(43, '2024-02-12 10:00:00', '2024-02-16 14:00:00', '2024-02-19 12:00:00', 'Completada', 200.00, 1, '70000043', 'H203'),
(44, '2024-02-13 10:00:00', '2024-02-17 14:00:00', '2024-02-21 12:00:00', 'Confirmada', 300.00, 2, '70000044', 'H204'),
(45, '2024-02-14 10:00:00', '2024-02-18 14:00:00', '2024-02-23 12:00:00', 'Confirmada', 450.00, 3, '70000045', 'H301'),
(46, '2024-02-15 10:00:00', '2024-02-19 14:00:00', '2024-02-22 12:00:00', 'Completada', 200.00, 4, '70000046', 'H302'),
(47, '2024-02-16 10:00:00', '2024-02-20 14:00:00', '2024-02-24 12:00:00', 'Confirmada', 300.00, 5, '70000047', 'H303'),
(48, '2024-02-17 10:00:00', '2024-02-21 14:00:00', '2024-02-26 12:00:00', 'Confirmada', 450.00, 6, '70000048', 'H304'),
(49, '2024-02-18 10:00:00', '2024-02-22 14:00:00', '2024-02-25 12:00:00', 'Completada', 200.00, 7, '70000049', 'H101'),
(50, '2024-02-19 10:00:00', '2024-02-23 14:00:00', '2024-02-27 12:00:00', 'Confirmada', 300.00, 1, '70000050', 'H102'),
(51, '2024-02-20 10:00:00', '2024-02-24 14:00:00', '2024-02-29 12:00:00', 'Confirmada', 450.00, 2, '70000051', 'H103'),
(52, '2024-02-21 10:00:00', '2024-02-25 14:00:00', '2024-02-28 12:00:00', 'Completada', 200.00, 3, '70000052', 'H104'),
(53, '2024-02-22 10:00:00', '2024-02-26 14:00:00', '2024-03-01 12:00:00', 'Confirmada', 300.00, 4, '70000053', 'H201'),
(54, '2024-02-23 10:00:00', '2024-02-27 14:00:00', '2024-03-03 12:00:00', 'Confirmada', 450.00, 5, '70000054', 'H202'),
(55, '2024-02-24 10:00:00', '2024-02-28 14:00:00', '2024-03-02 12:00:00', 'Completada', 200.00, 6, '70000055', 'H203'),
(56, '2024-02-25 10:00:00', '2024-02-29 14:00:00', '2024-03-04 12:00:00', 'Confirmada', 300.00, 7, '70000056', 'H204'),
(57, '2024-02-26 10:00:00', '2024-03-01 14:00:00', '2024-03-06 12:00:00', 'Confirmada', 450.00, 1, '70000057', 'H301'),
(58, '2024-02-27 10:00:00', '2024-03-02 14:00:00', '2024-03-05 12:00:00', 'Completada', 200.00, 2, '70000058', 'H302'),
(59, '2024-02-28 10:00:00', '2024-03-03 14:00:00', '2024-03-07 12:00:00', 'Confirmada', 300.00, 3, '70000059', 'H303'),
(60, '2024-02-29 10:00:00', '2024-03-04 14:00:00', '2024-03-09 12:00:00', 'Confirmada', 450.00, 4, '70000060', 'H304'),
(61, '2024-03-01 10:00:00', '2024-03-05 14:00:00', '2024-03-08 12:00:00', 'Completada', 200.00, 5, '70000061', 'H101'),
(62, '2024-03-02 10:00:00', '2024-03-06 14:00:00', '2024-03-10 12:00:00', 'Confirmada', 300.00, 6, '70000062', 'H102'),
(63, '2024-03-03 10:00:00', '2024-03-07 14:00:00', '2024-03-12 12:00:00', 'Confirmada', 450.00, 7, '70000063', 'H103'),
(64, '2024-03-04 10:00:00', '2024-03-08 14:00:00', '2024-03-11 12:00:00', 'Completada', 200.00, 1, '70000064', 'H104'),
(65, '2024-03-05 10:00:00', '2024-03-09 14:00:00', '2024-03-13 12:00:00', 'Confirmada', 300.00, 2, '70000065', 'H201'),
(66, '2024-03-06 10:00:00', '2024-03-10 14:00:00', '2024-03-15 12:00:00', 'Confirmada', 450.00, 3, '70000066', 'H202'),
(67, '2024-03-07 10:00:00', '2024-03-11 14:00:00', '2024-03-14 12:00:00', 'Completada', 200.00, 4, '70000067', 'H203'),
(68, '2024-03-08 10:00:00', '2024-03-12 14:00:00', '2024-03-16 12:00:00', 'Confirmada', 300.00, 5, '70000068', 'H204'),
(69, '2024-03-09 10:00:00', '2024-03-13 14:00:00', '2024-03-18 12:00:00', 'Confirmada', 450.00, 6, '70000069', 'H301'),
(70, '2024-03-10 10:00:00', '2024-03-14 14:00:00', '2024-03-17 12:00:00', 'Completada', 200.00, 7, '70000070', 'H302'),
(71, '2024-03-11 10:00:00', '2024-03-15 14:00:00', '2024-03-19 12:00:00', 'Confirmada', 300.00, 1, '70000071', 'H303'),
(72, '2024-03-12 10:00:00', '2024-03-16 14:00:00', '2024-03-21 12:00:00', 'Confirmada', 450.00, 2, '70000072', 'H304'),
(73, '2024-03-13 10:00:00', '2024-03-17 14:00:00', '2024-03-20 12:00:00', 'Completada', 200.00, 3, '70000073', 'H101'),
(74, '2024-03-14 10:00:00', '2024-03-18 14:00:00', '2024-03-22 12:00:00', 'Confirmada', 300.00, 4, '70000074', 'H102'),
(75, '2024-03-15 10:00:00', '2024-03-19 14:00:00', '2024-03-24 12:00:00', 'Confirmada', 450.00, 5, '70000075', 'H103'),
(76, '2024-03-16 10:00:00', '2024-03-20 14:00:00', '2024-03-23 12:00:00', 'Completada', 200.00, 6, '70000076', 'H104'),
(77, '2024-03-17 10:00:00', '2024-03-21 14:00:00', '2024-03-25 12:00:00', 'Confirmada', 300.00, 7, '70000077', 'H201'),
(78, '2024-03-18 10:00:00', '2024-03-22 14:00:00', '2024-03-27 12:00:00', 'Confirmada', 450.00, 1, '70000078', 'H202'),
(79, '2024-03-19 10:00:00', '2024-03-23 14:00:00', '2024-03-26 12:00:00', 'Completada', 200.00, 2, '70000079', 'H203'),
(80, '2024-03-20 10:00:00', '2024-03-24 14:00:00', '2024-03-28 12:00:00', 'Confirmada', 300.00, 3, '70000080', 'H204'),
(81, '2024-03-21 10:00:00', '2024-03-25 14:00:00', '2024-03-30 12:00:00', 'Confirmada', 450.00, 4, '70000001', 'H301'),
(82, '2024-03-22 10:00:00', '2024-03-26 14:00:00', '2024-03-29 12:00:00', 'Completada', 200.00, 5, '70000002', 'H302'),
(83, '2024-03-23 10:00:00', '2024-03-27 14:00:00', '2024-03-31 12:00:00', 'Confirmada', 300.00, 6, '70000003', 'H303'),
(84, '2024-03-24 10:00:00', '2024-03-28 14:00:00', '2024-04-02 12:00:00', 'Confirmada', 450.00, 7, '70000004', 'H304'),
(85, '2024-03-25 10:00:00', '2024-03-29 14:00:00', '2024-04-01 12:00:00', 'Completada', 200.00, 1, '70000005', 'H101'),
(86, '2024-03-26 10:00:00', '2024-03-30 14:00:00', '2024-04-03 12:00:00', 'Confirmada', 300.00, 2, '70000006', 'H102'),
(87, '2024-03-27 10:00:00', '2024-03-31 14:00:00', '2024-04-05 12:00:00', 'Confirmada', 450.00, 3, '70000007', 'H103'),
(88, '2024-03-28 10:00:00', '2024-04-01 14:00:00', '2024-04-04 12:00:00', 'Completada', 200.00, 4, '70000008', 'H104'),
(89, '2024-03-29 10:00:00', '2024-04-02 14:00:00', '2024-04-06 12:00:00', 'Confirmada', 300.00, 5, '70000009', 'H201'),
(90, '2024-03-30 10:00:00', '2024-04-03 14:00:00', '2024-04-08 12:00:00', 'Confirmada', 450.00, 6, '70000010', 'H202'),
(91, '2024-03-31 10:00:00', '2024-04-04 14:00:00', '2024-04-07 12:00:00', 'Completada', 200.00, 7, '70000011', 'H203'),
(92, '2024-04-01 10:00:00', '2024-04-05 14:00:00', '2024-04-09 12:00:00', 'Confirmada', 300.00, 1, '70000012', 'H204'),
(93, '2024-04-02 10:00:00', '2024-04-06 14:00:00', '2024-04-11 12:00:00', 'Confirmada', 450.00, 2, '70000013', 'H301'),
(94, '2024-04-03 10:00:00', '2024-04-07 14:00:00', '2024-04-10 12:00:00', 'Completada', 200.00, 3, '70000014', 'H302'),
(95, '2024-04-04 10:00:00', '2024-04-08 14:00:00', '2024-04-12 12:00:00', 'Confirmada', 300.00, 4, '70000015', 'H303'),
(96, '2024-04-05 10:00:00', '2024-04-09 14:00:00', '2024-04-14 12:00:00', 'Confirmada', 450.00, 5, '70000016', 'H304'),
(97, '2024-04-06 10:00:00', '2024-04-10 14:00:00', '2024-04-13 12:00:00', 'Completada', 200.00, 6, '70000017', 'H101'),
(98, '2024-04-07 10:00:00', '2024-04-11 14:00:00', '2024-04-15 12:00:00', 'Confirmada', 300.00, 7, '70000018', 'H102'),
(99, '2024-04-08 10:00:00', '2024-04-12 14:00:00', '2024-04-17 12:00:00', 'Confirmada', 450.00, 1, '70000019', 'H103'),
(100, '2024-04-09 10:00:00', '2024-04-13 14:00:00', '2024-04-16 12:00:00', 'Completada', 200.00, 2, '70000020', 'H104'),
(101, '2024-04-10 10:00:00', '2024-04-14 14:00:00', '2024-04-18 12:00:00', 'Confirmada', 300.00, 3, '70000021', 'H201'),
(102, '2024-04-11 10:00:00', '2024-04-15 14:00:00', '2024-04-20 12:00:00', 'Confirmada', 450.00, 4, '70000022', 'H202'),
(103, '2024-04-12 10:00:00', '2024-04-16 14:00:00', '2024-04-19 12:00:00', 'Completada', 200.00, 5, '70000023', 'H203'),
(104, '2024-04-13 10:00:00', '2024-04-17 14:00:00', '2024-04-21 12:00:00', 'Confirmada', 300.00, 6, '70000024', 'H204'),
(105, '2024-04-14 10:00:00', '2024-04-18 14:00:00', '2024-04-23 12:00:00', 'Confirmada', 450.00, 7, '70000025', 'H301'),
(106, '2024-04-15 10:00:00', '2024-04-19 14:00:00', '2024-04-22 12:00:00', 'Completada', 200.00, 1, '70000026', 'H302'),
(107, '2024-04-16 10:00:00', '2024-04-20 14:00:00', '2024-04-24 12:00:00', 'Confirmada', 300.00, 2, '70000027', 'H303'),
(108, '2024-04-17 10:00:00', '2024-04-21 14:00:00', '2024-04-26 12:00:00', 'Confirmada', 450.00, 3, '70000028', 'H304'),
(109, '2024-04-18 10:00:00', '2024-04-22 14:00:00', '2024-04-25 12:00:00', 'Completada', 200.00, 4, '70000029', 'H101'),
(110, '2024-04-19 10:00:00', '2024-04-23 14:00:00', '2024-04-27 12:00:00', 'Confirmada', 300.00, 5, '70000030', 'H102'),
(111, '2024-04-20 10:00:00', '2024-04-24 14:00:00', '2024-04-29 12:00:00', 'Confirmada', 450.00, 6, '70000031', 'H103'),
(112, '2024-04-21 10:00:00', '2024-04-25 14:00:00', '2024-04-28 12:00:00', 'Completada', 200.00, 7, '70000032', 'H104'),
(113, '2024-04-22 10:00:00', '2024-04-26 14:00:00', '2024-04-30 12:00:00', 'Confirmada', 300.00, 1, '70000033', 'H201'),
(114, '2024-04-23 10:00:00', '2024-04-27 14:00:00', '2024-05-02 12:00:00', 'Confirmada', 450.00, 2, '70000034', 'H202'),
(115, '2024-04-24 10:00:00', '2024-04-28 14:00:00', '2024-05-01 12:00:00', 'Completada', 200.00, 3, '70000035', 'H203'),
(116, '2024-04-25 10:00:00', '2024-04-29 14:00:00', '2024-05-03 12:00:00', 'Confirmada', 300.00, 4, '70000036', 'H204'),
(117, '2024-04-26 10:00:00', '2024-04-30 14:00:00', '2024-05-05 12:00:00', 'Confirmada', 450.00, 5, '70000037', 'H301'),
(118, '2024-04-27 10:00:00', '2024-05-01 14:00:00', '2024-05-04 12:00:00', 'Completada', 200.00, 6, '70000038', 'H302'),
(119, '2024-04-28 10:00:00', '2024-05-02 14:00:00', '2024-05-06 12:00:00', 'Confirmada', 300.00, 7, '70000039', 'H303'),
(120, '2024-04-29 10:00:00', '2024-05-03 14:00:00', '2024-05-08 12:00:00', 'Confirmada', 450.00, 1, '70000040', 'H304'),
(149, '2026-05-21 18:21:18', '2026-05-22 00:00:00', '2026-05-24 00:00:00', 'CONFIRMADA', 25.00, 1, '71594542', 'H101'),
(150, '2026-05-21 18:39:27', '2026-05-22 00:00:00', '2026-05-23 00:00:00', 'FINALIZADA', 250.00, 1, '87654321', 'H314'),
(157, '2026-05-21 20:32:39', '2026-05-23 00:00:00', '2026-05-24 00:00:00', 'CONFIRMADA', 500.00, 1, '71594542', 'H500'),
(158, '2026-05-23 19:11:30', '2026-05-24 00:00:00', '2026-05-25 00:00:00', 'CHECKIN', 300.00, 1, '87654321.', 'h500');

--
-- Disparadores `reserva`
--
DELIMITER $$
CREATE TRIGGER `tr_reserva_checkout_limpieza` AFTER UPDATE ON `reserva` FOR EACH ROW BEGIN

    -- Si la reserva cambia a estado FINALIZADA,
    -- la habitación debe pasar al área de limpieza

    IF NEW.estado = 'FINALIZADA' THEN

        UPDATE Habitacion
        SET estado = 'LIMPIEZA'
        WHERE id = NEW.idHabitacion;

    END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_reserva_insert_estado_habitacion` AFTER INSERT ON `reserva` FOR EACH ROW BEGIN

    -- Cuando se registra una nueva reserva,
    -- la habitación asignada pasa automáticamente a estado RESERVADA

    UPDATE Habitacion
    SET estado = 'RESERVADA'
    WHERE id = NEW.idHabitacion;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reservahuesped`
--

CREATE TABLE `reservahuesped` (
  `idReserva` int(11) NOT NULL,
  `docId` varchar(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `reservahuesped`
--

INSERT INTO `reservahuesped` (`idReserva`, `docId`) VALUES
(1, '70000001'),
(1, '70000002'),
(1, '70000003'),
(1, '70000004'),
(1, '70000005'),
(1, '70000006'),
(1, '70000007'),
(1, '70000008'),
(1, '70000009'),
(1, '70000010'),
(1, '70000011'),
(1, '70000012'),
(1, '70000013'),
(1, '70000014'),
(2, '70000015'),
(2, '70000016'),
(2, '70000017'),
(2, '70000018'),
(2, '70000019'),
(2, '70000020'),
(2, '70000021'),
(2, '70000022'),
(2, '70000023'),
(2, '70000024'),
(2, '70000025'),
(2, '70000026'),
(2, '70000027'),
(2, '70000028'),
(3, '70000029'),
(3, '70000030'),
(3, '70000031'),
(3, '70000032'),
(3, '70000033'),
(3, '70000034'),
(3, '70000035'),
(3, '70000036'),
(3, '70000037'),
(3, '70000038'),
(3, '70000039'),
(3, '70000040'),
(3, '70000041'),
(3, '70000042'),
(4, '70000043'),
(4, '70000044'),
(4, '70000045'),
(4, '70000046'),
(4, '70000047'),
(4, '70000048'),
(4, '70000049'),
(4, '70000050'),
(4, '70000051'),
(4, '70000052'),
(4, '70000053'),
(4, '70000054'),
(4, '70000055'),
(4, '70000056'),
(5, '70000057'),
(5, '70000058'),
(5, '70000059'),
(5, '70000060'),
(5, '70000061'),
(5, '70000062'),
(5, '70000063'),
(5, '70000064'),
(5, '70000065'),
(5, '70000066'),
(5, '70000067'),
(5, '70000068'),
(5, '70000069'),
(5, '70000070'),
(6, '70000001'),
(6, '70000002'),
(6, '70000003'),
(6, '70000004'),
(6, '70000071'),
(6, '70000072'),
(6, '70000073'),
(6, '70000074'),
(6, '70000075'),
(6, '70000076'),
(6, '70000077'),
(6, '70000078'),
(6, '70000079'),
(6, '70000080'),
(7, '70000005'),
(7, '70000006'),
(7, '70000007'),
(7, '70000008'),
(7, '70000009'),
(7, '70000010'),
(7, '70000011'),
(7, '70000012'),
(7, '70000013'),
(7, '70000014'),
(7, '70000015'),
(7, '70000016'),
(7, '70000017'),
(7, '70000018'),
(8, '70000019'),
(8, '70000020'),
(8, '70000021'),
(8, '70000022'),
(8, '70000023'),
(8, '70000024'),
(8, '70000025'),
(8, '70000026'),
(8, '70000027'),
(8, '70000028'),
(8, '70000029'),
(8, '70000030'),
(8, '70000031'),
(8, '70000032'),
(9, '70000033'),
(9, '70000034'),
(9, '70000035'),
(9, '70000036'),
(9, '70000037'),
(9, '70000038'),
(9, '70000039'),
(9, '70000040'),
(9, '70000041'),
(9, '70000042'),
(9, '70000043'),
(9, '70000044'),
(9, '70000045'),
(9, '70000046'),
(10, '70000047'),
(10, '70000048'),
(10, '70000049'),
(10, '70000050'),
(10, '70000051'),
(10, '70000052'),
(10, '70000053'),
(10, '70000054'),
(10, '70000055'),
(10, '70000056'),
(10, '70000057'),
(10, '70000058'),
(10, '70000059'),
(10, '70000060');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `servicio`
--

CREATE TABLE `servicio` (
  `id` int(11) NOT NULL,
  `tipo` varchar(10) DEFAULT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `estado` varchar(10) DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `servicio`
--

INSERT INTO `servicio` (`id`, `tipo`, `descripcion`, `estado`, `precio`) VALUES
(1, 'Extra', 'Desayuno buffet', 'Activo', 25.00),
(2, 'Extra', 'Servicio a la habitación', 'Activo', 30.00),
(3, 'Spa', 'Masaje relajante', 'Activo', 80.00),
(4, 'Transporte', 'Traslado al aeropuerto', 'Activo', 60.00),
(5, 'Limpieza', 'Lavandería', 'Activo', 15.00),
(6, 'Extra', 'Cena gourmet', 'Activo', 70.00),
(7, 'Spa', 'Sauna', 'Activo', 40.00),
(8, 'Transporte', 'Taxi privado', 'Activo', 35.00),
(9, 'bufet', 'bufet', 'ACTIVO', 50.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursal`
--

CREATE TABLE `sucursal` (
  `id` int(11) NOT NULL,
  `direccion` varchar(30) DEFAULT NULL,
  `nombre` varchar(30) DEFAULT NULL,
  `telefono` varchar(12) DEFAULT NULL,
  `ubigeo` char(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sucursal`
--

INSERT INTO `sucursal` (`id`, `direccion`, `nombre`, `telefono`, `ubigeo`) VALUES
(1, 'Av. Javier Prado 1234', 'Sucursal San Isidro', '014567890', '150131'),
(2, 'Av. Larco 456', 'Sucursal Miraflores', '014567891', '150122'),
(3, 'Av. Ejército 789', 'Sucursal Arequipa', '054123456', '040101');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_caja_diaria`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_caja_diaria` (
`fecha` date
,`metodo` varchar(20)
,`operaciones` bigint(21)
,`total` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_clientes_frecuentes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_clientes_frecuentes` (
`docId` varchar(11)
,`cliente` varchar(201)
,`total_reservas` bigint(21)
,`total_gastado` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_dashboard_general`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_dashboard_general` (
`total_reservas` bigint(21)
,`total_clientes` bigint(21)
,`habitaciones_ocupadas` bigint(21)
,`ingresos_totales` decimal(32,2)
,`ventas_servicios` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_estado_cuenta_reserva`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_estado_cuenta_reserva` (
`reserva` int(11)
,`hospedaje` decimal(10,2)
,`servicios` decimal(32,2)
,`total_consumido` decimal(33,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_habitaciones_disponibles`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_habitaciones_disponibles` (
`id` char(4)
,`tipo` varchar(15)
,`piso` int(11)
,`sucursal` varchar(30)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_reservas_activas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_reservas_activas` (
`id` int(11)
,`cliente` varchar(201)
,`habitacion` char(4)
,`fechaEntrada` datetime
,`fechaSalida` datetime
,`estado` varchar(20)
,`precio` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_caja_diaria`
--
DROP TABLE IF EXISTS `vw_caja_diaria`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_caja_diaria`  AS SELECT cast(`pago`.`fecha` as date) AS `fecha`, `pago`.`metodo` AS `metodo`, count(0) AS `operaciones`, sum(`pago`.`monto`) AS `total` FROM `pago` GROUP BY cast(`pago`.`fecha` as date), `pago`.`metodo` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_clientes_frecuentes`
--
DROP TABLE IF EXISTS `vw_clientes_frecuentes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_clientes_frecuentes`  AS SELECT `p`.`docId` AS `docId`, concat(`p`.`nombres`,' ',`p`.`apellidos`) AS `cliente`, count(`r`.`id`) AS `total_reservas`, sum(`r`.`precio`) AS `total_gastado` FROM (`persona` `p` join `reserva` `r` on(`p`.`docId` = `r`.`docIdCliente`)) GROUP BY `p`.`docId`, concat(`p`.`nombres`,' ',`p`.`apellidos`) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_dashboard_general`
--
DROP TABLE IF EXISTS `vw_dashboard_general`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_dashboard_general`  AS SELECT (select count(0) from `reserva`) AS `total_reservas`, (select count(0) from `persona`) AS `total_clientes`, (select count(0) from `habitacion` where `habitacion`.`estado` = 'OCUPADA') AS `habitaciones_ocupadas`, (select ifnull(sum(`pago`.`monto`),0) from `pago`) AS `ingresos_totales`, (select ifnull(sum(`detalleservicio`.`subTotal`),0) from `detalleservicio`) AS `ventas_servicios` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_estado_cuenta_reserva`
--
DROP TABLE IF EXISTS `vw_estado_cuenta_reserva`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_estado_cuenta_reserva`  AS SELECT `r`.`id` AS `reserva`, `r`.`precio` AS `hospedaje`, ifnull(sum(`ds`.`subTotal`),0) AS `servicios`, `r`.`precio`+ ifnull(sum(`ds`.`subTotal`),0) AS `total_consumido` FROM (`reserva` `r` left join `detalleservicio` `ds` on(`r`.`id` = `ds`.`idReserva`)) GROUP BY `r`.`id`, `r`.`precio` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_habitaciones_disponibles`
--
DROP TABLE IF EXISTS `vw_habitaciones_disponibles`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_habitaciones_disponibles`  AS SELECT `h`.`id` AS `id`, `h`.`tipo` AS `tipo`, `h`.`piso` AS `piso`, `s`.`nombre` AS `sucursal` FROM (`habitacion` `h` join `sucursal` `s` on(`h`.`idSucursal` = `s`.`id`)) WHERE `h`.`estado` = 'DISPONIBLE' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_reservas_activas`
--
DROP TABLE IF EXISTS `vw_reservas_activas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_reservas_activas`  AS SELECT `r`.`id` AS `id`, concat(`p`.`nombres`,' ',`p`.`apellidos`) AS `cliente`, `h`.`id` AS `habitacion`, `r`.`fechaEntrada` AS `fechaEntrada`, `r`.`fechaSalida` AS `fechaSalida`, `r`.`estado` AS `estado`, `r`.`precio` AS `precio` FROM ((`reserva` `r` join `persona` `p` on(`r`.`docIdCliente` = `p`.`docId`)) join `habitacion` `h` on(`r`.`idHabitacion` = `h`.`id`)) WHERE `r`.`estado` in ('CONFIRMADA','CHECKIN') ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditoriapago`
--
ALTER TABLE `auditoriapago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `auditoriapersona`
--
ALTER TABLE `auditoriapersona`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `detalleservicio`
--
ALTER TABLE `detalleservicio`
  ADD PRIMARY KEY (`idReserva`,`idServicio`),
  ADD KEY `idServicio` (`idServicio`);

--
-- Indices de la tabla `habitacion`
--
ALTER TABLE `habitacion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idSucursal` (`idSucursal`);

--
-- Indices de la tabla `pago`
--
ALTER TABLE `pago`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idReserva` (`idReserva`);

--
-- Indices de la tabla `persona`
--
ALTER TABLE `persona`
  ADD PRIMARY KEY (`docId`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `recepcionista`
--
ALTER TABLE `recepcionista`
  ADD PRIMARY KEY (`idEmpleado`),
  ADD UNIQUE KEY `docId` (`docId`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idEmpleado` (`idEmpleado`),
  ADD KEY `docIdCliente` (`docIdCliente`),
  ADD KEY `idHabitacion` (`idHabitacion`);

--
-- Indices de la tabla `reservahuesped`
--
ALTER TABLE `reservahuesped`
  ADD PRIMARY KEY (`idReserva`,`docId`),
  ADD KEY `docId` (`docId`);

--
-- Indices de la tabla `servicio`
--
ALTER TABLE `servicio`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `sucursal`
--
ALTER TABLE `sucursal`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoriapago`
--
ALTER TABLE `auditoriapago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `auditoriapersona`
--
ALTER TABLE `auditoriapersona`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `pago`
--
ALTER TABLE `pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=265;

--
-- AUTO_INCREMENT de la tabla `recepcionista`
--
ALTER TABLE `recepcionista`
  MODIFY `idEmpleado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `reserva`
--
ALTER TABLE `reserva`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=159;

--
-- AUTO_INCREMENT de la tabla `servicio`
--
ALTER TABLE `servicio`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `sucursal`
--
ALTER TABLE `sucursal`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalleservicio`
--
ALTER TABLE `detalleservicio`
  ADD CONSTRAINT `detalleservicio_ibfk_1` FOREIGN KEY (`idReserva`) REFERENCES `reserva` (`id`),
  ADD CONSTRAINT `detalleservicio_ibfk_2` FOREIGN KEY (`idServicio`) REFERENCES `servicio` (`id`);

--
-- Filtros para la tabla `habitacion`
--
ALTER TABLE `habitacion`
  ADD CONSTRAINT `habitacion_ibfk_1` FOREIGN KEY (`idSucursal`) REFERENCES `sucursal` (`id`);

--
-- Filtros para la tabla `pago`
--
ALTER TABLE `pago`
  ADD CONSTRAINT `pago_ibfk_1` FOREIGN KEY (`idReserva`) REFERENCES `reserva` (`id`);

--
-- Filtros para la tabla `recepcionista`
--
ALTER TABLE `recepcionista`
  ADD CONSTRAINT `recepcionista_ibfk_1` FOREIGN KEY (`docId`) REFERENCES `persona` (`docId`);

--
-- Filtros para la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD CONSTRAINT `reserva_ibfk_1` FOREIGN KEY (`idEmpleado`) REFERENCES `recepcionista` (`idEmpleado`),
  ADD CONSTRAINT `reserva_ibfk_2` FOREIGN KEY (`docIdCliente`) REFERENCES `persona` (`docId`),
  ADD CONSTRAINT `reserva_ibfk_3` FOREIGN KEY (`idHabitacion`) REFERENCES `habitacion` (`id`);

--
-- Filtros para la tabla `reservahuesped`
--
ALTER TABLE `reservahuesped`
  ADD CONSTRAINT `reservahuesped_ibfk_1` FOREIGN KEY (`idReserva`) REFERENCES `reserva` (`id`),
  ADD CONSTRAINT `reservahuesped_ibfk_2` FOREIGN KEY (`docId`) REFERENCES `persona` (`docId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
