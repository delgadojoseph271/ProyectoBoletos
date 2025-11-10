using System;

namespace ProyectoBoletos.App.Models
{
    public class Boleto
    {
        public long IdBoleto { get; set; }
        public long TandaId { get; set; }
        public long DueñoId { get; set; }
        public DateTime FechaCompra { get; set; }
        public long AsientoId { get; set; }
        public string Hash { get; set; }
        public string MetodoPago { get; set; }
        public decimal Monto { get; set; }

        // Relaciones
        public Tanda Tanda { get; set; }
        public Usuario Dueno { get; set; }
        public Asiento Asiento { get; set; }
    }
}
