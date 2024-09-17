namespace TestTaskForWork
{
    partial class Form1
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            btnCancelOrder = new Button();
            btnOrder = new Button();
            tbQuantity = new TextBox();
            panel1 = new Panel();
            comboBox1 = new ComboBox();
            SuspendLayout();
            // 
            // btnCancelOrder
            // 
            btnCancelOrder.BackColor = Color.FromArgb(192, 0, 0);
            btnCancelOrder.FlatStyle = FlatStyle.Popup;
            btnCancelOrder.ForeColor = SystemColors.HighlightText;
            btnCancelOrder.Location = new Point(513, 12);
            btnCancelOrder.Name = "btnCancelOrder";
            btnCancelOrder.Size = new Size(75, 23);
            btnCancelOrder.TabIndex = 0;
            btnCancelOrder.Text = "Cancel Order";
            btnCancelOrder.UseVisualStyleBackColor = false;
            btnCancelOrder.Click += btnCancelOrder_Click;
            // 
            // btnOrder
            // 
            btnOrder.FlatStyle = FlatStyle.Popup;
            btnOrder.ForeColor = SystemColors.ActiveCaptionText;
            btnOrder.Location = new Point(432, 12);
            btnOrder.Name = "btnOrder";
            btnOrder.Size = new Size(75, 23);
            btnOrder.TabIndex = 1;
            btnOrder.Text = "Order";
            btnOrder.UseVisualStyleBackColor = true;
            btnOrder.Click += btnOrder_Click;
            // 
            // tbQuantity
            // 
            tbQuantity.Location = new Point(326, 12);
            tbQuantity.Name = "tbQuantity";
            tbQuantity.Size = new Size(100, 23);
            tbQuantity.TabIndex = 3;
            tbQuantity.KeyPress += tbQuantity_KeyPress;
            // 
            // panel1
            // 
            panel1.ForeColor = SystemColors.Control;
            panel1.Location = new Point(12, 41);
            panel1.Name = "panel1";
            panel1.Size = new Size(576, 397);
            panel1.TabIndex = 4;
            // 
            // comboBox1
            // 
            comboBox1.FormattingEnabled = true;
            comboBox1.Location = new Point(12, 12);
            comboBox1.Name = "comboBox1";
            comboBox1.Size = new Size(308, 23);
            comboBox1.TabIndex = 5;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(800, 450);
            Controls.Add(comboBox1);
            Controls.Add(panel1);
            Controls.Add(tbQuantity);
            Controls.Add(btnOrder);
            Controls.Add(btnCancelOrder);
            ForeColor = SystemColors.Control;
            Name = "Form1";
            Text = "Form1";
            Load += Form1_Load;
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Button btnCancelOrder;
        private Button btnOrder;
        private TextBox tbQuantity;
        private Panel panel1;
        private ComboBox comboBox1;
    }
}
