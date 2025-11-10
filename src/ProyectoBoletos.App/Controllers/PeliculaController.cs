using System;
using System.Collections.Generic;
using System.Data;
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Models;

namespace ProyectoBoletos.App.Controllers
{
    public class PeliculaController : DbController
    {
        public List<Pelicula> ObtenerTodas()
        {
            var lista = new List<Pelicula>();
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "SELECT * FROM Pelicula";
                using (var cmd = new MySqlCommand(query, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new Pelicula
                        {
                            IdPelicula = reader.GetInt64("id_pelicula"),
                            Nombre = reader.GetString("nombre"),
                            Descripcion = reader["descripcion"]?.ToString(),
                            FechaEstreno = reader["fecha_estreno"] as DateTime?,
                            SalidaCartelera = reader["salida_cartelera"] as DateTime?,
                            Duracion = reader["duracion"] as int?,
                            Categoria = reader["categoria"]?.ToString(),
                            Clasificacion = reader["clasificacion"]?.ToString(),
                            Portada = reader["portada"]?.ToString()
                        });
                    }
                }
            }
            return lista;
        }

        public bool Agregar(Pelicula p)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = @"INSERT INTO Pelicula(nombre, descripcion, fecha_estreno, salida_cartelera, duracion, categoria, clasificacion, portada)
                                 VALUES (@nombre,@descripcion,@fecha_estreno,@salida_cartelera,@duracion,@categoria,@clasificacion,@portada)";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@nombre", p.Nombre);
                    cmd.Parameters.AddWithValue("@descripcion", p.Descripcion);
                    cmd.Parameters.AddWithValue("@fecha_estreno", p.FechaEstreno);
                    cmd.Parameters.AddWithValue("@salida_cartelera", p.SalidaCartelera);
                    cmd.Parameters.AddWithValue("@duracion", p.Duracion);
                    cmd.Parameters.AddWithValue("@categoria", p.Categoria);
                    cmd.Parameters.AddWithValue("@clasificacion", p.Clasificacion);
                    cmd.Parameters.AddWithValue("@portada", p.Portada);
                    return cmd.ExecuteNonQuery() > 0;
                }
            }
        }
    }
}
