using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProyectoBoletos.App.Controllers;
using ProyectoBoletos.App.Models;

namespace ProyectoBoletos.Tests
{
    [TestClass]
    public class UsuarioTests
    {
        private readonly UsuarioController controller = new UsuarioController();

        [TestMethod]
        public void AgregarYLoginUsuario()
        {
            var nuevo = new Usuario
            {
                Nombre = "Juan",
                Apellido = "Tester",
                Correo = "juan.tester@cine.com",
                Contraseña = "1234",
                RolId = 1 // Cambia por un ID real
            };

            var creado = controller.Agregar(nuevo);
            Assert.IsTrue(creado);

            var login = controller.Login("juan.tester@cine.com", "1234");
            Assert.IsNotNull(login);
            Assert.AreEqual("Juan", login.Nombre);
        }
    }
}
