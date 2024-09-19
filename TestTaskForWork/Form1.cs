using Microsoft.EntityFrameworkCore;
using MySqlConnector;
using TestTaskForWork.Context;
using TestTaskForWork.Modules;

namespace TestTaskForWork
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private int _lastOrderId;
        private int _currentOrderId;

        private void AddLabelToPanel(string labelText, string orderId)
        {
            Control lastControl = panel1.Controls.Cast<Control>().LastOrDefault();

            Label newLabel = new Label();
            newLabel.Text = labelText;
            newLabel.ForeColor = Color.Black;
            newLabel.AutoSize = true;

            if (lastControl != null)
            {
                newLabel.Location = new Point(10, lastControl.Bottom + 10);
            } else
            {
                newLabel.Location = new Point(10, 10);
            }

            panel1.Controls.Add(newLabel);

            Button cancelButton = new Button();
            cancelButton.Text = "Cancel";
            cancelButton.ForeColor = Color.White;
            cancelButton.BackColor = Color.DarkRed;
            cancelButton.AutoSize = true;

            cancelButton.Location = new Point(newLabel.Right + 10, newLabel.Top);

            cancelButton.Tag = orderId; // Используем Tag для хранения ID заказа
            cancelButton.Click += btnCancelOrder_Click;

            panel1.Controls.Add(cancelButton);
        }

        private void tbQuantity_KeyPress(object sender, KeyPressEventArgs e) // Обрабатываем нажатие цифр
        {
            e.Handled = !char.IsDigit(e.KeyChar) && !char.IsControl(e.KeyChar);
        }

        private void btnOrder_Click(object sender, EventArgs e)
        {
            using (var context = new AssemblyContext())
            {
                var selectedNomenclature = comboBox1.SelectedItem.ToString();
                var quantity = int.Parse(tbQuantity.Text);

                // Получаем ID выбранной номенклатуры
                var nomenclature = context.nomenclature.FirstOrDefault(n => n.name == selectedNomenclature);

                if (nomenclature == null)
                {
                    MessageBox.Show("Номенклатура не найдена.");
                    return;
                }

                var orderDate = DateTime.Now;

                // Вызов хранимой процедуры AddOrder
                context.Database.ExecuteSqlRaw("CALL AddOrder({0}, {1}, {2})", orderDate, nomenclature.id, quantity);

                var order = context.order.FirstOrDefault(n => n.id == nomenclature.id);
 
                AddLabelToPanel($"Заказ на {nomenclature.name} в количестве {quantity} создан.", order.id.ToString());
            }
        }

        private void btnCancelOrder_Click(object sender, EventArgs e)
        {
            var clickedBtn = sender as Button;
            string orderIdStr = clickedBtn.Tag.ToString();

            // Проверьте, что orderIdStr можно преобразовать в целое число
            if (!int.TryParse(orderIdStr, out int orderId))
            {
                MessageBox.Show("Некорректный ID заказа.");
                return;
            }

            if (_currentOrderId <= 0)
            {
                MessageBox.Show("Сначала создайте заказ.");
                return;
            }

            using (var context = new AssemblyContext())
            {
                // Вызов хранимой процедуры CancelOrder с параметрами
                context.Database.ExecuteSqlRaw("CALL CancelOrder(@pOrderID)",
                    new MySqlParameter("@pOrderID", orderId));

                AddLabelToPanel($"Заказ № {orderId} отменен.", orderIdStr);
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            using (var context = new AssemblyContext())
            {
                // Получаем все номенклатуры и добавляем их в ComboBox
                var nomenclatures = context.nomenclature.ToList();
                foreach (var nomenclature in nomenclatures)
                {
                    comboBox1.Items.Add(nomenclature.name);
                }

                // Получаем все заказы
                var orders = context.order.ToList();
                foreach (var order in orders)
                {
                    string canceled = order.iscancelled ? "(Отменен)" : "";
                    AddLabelToPanel($"Заказ № {order.id} от {order.orderdate} {canceled}", order.id.ToString());
                    _currentOrderId = order.id;
                }
            }
        }
    }
}
