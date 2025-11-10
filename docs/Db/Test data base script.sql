-- 🧪 SCRIPT DE PRUEBAS FUNCIONALES - SISTEMA DE BOLETOS (MySQL)
-- Autor: Joseph (Programador)
-- Fecha: Noviembre 2025
-- Versión: 1.0
-- --------------------------------------------------------------
-- Este script valida la integridad, triggers, vistas y procedimientos
-- de la base de datos del sistema de boletos.
-- Ejecutar después de haber creado las tablas y relaciones.
-- --------------------------------------------------------------
USE cine;

START TRANSACTION;

-- --------------------------------------------------------------
-- 1️⃣ CARGA DE DATOS INICIALES
-- --------------------------------------------------------------
select * from Rol;
select * from Usuario;
select * from boleto;
select * from cartelera;
select * from asiento;
select * from log_transacciones;
select * from tandas;
select * from pelicula;
select * from sala;



INSERT INTO Rol (id, nombre) VALUES (1, 'Cliente'), (2, 'Administrador');
select * from Rol;

INSERT INTO Usuario (id, nombre, apellido, rol, correo, contraseña)
VALUES (1, 'Juan', 'Pérez', 1, 'juan@example.com', 12345),
       (2, 'Ana', 'Gómez', 2, 'ana@example.com', 67890);
select * from Usuario;

INSERT INTO Sala (id_sala, tipo, nombre) VALUES (1, '3D', 'Sala 1');
select * from sala;

INSERT INTO Pelicula (id_pelicula, nombre, descripcion, fecha_estreno, salida_cartelera, duracion, categoria, clasificacion, portada)
VALUES (2, 'Matrix', 'Ciencia ficción', '2025-10-01', '2025-12-01', 2.5, 'Acción', 'PG-13', 'matrix.jpg');
select * from pelicula;

INSERT INTO Tandas (id_tanda, id_pelicula, id_sala, estado, hora_inicio, hora_fin, fecha)
VALUES (2, 1, 1, 'En Curso', '18:00:00', '20:30:00', '2025-11-05');
select * from tandas;

INSERT INTO Asiento (id_asiento, id_sala, estatus, nombre)
VALUES (1, 1, 'disponible', 'A1'),
       (2, 1, 'disponible', 'A2');
select * from asiento;

COMMIT;

-- --------------------------------------------------------------
-- 2️⃣ PRUEBAS DE INTEGRIDAD REFERENCIAL
-- --------------------------------------------------------------

-- Caso inválido: insertar boleto con usuario inexistente
-- ❌ Esperado: Error de restricción de clave foránea
INSERT INTO Boleto (id_boleto, tanda_id, dueño_id, fecha_compra, asiento_id, hash)
VALUES (999, 1, 9999, NOW(), 1, 'hash_prueba');
select * from boleto;
-- Si da error de FK, la integridad referencial funciona correctamente.

-- --------------------------------------------------------------
-- 3️⃣ PRUEBA DE PROCEDIMIENTO ALMACENADO
-- --------------------------------------------------------------

-- ✅ Caso correcto: asiento disponible
CALL sp_generar_boleto(1, 1, 1);

-- ❌ Caso de error: asiento ya ocupado
CALL sp_generar_boleto(1, 1, 1);

-- Resultado esperado: mensaje de error 'El asiento no está disponible'

-- --------------------------------------------------------------
-- 4️⃣ PRUEBA DE TRIGGERS
-- --------------------------------------------------------------
SET @boleto_id = NULL;
SET @msg = NULL;

CALL sp_generar_boleto(
  1,              -- p_usuario_id
  1,              -- p_tanda_id
  1,              -- p_asiento_id
  'Tarjeta',      -- p_metodo_pago
  10.50,          -- p_monto
  @boleto_id,
  @msg
);

SELECT @boleto_id AS id_generado, @msg AS mensaje;

-- Verificar si el asiento cambió a 'ocupado'
SELECT id_asiento, estatus FROM Asiento;

SELECT * FROM Boleto;
SELECT * FROM tandas;
SELECT * FROM Asiento;


-- Verificar registro en log (si existe tabla LogBoletos)
SELECT * FROM log_transacciones;

-- --------------------------------------------------------------
-- 5️⃣ PRUEBA DE VISTAS
-- --------------------------------------------------------------

-- Debe mostrar información detallada del boleto comprado
SELECT * FROM v_boletos_detalle;

-- Debe listar solo asientos disponibles
SELECT * FROM v_asientos_disponibles;

-- --------------------------------------------------------------
-- 6️⃣ VALIDACIONES FINALES
-- --------------------------------------------------------------

-- Comprobar que el boleto insertado existe
SELECT * FROM Boleto;

-- Validar relación completa
SELECT b.id_boleto, u.nombre AS usuario, p.nombre AS pelicula
FROM Boleto b
JOIN Usuario u ON b.dueño = u.id
JOIN Tandas t ON b.tanda = t.id_tanda
JOIN Pelicula p ON t.id_pelicula = p.id_pelicula;

-- --------------------------------------------------------------
-- ✅ RESULTADO ESPERADO
-- --------------------------------------------------------------
-- 1. Error al insertar FK inválida (OK)
-- 2. Procedimiento sp_generar_boleto crea boleto válido (OK)
-- 3. Asiento cambia de 'disponible' → 'ocupado' (OK)
-- 4. Segundo intento lanza error (OK)
-- 5. Vistas muestran información coherente (OK)
-- --------------------------------------------------------------

COMMIT;
