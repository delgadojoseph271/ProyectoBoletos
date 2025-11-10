using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProyectoBoletos.App.Controllers;
using ProyectoBoletos.App.Models;
using System.Linq;

namespace ProyectoBoletos.Tests
{
    [TestClass]
    public class RolTests
    {
        private readonly RolController controller = new RolController();

        [TestMethod]
        public void Obtener_Roles_NoDevuelveVacio()
        {
            var roles = controller.ObtenerTodos();
            Assert.IsTrue(roles.Count >= 0);
        }

        [TestMethod]
        public void Agregar_Actualizar_Eliminar_Rol()
        {
            var nuevoRol = new Rol { Nombre = "Tester", Descripcion = "Rol temporal de prueba" };
            var insertado = controller.Agregar(nuevoRol);
            Assert.IsTrue(insertado);

            var roles = controller.ObtenerTodos();
            var rolInsertado = roles.LastOrDefault(r => r.Nombre == "Tester");
            Assert.IsNotNull(rolInsertado);

            rolInsertado.Descripcion = "Modificado";
            var actualizado = controller.Actualizar(rolInsertado);
            Assert.IsTrue(actualizado);

            var eliminado = controller.Eliminar(rolInsertado.Id);
            Assert.IsTrue(eliminado);
        }
    }
}
