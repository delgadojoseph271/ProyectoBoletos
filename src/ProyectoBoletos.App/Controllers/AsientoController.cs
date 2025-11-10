using System;
using System.Collections.Generic;
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Models;

namespace ProyectoBoletos.App.Controllers
{
    public class AsientoController : DbController
    {
        public List<Asiento> ObtenerPorSala(long idSala)
        {
            var lista = new List<Asiento>();
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "SELECT * FROM Asiento WHERE id_sala = @idSala";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idSala", idSala);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            lista.Add(new Asiento
                            {
                                IdAsiento = reader.GetInt64("id_asiento"),
                                IdSala = reader.GetInt64("id_sala"),
                                Nombre = reader.GetString("nombre"),
                                Estatus = reader.GetString("estatus")
                            });
                        }
                    }
                }
            }
            return lista;
        }

        public List<dynamic> ObtenerDisponiblesPorTanda(long idTanda)
        {
            var lista = new List<dynamic>();
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "SELECT * FROM v_asientos_disponibles WHERE id_tanda = @idTanda";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idTanda", idTanda);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            lista.Add(new
                            {
                                IdAsiento = reader.GetInt64("id_asiento"),
                                Nombre = reader.GetString("asiento_nombre"),
                                Estatus = reader.GetString("estatus"),
                                Disponible = reader.GetBoolean("disponible")
                            });
                        }
                    }
                }
            }
            return lista;
        }
    }
}
