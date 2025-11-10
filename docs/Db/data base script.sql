-- DB Release 1.0: Sistema de Boletos
-- Contenido:
-- 1) Esquema (tablas) con PK/FK, índices
-- 2) Vistas útiles
-- 3) Triggers de auditoría y status
-- 4) Stored Procedure para generar un boleto (atomic)
-- 5) Datos de ejemplo para pruebas
-- 6) Usuarios/roles y GRANTS recomendados
-- 7) Notas de backup/restore y mantenimiento
-- ==================================================================

-- RECOMENDACIONES PREVIAS:
-- * Ejecutar en una base limpia (CREATE DATABASE cine; USE cine;)
-- * Ajustar tipos y tamaños a tu negocio (ej. duracion FLOAT -> INT minutos si prefieres)
-- * Revisar permisos y credenciales antes de producción

CREATE DATABASE cine; USE cine;

-- --------------------
-- 1) TABLAS
-- --------------------
CREATE TABLE IF NOT EXISTS Rol (
  id BIGINT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Usuario (
  id BIGINT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100),
  rol_id BIGINT NOT NULL,
  correo VARCHAR(255) NOT NULL UNIQUE,
  contraseña VARCHAR(255) NOT NULL,
  creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (rol_id) REFERENCES Rol(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Sala (
  id_sala BIGINT NOT NULL AUTO_INCREMENT,
  tipo VARCHAR(100),
  nombre VARCHAR(50) NOT NULL,
  capacidad INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id_sala)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Pelicula (
  id_pelicula BIGINT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(150) NOT NULL,
  descripcion varchar(255),
  fecha_estreno DATE,
  salida_cartelera DATE,
  duracion INT, -- minutos
  categoria VARCHAR(100),
  clasificacion VARCHAR(50),
  portada VARCHAR(255),
  PRIMARY KEY (id_pelicula)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Cartelera (
  id_cartelera BIGINT NOT NULL AUTO_INCREMENT,
  estado ENUM('Activa','Inactiva','Proxima') DEFAULT 'Proxima',
  fecha_inicio DATE,
  fecha_fin DATE,
  id_pelicula BIGINT NOT NULL,
  PRIMARY KEY (id_cartelera),
  FOREIGN KEY (id_pelicula) REFERENCES Pelicula(id_pelicula)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Tandas (
  id_tanda BIGINT NOT NULL AUTO_INCREMENT,
  id_pelicula BIGINT NOT NULL,
  id_sala BIGINT NOT NULL,
  estado ENUM('Programada','En Curso','Finalizada','Cancelada') DEFAULT 'Programada',
  hora_inicio TIME NOT NULL,
  hora_fin TIME,
  fecha DATE NOT NULL,
  precio DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  capacidad INT, -- redundante: copia de sala.capacidad si quieres optimizar
  PRIMARY KEY (id_tanda),
  FOREIGN KEY (id_pelicula) REFERENCES Pelicula(id_pelicula),
  FOREIGN KEY (id_sala) REFERENCES Sala(id_sala)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Asiento (
  id_asiento BIGINT NOT NULL AUTO_INCREMENT,
  id_sala BIGINT NOT NULL,
  nombre VARCHAR(20) NOT NULL, -- Ej: A12
  estatus ENUM('Libre','Reservado','Ocupado','Inhabilitado') DEFAULT 'Libre',
  PRIMARY KEY (id_asiento),
  FOREIGN KEY (id_sala) REFERENCES Sala(id_sala)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Boleto (
  id_boleto BIGINT NOT NULL AUTO_INCREMENT,
  tanda_id BIGINT NOT NULL,
  dueño_id BIGINT NOT NULL,
  fecha_compra DATETIME DEFAULT CURRENT_TIMESTAMP,
  asiento_id BIGINT NOT NULL,
  hash VARCHAR(255) NOT NULL UNIQUE,
  metodo_pago VARCHAR(50),
  monto DECIMAL(10,2) DEFAULT 0.00,
  PRIMARY KEY (id_boleto),
  FOREIGN KEY (tanda_id) REFERENCES Tandas(id_tanda),
  FOREIGN KEY (dueño_id) REFERENCES Usuario(id),
  FOREIGN KEY (asiento_id) REFERENCES Asiento(id_asiento)
) ENGINE=InnoDB;

-- Auditoría / Log de transacciones
CREATE TABLE IF NOT EXISTS Log_Transacciones (
  id_log BIGINT NOT NULL AUTO_INCREMENT,
  tabla_afectada VARCHAR(64),
  tipo_operacion VARCHAR(10),
  usuario_db VARCHAR(100),
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  detalle TEXT,
  PRIMARY KEY (id_log)
) ENGINE=InnoDB;

-- --------------------
-- 2) ÍNDICES (mejoras de performance)
-- --------------------
CREATE INDEX idx_tandas_pelicula ON Tandas(id_pelicula);
CREATE INDEX idx_tandas_sala ON Tandas(id_sala);
CREATE INDEX idx_boleto_dueño ON Boleto(dueño_id);
CREATE INDEX idx_boleto_tanda ON Boleto(tanda_id);
CREATE INDEX idx_asiento_sala ON Asiento(id_sala);
CREATE INDEX idx_usuario_correo ON Usuario(correo);

-- --------------------
-- 3) VISTAS (views) útiles para el backend
-- --------------------
DROP VIEW IF EXISTS v_boletos_detalle;
CREATE VIEW v_boletos_detalle AS
SELECT 
  b.id_boleto,
  b.hash,
  b.fecha_compra,
  b.monto,
  u.id AS usuario_id,
  CONCAT(u.nombre,' ',u.apellido) AS usuario_nombre,
  p.id_pelicula,
  p.nombre AS pelicula_nombre,
  t.id_tanda,
  t.fecha AS tanda_fecha,
  t.hora_inicio,
  t.hora_fin,
  s.id_sala,
  s.nombre AS sala_nombre,
  a.id_asiento,
  a.nombre AS asiento_nombre
FROM Boleto b
JOIN Usuario u ON b.dueño_id = u.id
JOIN Tandas t ON b.tanda_id = t.id_tanda
JOIN Pelicula p ON t.id_pelicula = p.id_pelicula
JOIN Sala s ON t.id_sala = s.id_sala
JOIN Asiento a ON b.asiento_id = a.id_asiento;

-- Vista para disponibilidad de asientos por tanda
DROP VIEW IF EXISTS v_asientos_disponibles;
CREATE VIEW v_asientos_disponibles AS
SELECT
  t.id_tanda,
  a.id_asiento,
  a.nombre AS asiento_nombre,
  a.estatus,
  CASE WHEN EXISTS (SELECT 1 FROM Boleto b WHERE b.tanda_id = t.id_tanda AND b.asiento_id = a.id_asiento) THEN 0 ELSE 1 END AS disponible
FROM Tandas t
JOIN Asiento a ON a.id_sala = t.id_sala;

-- --------------------
-- 4) TRIGGERS
-- --------------------
-- Trigger: cuando se inserta un boleto, marcar asiento como Ocupado y loggear
DROP TRIGGER IF EXISTS trg_boleto_after_insert;
DELIMITER $$
CREATE TRIGGER trg_boleto_after_insert
AFTER INSERT ON Boleto
FOR EACH ROW
BEGIN
  -- Actualiza estatus del asiento
  UPDATE Asiento SET estatus = 'Ocupado' WHERE id_asiento = NEW.asiento_id;
  -- Inserta en log
  INSERT INTO Log_Transacciones(tabla_afectada, tipo_operacion, usuario_db, detalle)
  VALUES('Boleto','INSERT',USER(), CONCAT('Boleto ID ', NEW.id_boleto, ' - Asiento ', NEW.asiento_id, ' - Tanda ', NEW.tanda_id));
END$$
DELIMITER ;

-- Trigger: cuando se borra un boleto, liberar asiento y loggear
DROP TRIGGER IF EXISTS trg_boleto_after_delete;
DELIMITER $$
CREATE TRIGGER trg_boleto_after_delete
AFTER DELETE ON Boleto
FOR EACH ROW
BEGIN
  UPDATE Asiento SET estatus = 'Libre' WHERE id_asiento = OLD.asiento_id;
  INSERT INTO Log_Transacciones(tabla_afectada, tipo_operacion, usuario_db, detalle)
  VALUES('Boleto','DELETE',USER(), CONCAT('Boleto ID ', OLD.id_boleto, ' eliminado - Asiento ', OLD.asiento_id));
END$$
DELIMITER ;

-- --------------------
-- 5) STORED PROCEDURES (operaciones atómicas que el backend puede llamar)
-- --------------------
DROP PROCEDURE IF EXISTS sp_generar_boleto;
DELIMITER $$

CREATE PROCEDURE sp_generar_boleto(
  IN p_usuario_id BIGINT,
  IN p_tanda_id BIGINT,
  IN p_asiento_id BIGINT,
  IN p_metodo_pago VARCHAR(50),
  IN p_monto DECIMAL(10,2),
  OUT p_boleto_id BIGINT,
  OUT p_error_msg VARCHAR(255)
)
main_block: BEGIN
  DECLARE v_exist INT DEFAULT 0;
  DECLARE v_asiento_status VARCHAR(20);

  -- Manejador de errores SQL
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_boleto_id = NULL;
    SET p_error_msg = 'Error interno al generar boleto.';
  END;

  START TRANSACTION;

  -- 1. Verificar que la tanda exista
  SELECT COUNT(*) INTO v_exist FROM Tandas WHERE id_tanda = p_tanda_id;
  IF v_exist = 0 THEN
    SET p_error_msg = 'Tanda no encontrada';
    ROLLBACK;
    SET p_boleto_id = NULL;
    LEAVE main_block;
  END IF;

  -- 2. Verificar que el asiento exista y esté libre
  SELECT a.estatus INTO v_asiento_status
  FROM Asiento a
  WHERE a.id_asiento = p_asiento_id
  FOR UPDATE;

  IF v_asiento_status IS NULL THEN
    SET p_error_msg = 'Asiento no encontrado';
    ROLLBACK;
    SET p_boleto_id = NULL;
    LEAVE main_block;
  END IF;

  IF v_asiento_status != 'Libre' THEN
    SET p_error_msg = 'Asiento no disponible';
    ROLLBACK;
    SET p_boleto_id = NULL;
    LEAVE main_block;
  END IF;

  -- 3. Generar hash único (simplificado)
  SET @hash_val = CONCAT('B-', UNIX_TIMESTAMP(), '-', FLOOR(RAND() * 1000000));

  -- 4. Insertar el boleto
  INSERT INTO Boleto (tanda_id, dueño_id, asiento_id, hash, metodo_pago, monto)
  VALUES (p_tanda_id, p_usuario_id, p_asiento_id, @hash_val, p_metodo_pago, p_monto);

  SET p_boleto_id = LAST_INSERT_ID();

  -- 5. Actualizar asiento a ocupado
  UPDATE Asiento SET estatus = 'Ocupado' WHERE id_asiento = p_asiento_id;

  COMMIT;
  SET p_error_msg = NULL;
END$$

DELIMITER ;


-- --------------------
-- 6) DATOS DE EJEMPLO (mínimos) para pruebas
-- --------------------
INSERT INTO Rol (nombre, descripcion) VALUES ('Cliente','Cliente estándar'),('Admin','Administrador del sistema');

INSERT INTO Usuario (nombre, apellido, rol_id, correo, contraseña)
VALUES ('Ana','Perez',1,'ana@example.com','$2y$...'),('Luis','Garcia',2,'luis@example.com','$2y$...');

INSERT INTO Sala (tipo, nombre, capacidad) VALUES ('3D','Sala A',120),('2D','Sala B',80);

INSERT INTO Pelicula (nombre, descripcion, fecha_estreno, duracion, categoria, clasificacion)
VALUES ('La Gran Función','Descripción corta','2025-10-20', 125, 'Acción', 'B');

INSERT INTO Cartelera (estado, fecha_inicio, fecha_fin, id_pelicula) VALUES ('Activa','2025-10-20','2025-11-20',1);

INSERT INTO Tandas (id_pelicula, id_sala, estado, hora_inicio, hora_fin, fecha, precio)
VALUES (1,1,'Programada','18:30:00','20:35:00','2025-11-05',10.00);

-- Crear asientos para sala 1 (ejemplo simple)
INSERT INTO Asiento (id_sala,nombre,estatus)
SELECT 1, CONCAT('A',n), 'Libre' FROM (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) nums;



-- --------------------
-- 7) USUARIOS/PRIVILEGIOS (ejemplo)
-- --------------------
-- CREATE USER 'api_user'@'%' IDENTIFIED BY 'tu_password_segura';
-- GRANT SELECT, INSERT, UPDATE ON cine.* TO 'api_user'@'%';
-- FLUSH PRIVILEGES;

-- --------------------
-- 8) BACKUP / RESTORE (notas)
-- --------------------
-- Backup completo:asiento
-- mysqldump -u root -p cine > cine_backup_$(date +%F).sql
-- Restore:
-- mysql -u root -p cine < cine_backup_2025-11-03.sql

-- Para bases de producción con alta disponibilidad usar: snapshots, binlogs y replication.

-- --------------------
-- 9) DOCUMENTACIÓN ADICIONAL (sugerida)
-- --------------------
-- * Archivo README.md con: cómo desplegar, pasos para restaurar, credenciales de test, endpoints de vistas/procedimientos.
-- * Diagrama ER (exportable desde MySQL Workbench) adjunto al release.
-- * Script de carga de datos de prueba separado (seed_data.sql) para facilitar testing.

-- FIN DEL SCRIPT


-- test --
-- Mostrar todas las tablas
SHOW TABLES;

-- Verificar columnas
DESCRIBE Pelicula;

-- Verificar llaves foráneas
SELECT
  table_name,
  constraint_name,
  referenced_table_name
FROM information_schema.KEY_COLUMN_USAGE
WHERE referenced_table_name IS NOT NULL;

-- Verificar cambio de estado del asiento
SELECT estatus FROM Asiento WHERE id_asiento = 1;

CALL sp_generar_boleto(1, 1, 1);

SELECT estatus FROM Asiento WHERE id_asiento = 1;

-- Caso exitoso
CALL sp_generar_boleto(1, 1, 2);

-- Caso de error: asiento ya ocupado
CALL sp_generar_boleto(1, 1, 2);

SELECT * FROM v_boletos_detalle;
SELECT * FROM v_asientos_disponibles;


