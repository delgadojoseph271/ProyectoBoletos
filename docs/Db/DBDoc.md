# 🎓 Proyecto: Sistema de Boletos - Base de Datos (Release 1.0)

## 🧩 Descripción general

Este proyecto implementa la **base de datos relacional** para un sistema de administración de boletos de cine. La estructura está diseñada para ofrecer integridad, mantenibilidad y escalabilidad, y servir como backend sólido para aplicaciones web o móviles.

Incluye:

- Modelo relacional normalizado (3FN)
- Llaves primarias y foráneas bien definidas
- Triggers de auditoría y control de disponibilidad
- Procedimientos almacenados para operaciones atómicas
- Vistas de uso común para simplificar consultas

---

## 📁 Estructura principal

### Tablas

| Tabla         | Descripción                                                                                                                                               |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pelicula**  | Contiene la información principal de cada película: nombre, descripción, fechas de estreno y salida, duración, categoría, clasificación y URL de portada. |
| **Tandas**    | Representa las funciones (horarios de proyección) de cada película. Contiene hora, fecha, sala y estado.                                                  |
| **Sala**      | Identifica las salas disponibles en el cine, con su nombre y tipo.                                                                                        |
| **Asiento**   | Define los asientos físicos de cada sala, su estado (disponible, ocupado, fuera de servicio) y su identificador.                                          |
| **Boleto**    | Registra la compra de un boleto. Incluye el usuario comprador, la tanda, el asiento y un hash único.                                                      |
| **Usuario**   | Guarda la información de los usuarios registrados (clientes, administradores, empleados).                                                                 |
| **Rol**       | Define los diferentes roles que un usuario puede tener.                                                                                                   |
| **Cartelera** | Relaciona las películas disponibles durante un período específico.                                                                                        |

---

## 🔗 Relaciones (FK)

- **Boleto** → `Tandas(id_tanda)` y `Usuario(id)`
- **Asiento** → `Sala(id_sala)`
- **Tandas** → `Pelicula(id_pelicula)` y `Sala(id_sala)`
- **Usuario** → `Rol(id)`
- **Cartelera** → `Pelicula(id_pelicula)`

---

## ⚙️ Vistas incluidas

### `v_boletos_detalle`

Muestra la información completa de cada boleto: película, usuario, sala y asiento.

```sql
CREATE VIEW v_boletos_detalle AS
SELECT b.id_boleto, u.nombre AS usuario, p.nombre AS pelicula, s.nombre AS sala, a.nombre AS asiento
FROM Boleto b
JOIN Usuario u ON b.dueño = u.id
JOIN Tandas t ON b.tanda = t.id_tanda
JOIN Pelicula p ON t.id_pelicula = p.id_pelicula
JOIN Sala s ON t.id_sala = s.id_sala
JOIN Asiento a ON b.asiento = a.id_asiento;
```

### `v_asientos_disponibles`

Lista todos los asientos libres por sala y tanda.

```sql
CREATE VIEW v_asientos_disponibles AS
SELECT s.nombre AS sala, a.nombre AS asiento
FROM Asiento a
JOIN Sala s ON a.id_sala = s.id_sala
WHERE a.estatus = 'disponible';
```

---

## ⚡ Triggers

### `tr_auditoria_boletos`

Guarda un registro de cada compra de boleto.

```sql
CREATE TRIGGER tr_auditoria_boletos
AFTER INSERT ON Boleto
FOR EACH ROW
INSERT INTO LogBoletos (id_boleto, fecha, accion)
VALUES (NEW.id_boleto, NOW(), 'Creación de boleto');
```

### `tr_actualizar_asiento`

Cambia el estado de un asiento a _ocupado_ cuando se compra un boleto.

```sql
CREATE TRIGGER tr_actualizar_asiento
AFTER INSERT ON Boleto
FOR EACH ROW
UPDATE Asiento SET estatus = 'ocupado'
WHERE id_asiento = NEW.asiento;
```

---

## 🧮 Procedimientos almacenados

### `sp_generar_boleto`

Crea un boleto de forma atómica y segura.

```sql
CREATE PROCEDURE sp_generar_boleto(
  IN p_usuario_id BIGINT,
  IN p_tanda_id BIGINT,
  IN p_asiento_id BIGINT,
  IN p_metodo_pago VARCHAR(50),
  IN p_monto DECIMAL(10,2),
  OUT p_boleto_id BIGINT,
  OUT p_error_msg VARCHAR(255)
)
BEGIN
  DECLARE v_exist INT DEFAULT 0;
  DECLARE v_asiento_status VARCHAR(20);

  START TRANSACTION;

  SELECT COUNT(*) INTO v_exist FROM Tandas WHERE id_tanda = p_tanda_id;
  IF v_exist = 0 THEN
    SET p_error_msg = 'Tanda no encontrada';
    ROLLBACK; LEAVE BEGIN;
  END IF;

  SELECT estatus INTO v_asiento_status FROM Asiento WHERE id_asiento = p_asiento_id FOR UPDATE;
  IF v_asiento_status != 'Libre' THEN
    SET p_error_msg = 'Asiento no disponible';
    ROLLBACK; LEAVE BEGIN;
  END IF;

  SET @hash_val = CONCAT('B-', UNIX_TIMESTAMP(), '-', FLOOR(RAND() * 1000000));

  INSERT INTO Boleto (tanda_id, dueño_id, asiento_id, hash, metodo_pago, monto)
  VALUES (p_tanda_id, p_usuario_id, p_asiento_id, @hash_val, p_metodo_pago, p_monto);

  SET p_boleto_id = LAST_INSERT_ID();
  UPDATE Asiento SET estatus = 'Ocupado' WHERE id_asiento = p_asiento_id;

  COMMIT;
  SET p_error_msg = NULL;
END;

```

---

## 🧠 Recomendaciones de entrega y QA

1. **Validación de datos:**

   - Comprobar que no existan campos nulos en claves primarias.
   - Asegurar la integridad referencial entre FK y PK.

2. **Usuarios y roles:**

   - Crear usuarios con permisos limitados según el rol (`SELECT`, `INSERT`, `UPDATE`, `DELETE`).
   - Evitar usar el usuario `root` para las operaciones de aplicación.

3. **Respaldo y replicación:**

   - Exportar la BD en formato `.sql` usando `mysqldump`.
   - (Opcional) Configurar replicación maestro-esclavo si se requiere tolerancia a fallos.

4. **Rendimiento:**
   - Indexar columnas usadas frecuentemente en consultas (`id_pelicula`, `id_tanda`, `correo`).
   - Revisar el plan de ejecución (`EXPLAIN`) de las vistas más usadas.

---

## ✅ Estado del proyecto

Versión: **1.0 (Entrega universitaria)**

- Esquema funcional ✅
- Relaciones y restricciones integradas ✅
- Triggers y vistas documentadas ✅
- Procedimiento de compra funcional ✅
- Pendiente: auditoría completa y backup automatizado ⚙️

---

**Autor:** Equipo de desarrollo académico  
**Revisor:** Joseph (Coordinador técnico / Programador)

📅 _Fecha de entrega: noviembre 2025_
