namespace TestTaskForWork.Modules
{
    public class order
    {
        public int id { get; set; }
        public DateTime orderdate { get; set; }
        public DateTime duedate { get; set; }
        public bool iscancelled { get; set; }

        public ICollection<ordernomenclature> ordernomenclatures { get; set; }
    }
}
    