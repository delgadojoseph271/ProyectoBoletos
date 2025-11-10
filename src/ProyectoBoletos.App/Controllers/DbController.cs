using System;
using System.Data;
using MySql.Data.MySqlClient;

namespace ProyectoBoletos.App.Controllers
{
    public abstract class DbController
    {
        protected string connectionString = "server=localhost;database=cine;user=root;password=123456789;";

        protected MySqlConnection GetConnection()
        {
            return new MySqlConnection(connectionString);
        }
    }
}
