using System;
using System.Collections.Generic;
using System.Data;
using MySql.Data.MySqlClient;
using ProyectoBoletos.App.Models;

namespace ProyectoBoletos.App.Controllers
{
    public class BoletoController : DbController
    {
        public (long boletoId, string error) GenerarBoleto(long usuarioId, long tandaId, long asientoId, string metodoPago, decimal monto)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new MySqlCommand("sp_generar_boleto", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("p_usuario_id", usuarioId);
                    cmd.Parameters.AddWithValue("p_tanda_id", tandaId);
                    cmd.Parameters.AddWithValue("p_asiento_id", asientoId);
                    cmd.Parameters.AddWithValue("p_metodo_pago", metodoPago);
                    cmd.Parameters.AddWithValue("p_monto", monto);

                    var pBoletoId = new MySqlParameter("p_boleto_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
                    var pError = new MySqlParameter("p_error_msg", MySqlDbType.VarChar, 255) { Direction = ParameterDirection.Output };

                    cmd.Parameters.Add(pBoletoId);
                    cmd.Parameters.Add(pError);

                    cmd.ExecuteNonQuery();

                    return (
                        boletoId: pBoletoId.Value == DBNull.Value ? 0 : Convert.ToInt64(pBoletoId.Value),
                        error: pError.Value?.ToString()
                    );
                }
            }
        }

        public List<dynamic> ObtenerDetalleBoletos()
        {
            var lista = new List<dynamic>();
            using (var conn = GetConnection())
            {
                conn.Open();
                string query = "SELECT * FROM v_boletos_detalle";
                using (var cmd = new MySqlCommand(query, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new
                        {
                            IdBoleto = reader.GetInt64("id_boleto"),
                            Hash = reader.GetString("hash"),
                            FechaCompra = reader.GetDateTime("fecha_compra"),
                            Monto = reader.GetDecimal("monto"),
                            Usuario = reader["usuario_nombre"].ToString(),
                            Pelicula = reader["pelicula_nombre"].ToString(),
                            Sala = reader["sala_nombre"].ToString(),
                            Asiento = reader["asiento_nombre"].ToString()
                        });
                    }
                }
            }
            return lista;
        }
    }
}
