namespace TestTaskForWork.Modules
{
    public class nomenclature
    {
        public int id { get; set; }
        public string name { get; set; }
        public string type { get; set; }  // "Запчасть" или "Комплект"
        public int assemblytime { get; set; }  // Время сборки в днях

        public ICollection<ordernomenclature> ordernomenclatures { get; set; }
        public ICollection<assemblytask> assemblytasks { get; set; }
    }
}
