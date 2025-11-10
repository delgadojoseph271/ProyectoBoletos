using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProyectoBoletos.App.Controllers;
using System;

namespace ProyectoBoletos.Tests
{
    [TestClass]
    public class BoletoTests
    {
        private readonly BoletoController controller = new BoletoController();

        [TestMethod]
        public void Generar_Boleto_Valido()
        {
            var (boletoId, error) = controller.GenerarBoleto(
                usuarioId: 1,  // Usuario existente
                tandaId: 1,    // Tanda válida
                asientoId: 1,  // Asiento libre
                metodoPago: "Efectivo",
                monto: 5.50m
            );

            Assert.IsTrue(boletoId > 0, $"Error: {error}");
        }
    }
}
