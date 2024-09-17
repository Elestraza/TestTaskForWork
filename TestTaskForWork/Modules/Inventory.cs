namespace TestTaskForWork.Modules
{
    public class inventory
    {
        public int id { get; set; }
        public int assemblysiteid { get; set; }
        public assemblysite assemblysite { get; set; }

        public int nomenclatureid { get; set; }
        public nomenclature nomenclature { get; set; }

        public int quantity { get; set; }
        public bool reserved { get; set; }
    }
}
