using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace TestTaskForWork
{
    public partial class ConnectionSettingsForm : Form
    {
        public string ConnectionString { get; private set; }

        public ConnectionSettingsForm()
        {
            InitializeComponent();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            string server = txtServer.Text;
            string database = txtDatabase.Text;
            string user = txtUser.Text;
            string password = txtPassword.Text;

            ConnectionString = $"server={server};database={database};user={user};password={password}";

            DialogResult = DialogResult.OK;
            Close();
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            DialogResult = DialogResult.Cancel;
            Close();
        }
    }
}
