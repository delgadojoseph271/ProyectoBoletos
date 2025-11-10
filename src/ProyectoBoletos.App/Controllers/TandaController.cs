using System;
using System.Collections.Generic;
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Models;

namespace ProyectoBoletos.App.Controllers
{
    public class TandaController : DbController
    {
        public List<Tanda> ObtenerPorFecha(DateTime fecha)
        {
            var lista = new List<Tanda>();
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "SELECT * FROM Tandas WHERE fecha = @fecha";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@fecha", fecha);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            lista.Add(new Tanda
                            {
                                IdTanda = reader.GetInt64("id_tanda"),
                                IdPelicula = reader.GetInt64("id_pelicula"),
                                IdSala = reader.GetInt64("id_sala"),
                                Estado = reader.GetString("estado"),
                                HoraInicio = reader.GetTimeSpan("hora_inicio"),
                                HoraFin = reader["hora_fin"] as TimeSpan?,
                                Fecha = reader.GetDateTime("fecha"),
                                Precio = reader.GetDecimal("precio"),
                                Capacidad = reader.GetInt32("capacidad")
                            });
                        }
                    }
                }
            }
            return lista;
        }
    }
}
