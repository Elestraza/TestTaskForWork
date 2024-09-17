namespace TestTaskForWork.Modules
{
    public class ordernomenclature
    {
        public int id { get; set; }
        public int crderid { get; set; }
        public order order { get; set; }

        public int nomenclatureid { get; set; }
        public nomenclature nomenclature { get; set; }

        public int quantity { get; set; }
        public string status { get; set; }  // "Зарезервировано", "Произведено", "Отменено"
    }
}
