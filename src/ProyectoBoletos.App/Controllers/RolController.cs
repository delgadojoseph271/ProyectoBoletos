using System;
using System.Collections.Generic;
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Models;

namespace ProyectoBoletos.App.Controllers
{
    public class RolController : DbController
    {
        public List<Rol> ObtenerTodos()
        {
            var lista = new List<Rol>();
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "SELECT * FROM Rol";
                using (var cmd = new MySqlCommand(query, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new Rol
                        {
                            Id = reader.GetInt64("id"),
                            Nombre = reader.GetString("nombre"),
                            Descripcion = reader["descripcion"]?.ToString()
                        });
                    }
                }
            }
            return lista;
        }

        public bool Agregar(Rol rol)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "INSERT INTO Rol(nombre, descripcion) VALUES (@nombre, @descripcion)";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@nombre", rol.Nombre);
                    cmd.Parameters.AddWithValue("@descripcion", rol.Descripcion);
                    return cmd.ExecuteNonQuery() > 0;
                }
            }
        }

        public bool Actualizar(Rol rol)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "UPDATE Rol SET nombre=@nombre, descripcion=@descripcion WHERE id=@id";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", rol.Id);
                    cmd.Parameters.AddWithValue("@nombre", rol.Nombre);
                    cmd.Parameters.AddWithValue("@descripcion", rol.Descripcion);
                    return cmd.ExecuteNonQuery() > 0;
                }
            }
        }

        public bool Eliminar(long id)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "DELETE FROM Rol WHERE id=@id";
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    return cmd.ExecuteNonQuery() > 0;
                }
            }
        }
    }
}
