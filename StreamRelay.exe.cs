using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Threading;
using System.Text.RegularExpressions;

namespace StreamRelay
{
    public partial class MainForm : Form
    {
        private Process rtmpProcess;
        private bool isStreaming = false;
        private Thread monitorThread;
        private CancellationTokenSource cancellationTokenSource;
        
        // Stream configuration
        private string twitchKey = "";
        private string youtubeKey = "";
        private string kickKey = "";
        private int localPort = 1935;
        private string streamKey = "live";
        
        public MainForm()
        {
            InitializeComponent();
            LoadConfiguration();
            SetupUI();
        }
        
        private void InitializeComponent()
        {
            this.SuspendLayout();
            
            // Form properties
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(600, 500);
            this.Text = "StreamRelay - Multi-Platform Streaming";
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;
            
            // Title Label
            var titleLabel = new Label
            {
                Text = "🎥 StreamRelay - Multi-Platform Streaming",
                Font = new Font("Segoe UI", 16, FontStyle.Bold),
                ForeColor = Color.FromArgb(0, 122, 255),
                Location = new Point(20, 20),
                Size = new Size(560, 35),
                TextAlign = ContentAlignment.MiddleCenter
            };
            this.Controls.Add(titleLabel);
            
            // Stream Keys Group
            var keysGroup = new GroupBox
            {
                Text = "Stream Keys Configuration",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.White,
                Location = new Point(20, 70),
                Size = new Size(560, 180),
                BackColor = Color.FromArgb(55, 55, 58)
            };
            
            // Twitch Key
            var twitchLabel = new Label
            {
                Text = "Twitch Stream Key:",
                Location = new Point(15, 30),
                Size = new Size(120, 23),
                ForeColor = Color.FromArgb(169, 112, 255)
            };
            var twitchTextBox = new TextBox
            {
                Name = "twitchKey",
                Location = new Point(140, 27),
                Size = new Size(300, 23),
                BackColor = Color.FromArgb(69, 69, 69),
                ForeColor = Color.White,
                UseSystemPasswordChar = true
            };
            var twitchShowBtn = new Button
            {
                Text = "👁",
                Location = new Point(450, 27),
                Size = new Size(30, 23),
                BackColor = Color.FromArgb(0, 122, 255),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            twitchShowBtn.Click += (s, e) => TogglePasswordChar(twitchTextBox);
            
            // YouTube Key
            var youtubeLabel = new Label
            {
                Text = "YouTube Stream Key:",
                Location = new Point(15, 70),
                Size = new Size(120, 23),
                ForeColor = Color.FromArgb(255, 0, 0)
            };
            var youtubeTextBox = new TextBox
            {
                Name = "youtubeKey",
                Location = new Point(140, 67),
                Size = new Size(300, 23),
                BackColor = Color.FromArgb(69, 69, 69),
                ForeColor = Color.White,
                UseSystemPasswordChar = true
            };
            var youtubeShowBtn = new Button
            {
                Text = "👁",
                Location = new Point(450, 67),
                Size = new Size(30, 23),
                BackColor = Color.FromArgb(0, 122, 255),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            youtubeShowBtn.Click += (s, e) => TogglePasswordChar(youtubeTextBox);
            
            // Kick Key
            var kickLabel = new Label
            {
                Text = "Kick Stream Key:",
                Location = new Point(15, 110),
                Size = new Size(120, 23),
                ForeColor = Color.FromArgb(83, 255, 26)
            };
            var kickTextBox = new TextBox
            {
                Name = "kickKey",
                Location = new Point(140, 107),
                Size = new Size(300, 23),
                BackColor = Color.FromArgb(69, 69, 69),
                ForeColor = Color.White,
                UseSystemPasswordChar = true
            };
            var kickShowBtn = new Button
            {
                Text = "👁",
                Location = new Point(450, 107),
                Size = new Size(30, 23),
                BackColor = Color.FromArgb(0, 122, 255),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            kickShowBtn.Click += (s, e) => TogglePasswordChar(kickTextBox);
            
            // Save Keys Button
            var saveKeysBtn = new Button
            {
                Text = "💾 Save Keys",
                Location = new Point(490, 140),
                Size = new Size(60, 30),
                BackColor = Color.FromArgb(0, 122, 255),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            saveKeysBtn.Click += SaveKeys_Click;
            
            keysGroup.Controls.AddRange(new Control[] {
                twitchLabel, twitchTextBox, twitchShowBtn,
                youtubeLabel, youtubeTextBox, youtubeShowBtn,
                kickLabel, kickTextBox, kickShowBtn,
                saveKeysBtn
            });
            this.Controls.Add(keysGroup);
            
            // OBS Configuration Group
            var obsGroup = new GroupBox
            {
                Text = "OBS Configuration",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.White,
                Location = new Point(20, 270),
                Size = new Size(560, 80),
                BackColor = Color.FromArgb(55, 55, 58)
            };
            
            var obsLabel = new Label
            {
                Text = "RTMP URL for OBS:",
                Location = new Point(15, 30),
                Size = new Size(120, 23),
                ForeColor = Color.White
            };
            var obsUrlTextBox = new TextBox
            {
                Name = "obsUrl",
                Text = $"rtmp://localhost:{localPort}/live",
                Location = new Point(140, 27),
                Size = new Size(250, 23),
                BackColor = Color.FromArgb(69, 69, 69),
                ForeColor = Color.White,
                ReadOnly = true
            };
            var copyUrlBtn = new Button
            {
                Text = "📋 Copy",
                Location = new Point(400, 27),
                Size = new Size(60, 23),
                BackColor = Color.FromArgb(0, 122, 255),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            copyUrlBtn.Click += (s, e) => Clipboard.SetText(obsUrlTextBox.Text);
            
            var streamKeyLabel = new Label
            {
                Text = "Stream Key: live",
                Location = new Point(470, 30),
                Size = new Size(80, 23),
                ForeColor = Color.FromArgb(0, 255, 127)
            };
            
            obsGroup.Controls.AddRange(new Control[] {
                obsLabel, obsUrlTextBox, copyUrlBtn, streamKeyLabel
            });
            this.Controls.Add(obsGroup);
            
            // Control Buttons
            var startBtn = new Button
            {
                Name = "startBtn",
                Text = "🚀 Start Streaming",
                Location = new Point(50, 370),
                Size = new Size(150, 40),
                BackColor = Color.FromArgb(0, 255, 127),
                ForeColor = Color.Black,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                FlatStyle = FlatStyle.Flat
            };
            startBtn.Click += StartStreaming_Click;
            
            var stopBtn = new Button
            {
                Name = "stopBtn",
                Text = "⏹ Stop Streaming",
                Location = new Point(220, 370),
                Size = new Size(150, 40),
                BackColor = Color.FromArgb(255, 69, 58),
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                FlatStyle = FlatStyle.Flat,
                Enabled = false
            };
            stopBtn.Click += StopStreaming_Click;
            
            var statusLabel = new Label
            {
                Name = "statusLabel",
                Text = "Status: Ready",
                Location = new Point(400, 380),
                Size = new Size(150, 23),
                ForeColor = Color.FromArgb(0, 255, 127),
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            
            this.Controls.AddRange(new Control[] { startBtn, stopBtn, statusLabel });
            
            // Instructions
            var instructionsLabel = new Label
            {
                Text = "Instructions: 1) Enter your stream keys 2) Click 'Start Streaming' 3) Set OBS to the RTMP URL above with stream key 'live'",
                Location = new Point(20, 430),
                Size = new Size(560, 40),
                ForeColor = Color.FromArgb(255, 214, 10),
                Font = new Font("Segoe UI", 9),
                TextAlign = ContentAlignment.MiddleLeft
            };
            this.Controls.Add(instructionsLabel);
            
            this.ResumeLayout(false);
        }
        
        private void SetupUI()
        {
            // Load saved keys
            var twitchBox = this.Controls.Find("twitchKey", true)[0] as TextBox;
            var youtubeBox = this.Controls.Find("youtubeKey", true)[0] as TextBox;
            var kickBox = this.Controls.Find("kickKey", true)[0] as TextBox;
            
            if (twitchBox != null) twitchBox.Text = twitchKey;
            if (youtubeBox != null) youtubeBox.Text = youtubeKey;
            if (kickBox != null) kickBox.Text = kickKey;
        }
        
        private void TogglePasswordChar(TextBox textBox)
        {
            textBox.UseSystemPasswordChar = !textBox.UseSystemPasswordChar;
        }
        
        private void SaveKeys_Click(object sender, EventArgs e)
        {
            var twitchBox = this.Controls.Find("twitchKey", true)[0] as TextBox;
            var youtubeBox = this.Controls.Find("youtubeKey", true)[0] as TextBox;
            var kickBox = this.Controls.Find("kickKey", true)[0] as TextBox;
            
            twitchKey = twitchBox?.Text ?? "";
            youtubeKey = youtubeBox?.Text ?? "";
            kickKey = kickBox?.Text ?? "";
            
            SaveConfiguration();
            MessageBox.Show("Stream keys saved successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        
        private void StartStreaming_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(twitchKey) && string.IsNullOrEmpty(youtubeKey) && string.IsNullOrEmpty(kickKey))
            {
                MessageBox.Show("Please configure at least one stream key before starting.", "Configuration Required", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            
            try
            {
                StartRTMPServer();
                isStreaming = true;
                
                var startBtn = this.Controls.Find("startBtn", true)[0] as Button;
                var stopBtn = this.Controls.Find("stopBtn", true)[0] as Button;
                var statusLabel = this.Controls.Find("statusLabel", true)[0] as Label;
                
                if (startBtn != null) startBtn.Enabled = false;
                if (stopBtn != null) stopBtn.Enabled = true;
                if (statusLabel != null)
                {
                    statusLabel.Text = "Status: Streaming";
                    statusLabel.ForeColor = Color.FromArgb(0, 255, 127);
                }
                
                MessageBox.Show("Streaming started! Configure OBS with the RTMP URL shown above.", "Streaming Started", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to start streaming: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private void StopStreaming_Click(object sender, EventArgs e)
        {
            try
            {
                StopRTMPServer();
                isStreaming = false;
                
                var startBtn = this.Controls.Find("startBtn", true)[0] as Button;
                var stopBtn = this.Controls.Find("stopBtn", true)[0] as Button;
                var statusLabel = this.Controls.Find("statusLabel", true)[0] as Label;
                
                if (startBtn != null) startBtn.Enabled = true;
                if (stopBtn != null) stopBtn.Enabled = false;
                if (statusLabel != null)
                {
                    statusLabel.Text = "Status: Stopped";
                    statusLabel.ForeColor = Color.FromArgb(255, 69, 58);
                }
                
                MessageBox.Show("Streaming stopped.", "Streaming Stopped", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error stopping streaming: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private void StartRTMPServer()
        {
            // Create nginx configuration
            string configPath = Path.Combine(Application.StartupPath, "nginx.conf");
            CreateNginxConfig(configPath);
            
            // Start nginx process
            string nginxPath = Path.Combine(Application.StartupPath, "nginx", "nginx.exe");
            
            if (!File.Exists(nginxPath))
            {
                throw new FileNotFoundException("Nginx executable not found. Please ensure nginx is installed in the application directory.");
            }
            
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = nginxPath,
                Arguments = $"-c \"{configPath}\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            
            rtmpProcess = Process.Start(startInfo);
            
            // Start monitoring thread
            cancellationTokenSource = new CancellationTokenSource();
            monitorThread = new Thread(() => MonitorStreaming(cancellationTokenSource.Token));
            monitorThread.Start();
        }
        
        private void StopRTMPServer()
        {
            cancellationTokenSource?.Cancel();
            
            if (rtmpProcess != null && !rtmpProcess.HasExited)
            {
                rtmpProcess.Kill();
                rtmpProcess.WaitForExit(5000);
                rtmpProcess.Dispose();
                rtmpProcess = null;
            }
            
            monitorThread?.Join(2000);
        }
        
        private void CreateNginxConfig(string configPath)
        {
            var config = new StringBuilder();
            config.AppendLine("worker_processes 1;");
            config.AppendLine("events { worker_connections 1024; }");
            config.AppendLine();
            config.AppendLine("rtmp {");
            config.AppendLine("    server {");
            config.AppendLine($"        listen {localPort};");
            config.AppendLine("        chunk_size 4096;");
            config.AppendLine("        allow publish all;");
            config.AppendLine("        allow play all;");
            config.AppendLine();
            config.AppendLine("        application live {");
            config.AppendLine("            live on;");
            config.AppendLine("            record off;");
            config.AppendLine();
            
            // Add platform pushes
            if (!string.IsNullOrEmpty(twitchKey))
            {
                config.AppendLine("            push rtmp://localhost/twitch;");
            }
            if (!string.IsNullOrEmpty(youtubeKey))
            {
                config.AppendLine("            push rtmp://localhost/youtube;");
            }
            if (!string.IsNullOrEmpty(kickKey))
            {
                config.AppendLine("            push rtmp://localhost/kick;");
            }
            
            config.AppendLine("        }");
            config.AppendLine();
            
            // Platform-specific applications
            if (!string.IsNullOrEmpty(twitchKey))
            {
                config.AppendLine("        application twitch {");
                config.AppendLine("            live on;");
                config.AppendLine("            record off;");
                config.AppendLine("            allow publish 127.0.0.1;");
                config.AppendLine("            deny publish all;");
                config.AppendLine();
                config.AppendLine($"            exec ffmpeg -i rtmp://localhost/twitch/$name");
                config.AppendLine("                -c:v libx264 -preset veryfast -tune zerolatency");
                config.AppendLine("                -b:v 6000k -maxrate 6000k -bufsize 6000k");
                config.AppendLine("                -pix_fmt yuv420p -g 50 -r 30");
                config.AppendLine("                -c:a aac -b:a 160k -ar 44100 -ac 2");
                config.AppendLine($"                -f flv rtmp://live.twitch.tv/app/{twitchKey};");
                config.AppendLine("        }");
                config.AppendLine();
            }
            
            if (!string.IsNullOrEmpty(youtubeKey))
            {
                config.AppendLine("        application youtube {");
                config.AppendLine("            live on;");
                config.AppendLine("            record off;");
                config.AppendLine("            allow publish 127.0.0.1;");
                config.AppendLine("            deny publish all;");
                config.AppendLine();
                config.AppendLine($"            exec ffmpeg -i rtmp://localhost/youtube/$name");
                config.AppendLine("                -c:v libx264 -preset veryfast -tune zerolatency");
                config.AppendLine("                -b:v 12000k -maxrate 12000k -bufsize 12000k");
                config.AppendLine("                -pix_fmt yuv420p -g 50 -r 30");
                config.AppendLine("                -c:a aac -b:a 160k -ar 44100 -ac 2");
                config.AppendLine($"                -f flv rtmp://a.rtmp.youtube.com/live2/{youtubeKey};");
                config.AppendLine("        }");
                config.AppendLine();
            }
            
            if (!string.IsNullOrEmpty(kickKey))
            {
                config.AppendLine("        application kick {");
                config.AppendLine("            live on;");
                config.AppendLine("            record off;");
                config.AppendLine("            allow publish 127.0.0.1;");
                config.AppendLine("            deny publish all;");
                config.AppendLine();
                config.AppendLine($"            exec ffmpeg -i rtmp://localhost/kick/$name");
                config.AppendLine("                -c:v libx264 -preset veryfast -tune zerolatency");
                config.AppendLine("                -b:v 10000k -maxrate 10000k -bufsize 10000k");
                config.AppendLine("                -pix_fmt yuv420p -g 50 -r 30");
                config.AppendLine("                -c:a aac -b:a 160k -ar 44100 -ac 2");
                config.AppendLine($"                -f flv rtmp://ingest.kick.com/live/{kickKey};");
                config.AppendLine("        }");
                config.AppendLine();
            }
            
            config.AppendLine("    }");
            config.AppendLine("}");
            
            File.WriteAllText(configPath, config.ToString());
        }
        
        private void MonitorStreaming(CancellationToken cancellationToken)
        {
            while (!cancellationToken.IsCancellationRequested && isStreaming)
            {
                Thread.Sleep(5000);
                
                // Check if nginx process is still running
                if (rtmpProcess != null && rtmpProcess.HasExited)
                {
                    this.Invoke(new Action(() =>
                    {
                        var statusLabel = this.Controls.Find("statusLabel", true)[0] as Label;
                        if (statusLabel != null)
                        {
                            statusLabel.Text = "Status: Error";
                            statusLabel.ForeColor = Color.FromArgb(255, 69, 58);
                        }
                        MessageBox.Show("Streaming process has stopped unexpectedly.", "Streaming Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }));
                    break;
                }
            }
        }
        
        private void LoadConfiguration()
        {
            try
            {
                string configPath = Path.Combine(Application.StartupPath, "streamrelay.config");
                if (File.Exists(configPath))
                {
                    var lines = File.ReadAllLines(configPath);
                    foreach (var line in lines)
                    {
                        var parts = line.Split('=');
                        if (parts.Length == 2)
                        {
                            switch (parts[0].Trim())
                            {
                                case "TwitchKey":
                                    twitchKey = parts[1].Trim();
                                    break;
                                case "YouTubeKey":
                                    youtubeKey = parts[1].Trim();
                                    break;
                                case "KickKey":
                                    kickKey = parts[1].Trim();
                                    break;
                                case "LocalPort":
                                    int.TryParse(parts[1].Trim(), out localPort);
                                    break;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading configuration: {ex.Message}", "Configuration Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        
        private void SaveConfiguration()
        {
            try
            {
                string configPath = Path.Combine(Application.StartupPath, "streamrelay.config");
                var config = new StringBuilder();
                config.AppendLine($"TwitchKey={twitchKey}");
                config.AppendLine($"YouTubeKey={youtubeKey}");
                config.AppendLine($"KickKey={kickKey}");
                config.AppendLine($"LocalPort={localPort}");
                
                File.WriteAllText(configPath, config.ToString());
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving configuration: {ex.Message}", "Configuration Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        
        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (isStreaming)
            {
                StopRTMPServer();
            }
            base.OnFormClosing(e);
        }
    }
    
    public class Program
    {
        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}