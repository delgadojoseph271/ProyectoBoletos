using System;

namespace ProyectoBoletos.App.Models
{
    public class Cartelera
    {
        public long IdCartelera { get; set; }
        public string Estado { get; set; }  // 'Activa','Inactiva','Proxima'
        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }
        public long IdPelicula { get; set; }

        // Relación
        public Pelicula Pelicula { get; set; }
    }
}
