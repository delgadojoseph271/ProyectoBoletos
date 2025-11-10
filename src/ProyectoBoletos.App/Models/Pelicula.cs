using System;

namespace ProyectoBoletos.App.Models
{
    public class Pelicula
    {
        public long IdPelicula { get; set; }
        public string Nombre { get; set; }
        public string Descripcion { get; set; }
        public DateTime? FechaEstreno { get; set; }
        public DateTime? SalidaCartelera { get; set; }
        public int? Duracion { get; set; }
        public string Categoria { get; set; }
        public string Clasificacion { get; set; }
        public string Portada { get; set; }
    }
}
