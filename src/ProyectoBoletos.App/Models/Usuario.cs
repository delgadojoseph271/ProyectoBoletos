using System;

namespace ProyectoBoletos.App.Models
{
    public class Usuario
    {
        public long Id { get; set; }
        public string Nombre { get; set; }
        public string Apellido { get; set; }
        public long RolId { get; set; }
        public string Correo { get; set; }
        public string Contraseña { get; set; }
        public DateTime CreadoEn { get; set; }

        // Relaciones
        public Rol Rol { get; set; }
    }
}
