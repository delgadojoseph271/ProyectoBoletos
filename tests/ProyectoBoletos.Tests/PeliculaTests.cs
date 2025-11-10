using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProyectoBoletos.App.Controllers;
using ProyectoBoletos.App.Models;
using System;

namespace ProyectoBoletos.Tests
{
    [TestClass]
    public class PeliculaTests
    {
        private readonly PeliculaController controller = new PeliculaController();

        [TestMethod]
        public void Agregar_Pelicula_DeberiaFuncionar()
        {
            var pelicula = new Pelicula
            {
                Nombre = "Matrix Reloaded",
                Descripcion = "Ciencia ficción",
                FechaEstreno = DateTime.Now,
                Duracion = 120,
                Categoria = "Acción",
                Clasificacion = "PG-13"
            };

            var result = controller.Agregar(pelicula);
            Assert.IsTrue(result);
        }
    }
}
