using System;

namespace ProyectoBoletos.App.Models
{
    public class Asiento
    {
        public long IdAsiento { get; set; }
        public long IdSala { get; set; }
        public string Nombre { get; set; } // Ej: A12
        public string Estatus { get; set; } // 'Libre','Reservado','Ocupado','Inhabilitado'

        // Relación
        public Sala Sala { get; set; }
    }
}
