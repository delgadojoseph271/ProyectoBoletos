using System;

namespace ProyectoBoletos.App.Models
{
    public class LogTransaccion
    {
        public long IdLog { get; set; }
        public string TablaAfectada { get; set; }
        public string TipoOperacion { get; set; }
        public string UsuarioDB { get; set; }
        public DateTime Fecha { get; set; }
        public string Detalle { get; set; }
    }
}
