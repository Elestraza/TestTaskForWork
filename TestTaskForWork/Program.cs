using TestTaskForWork.Context;

namespace TestTaskForWork
{
    internal static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool connected = false;

            while (!connected)
            {
                try
                {
                    using (var context = new AssemblyContext())
                    {
                        // Попытка выполнить запрос к базе данных
                        context.Database.CanConnect();
                        connected = true;
                    }
                }
                catch
                {
                    // Если подключение невозможно, отображаем форму для ввода данных
                    using (var settingsForm = new ConnectionSettingsForm())
                    {
                        if (settingsForm.ShowDialog() == DialogResult.OK)
                        {
                            var connectionString = settingsForm.ConnectionString;
                            // Обновляем строку подключения в контексте данных
                            AssemblyContext.UpdateConnectionString(connectionString);
                        }
                        else
                        {
                            // Если пользователь отменил, закрываем приложение
                            Application.Exit();
                            return;
                        }
                    }
                }
            }

            Application.Run(new Form1());
        }
    }
}