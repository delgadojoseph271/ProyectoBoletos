using System;

namespace ProyectoBoletos.App.Models
{
    public class Tanda
    {
        public long IdTanda { get; set; }
        public long IdPelicula { get; set; }
        public long IdSala { get; set; }
        public string Estado { get; set; }  // 'Programada','En Curso','Finalizada','Cancelada'
        public TimeSpan HoraInicio { get; set; }
        public TimeSpan? HoraFin { get; set; }
        public DateTime Fecha { get; set; }
        public decimal Precio { get; set; }
        public int? Capacidad { get; set; }

        // Relaciones
        public Pelicula Pelicula { get; set; }
        public Sala Sala { get; set; }
    }
}
