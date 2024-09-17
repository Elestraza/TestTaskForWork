namespace TestTaskForWork.Modules
{
    public class assemblysite
    {
        public int id { get; set; }
        public string name { get; set; }
        public string location { get; set; }

        public ICollection<assemblytask> assemblytasks { get; set; }
        public ICollection<inventory> inventories { get; set; }
    }
}
