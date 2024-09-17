using Microsoft.EntityFrameworkCore;
using TestTaskForWork.Modules;

namespace TestTaskForWork.Context
{
    public class AssemblyContext : DbContext
    {
        public DbSet<nomenclature> nomenclature { get; set; }
        public DbSet<assemblysite> assemblysite { get; set; }
        public DbSet<order> order { get; set; }
        public DbSet<ordernomenclature> ordernomenclature { get; set; }
        public DbSet<assemblytask> assemblytask { get; set; }
        public DbSet<inventory> inventorie { get; set; }

        private static string _connectionString;

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseMySql("server=localhost;database=database;user=root;password=password",
                new MySqlServerVersion(new Version(8, 0, 21)));
        }

        public static void UpdateConnectionString(string connectionString)
        {
            _connectionString = connectionString;
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder) { } // Доп настройки
    }
}
