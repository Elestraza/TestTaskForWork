namespace TestTaskForWork.Modules
{
    public class assemblytask
    {
        public int id { get; set; }
        public int nomenclatureid { get; set; }
        public nomenclature nomenclature { get; set; }

        public int assemblysiteid { get; set; }
        public assemblysite assemblysite { get; set; }

        public DateTime duedate { get; set; }
        public DateTime? completeddate { get; set; }
    }
}
