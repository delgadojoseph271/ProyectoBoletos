using MySql.Data.MySqlClient;

namespace ProyectoBoletos.App.Data
{
    public class ConexionDB
    {
        private readonly string _connectionString = 
            "Server=localhost;Database=cine;User ID=root;Password=;SslMode=none;";

        public MySqlConnection GetConnection()
        {
            var conn = new MySqlConnection(_connectionString);
            conn.Open();
            return conn;
        }
    }
}
