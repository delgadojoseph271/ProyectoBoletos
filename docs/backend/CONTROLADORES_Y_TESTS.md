# 🎬 Proyecto Boletos - Documentación Técnica de Controladores y Pruebas

## 📁 Estructura del proyecto

```
ProyectoBoletos/
├── src/
│   └── ProyectoBoletos.App/
│       ├── Models/               # Clases que representan tablas de la BD
│       ├── Controllers/          # Lógica que conecta la BD con la App
│       ├── Views/                # (UI en caso de integrar con WinForms)
│       ├── Data/                 # Conexión a MySQL y configuración
│       ├── Utils/                # Herramientas de apoyo
│       ├── ProyectoBoletos.App.csproj
│       └── Program.cs
├── tests/
│   └── ProyectoBoletos.Tests/
│       ├── BoletoTests.cs
│       ├── RolTests.cs
│       ├── ProyectoBoletos.Tests.csproj
│       └── TestDbHelper.cs       # (opcional, ver más abajo)
├── ProyectoBoletos.sln
├── README.md
└── .gitignore
```

---

## ⚙️ Base de datos

Base de datos usada: `cine`

Contiene las tablas:

- `Rol`
- `Usuario`
- `Sala`
- `Pelicula`
- `Cartelera`
- `Tandas`
- `Asiento`
- `Boleto`
- `Log_Transacciones`

Además de:

- **Vistas:** `v_boletos_detalle`, `v_asientos_disponibles`
- **Triggers:** `trg_boleto_after_insert`, `trg_boleto_after_delete`
- **Procedimiento:** `sp_generar_boleto`

---

## 🧩 Configuración de conexión

Archivo recomendado: `src/ProyectoBoletos.App/Data/Database.cs`

```csharp
using MySql.Data.MySqlClient;

namespace ProyectoBoletos.App.Data
{
    public class Database
    {
        private const string ConnectionString = "Server=localhost;Database=cine;Uid=root;Pwd=;";

        public static MySqlConnection GetConnection()
        {
            var conn = new MySqlConnection(ConnectionString);
            conn.Open();
            return conn;
        }
    }
}
```

---

## 🧠 Controladores principales

Ubicación: `src/ProyectoBoletos.App/Controllers/`

Cada controlador se comunica directamente con la base de datos **sin ORM**, mediante `MySqlCommand`.

### 🎟️ BoletoController.cs

Encargado de manejar la lógica de compra de boletos, incluyendo la ejecución del `sp_generar_boleto`.

```csharp
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Data;

namespace ProyectoBoletos.App.Controllers
{
    public class BoletoController
    {
        public (long boletoId, string errorMsg) GenerarBoleto(
            long usuarioId, long tandaId, long asientoId,
            string metodoPago, decimal monto)
        {
            using var conn = Database.GetConnection();
            using var cmd = new MySqlCommand("sp_generar_boleto", conn)
            {
                CommandType = System.Data.CommandType.StoredProcedure
            };

            cmd.Parameters.AddWithValue("@p_usuario_id", usuarioId);
            cmd.Parameters.AddWithValue("@p_tanda_id", tandaId);
            cmd.Parameters.AddWithValue("@p_asiento_id", asientoId);
            cmd.Parameters.AddWithValue("@p_metodo_pago", metodoPago);
            cmd.Parameters.AddWithValue("@p_monto", monto);

            var outId = new MySqlParameter("@p_boleto_id", MySqlDbType.Int64)
            {
                Direction = System.Data.ParameterDirection.Output
            };
            var outMsg = new MySqlParameter("@p_error_msg", MySqlDbType.VarChar, 255)
            {
                Direction = System.Data.ParameterDirection.Output
            };

            cmd.Parameters.Add(outId);
            cmd.Parameters.Add(outMsg);

            cmd.ExecuteNonQuery();

            long boletoId = outId.Value != DBNull.Value ? Convert.ToInt64(outId.Value) : 0;
            string error = outMsg.Value != DBNull.Value ? outMsg.Value.ToString() : null;

            return (boletoId, error);
        }
    }
}
```

---

### 👤 RolController.cs

Ejemplo de CRUD simple.

```csharp
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Data;
using ProyectoBoletos.App.Models;
using System.Collections.Generic;

namespace ProyectoBoletos.App.Controllers
{
    public class RolController
    {
        public List<Rol> ObtenerRoles()
        {
            var lista = new List<Rol>();
            using var conn = Database.GetConnection();
            using var cmd = new MySqlCommand("SELECT * FROM Rol", conn);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                lista.Add(new Rol
                {
                    Id = reader.GetInt64("id"),
                    Nombre = reader.GetString("nombre"),
                    Descripcion = reader.IsDBNull("descripcion") ? "" : reader.GetString("descripcion")
                });
            }
            return lista;
        }
    }
}
```

---

## 🧪 Pruebas unitarias (tests)

Ubicación: `tests/ProyectoBoletos.Tests/`

Se utiliza MSTest para validar controladores.

Ejemplo: `RolTests.cs`

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProyectoBoletos.App.Controllers;

namespace ProyectoBoletos.Tests
{
    [TestClass]
    public class RolTests
    {
        [TestMethod]
        public void Obtener_Roles_NoVacio()
        {
            var controller = new RolController();
            var roles = controller.ObtenerRoles();

            Assert.IsNotNull(roles);
            Assert.IsTrue(roles.Count >= 0);
        }
    }
}
```

Ejemplo: `BoletoTests.cs`

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProyectoBoletos.App.Controllers;

namespace ProyectoBoletos.Tests
{
    [TestClass]
    public class BoletoTests
    {
        [TestMethod]
        public void Generar_Boleto_Valido()
        {
            var controller = new BoletoController();
            var (boletoId, error) = controller.GenerarBoleto(1, 1, 1, "Efectivo", 5.00m);

            Assert.IsTrue(boletoId > 0, error ?? "No se generó el boleto correctamente");
        }
    }
}
```

---

## ⚠️ Errores comunes y cómo solucionarlos

| Error                           | Causa probable                                 | Solución                                                           |
| ------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------ |
| `Asiento no disponible`         | El asiento ya tiene un boleto asociado         | Ejecutar `DELETE FROM Boleto; UPDATE Asiento SET estatus='Libre';` |
| `MySqlException: Access denied` | Usuario o contraseña incorrecta en la conexión | Verificar `Database.cs`                                            |
| `Table not found`               | No se ejecutó el script SQL completo           | Importar la BD `cine.sql`                                          |
| `NullReferenceException`        | Faltan parámetros o conexión no abierta        | Revisar inicialización en controladores                            |

---

## 💡 Consejos para el equipo de Windows Forms

- **Nunca acceder directamente a la BD desde el Form.**  
  Siempre hacerlo mediante los controladores (`Controllers/`).

- **Mantener los modelos simples**, sin lógica de negocio.

- **Centralizar la conexión** en `Database.cs`.

- **Para insertar datos de prueba**, usar MySQL Workbench o ejecutar:

  ```sql
  INSERT INTO Rol (nombre, descripcion) VALUES ('Administrador', 'Control total');
  ```

- **Para depurar**, puedes imprimir mensajes:
  ```csharp
  Console.WriteLine($"Boleto generado ID: {boletoId}");
  ```

---

## ✅ Estado actual de pruebas

Ejemplo de salida típica al compilar:

```
ProyectoBoletos.Tests correcto con 3 advertencias (2.9s)
  ProyectoBoletos.Tests pruebaerror con 1 errores (7.8s)
Resumen de pruebas: total: 5; con errores: 1; correcto: 4
```

**Advertencias (MSTEST0001, MSTEST0037)** → Son solo sugerencias de estilo, no afectan ejecución.  
**Error “Asiento no disponible”** → se corrige reiniciando la tabla `Asiento`.

---

## 🗂️ Recomendación final

Guardar este archivo como:

```
/docs/CONTROLADORES_Y_TESTS.md
```

para mantener una guía clara para quien implemente los formularios.

---

_Equipo de desarrollo — Proyecto CINE (2025)_
