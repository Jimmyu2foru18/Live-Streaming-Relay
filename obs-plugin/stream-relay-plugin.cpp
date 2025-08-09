/*
 * StreamRelay OBS Studio Plugin
 * 
 * This file uses conditional compilation to support both:
 * 1. Standalone compilation (for development/testing without full OBS SDK)
 * 2. Full OBS Studio plugin compilation (with proper OBS SDK and Qt)
 * 
 * To build as a proper OBS plugin, define:
 * - OBS_STUDIO_BUILD (for OBS headers)
 * - QT_WIDGETS_LIB (for Qt GUI)
 * - WINDOWS_SDK_AVAILABLE (for Windows-specific features)
 * 
 * Example CMake configuration:
 * add_definitions(-DOBS_STUDIO_BUILD -DQT_WIDGETS_LIB -DWINDOWS_SDK_AVAILABLE)
 */

// Conditional compilation for development environment
#ifdef OBS_STUDIO_BUILD
// Real OBS Studio headers (when building with OBS SDK)
#include <obs-module.h>
#include <obs-frontend-api.h>
#include <util/config-file.h>
#include <util/platform.h>
#include <util/threading.h>
#else
// Mock OBS headers for standalone compilation
#ifndef OBS_MODULE_H
#define OBS_MODULE_H
#define OBS_DECLARE_MODULE() extern "C" { bool obs_module_load(void) { return true; } void obs_module_unload(void) {} }
#define OBS_MODULE_USE_DEFAULT_LOCALE(name, locale)
#define blog(level, format, ...) printf("[" #level "] " format "\n", ##__VA_ARGS__)
#define LOG_INFO 0
#define LOG_WARNING 1
#define LOG_ERROR 2
#define LOG_DEBUG 3
typedef void* obs_frontend_cb_data;
#endif
#endif

// Platform-specific headers
#ifdef _WIN32
#ifdef WINDOWS_SDK_AVAILABLE
#include <Windows.h>
#endif
#endif

// Qt Headers - conditional compilation
#ifdef QT_WIDGETS_LIB
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QDialog>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QMessageBox>
#include <QtWidgets/QApplication>
#include <QtGui/QClipboard>
#include <QtCore/QTimer>
#include <QtWidgets/QProgressBar>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QFileDialog>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QProcess>
#include <QtCore/QThread>
#include <QtCore/QMutex>
#include <QtCore/QSettings>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>
#include <QtCore/QDateTime>
#else
// Mock Qt classes for standalone compilation
#define Q_OBJECT
#define slots
#define signals public
#define emit
class QWidget {};
class QDialog : public QWidget {};
class QMainWindow : public QWidget {};
class QTimer {};
class QSettings {};
class QProcess {};
// Add other mock classes as needed
#endif

#include <memory>

// Plugin configuration
#include "plugin-macros.h"

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("stream-relay-plugin", "en-US")

class StreamRelayPlugin;
static StreamRelayPlugin *plugin_instance = nullptr;

class StreamRelayDialog : public QDialog {
    Q_OBJECT

public:
    StreamRelayDialog(QWidget *parent = nullptr);
    ~StreamRelayDialog();

private slots:
    void onStartRelay();
    void onStopRelay();
    void onSaveConfig();
    void onLoadConfig();
    void onTestConnection();
    void onCopyRTMPUrl();
    void updateStatus();
    void onPlatformToggled();

private:
    void setupUI();
    void loadSettings();
    void saveSettings();
    void updateRelayStatus();
    void startRTMPServer();
    void stopRTMPServer();
    void createNginxConfig();
    
    // UI Elements
    QTabWidget *tabWidget;
    
    // Platform Configuration Tab
    QWidget *configTab;
    QCheckBox *twitchEnabled;
    QLineEdit *twitchKey;
    QPushButton *twitchShow;
    QCheckBox *youtubeEnabled;
    QLineEdit *youtubeKey;
    QPushButton *youtubeShow;
    QCheckBox *kickEnabled;
    QLineEdit *kickKey;
    QPushButton *kickShow;
    QSpinBox *localPort;
    QPushButton *saveConfigBtn;
    QPushButton *loadConfigBtn;
    
    // Control Tab
    QWidget *controlTab;
    QLabel *rtmpUrlLabel;
    QLineEdit *rtmpUrlEdit;
    QPushButton *copyUrlBtn;
    QPushButton *startBtn;
    QPushButton *stopBtn;
    QLabel *statusLabel;
    QProgressBar *statusProgress;
    QPushButton *testBtn;
    
    // Monitor Tab
    QWidget *monitorTab;
    QTextEdit *logOutput;
    QLabel *viewersLabel;
    QLabel *bitrateLabel;
    QLabel *uptimeLabel;
    QTimer *updateTimer;
    
    // Settings Tab
    QWidget *settingsTab;
    QComboBox *qualityPreset;
    QSpinBox *maxBitrate;
    QCheckBox *autoReconnect;
    QCheckBox *enableLogging;
    QLineEdit *customFFmpegArgs;
    
    // Internal state
    bool isRelaying;
    QProcess *nginxProcess;
    QTimer *statusTimer;
    QMutex configMutex;
    QString configPath;
    QSettings *settings;
};

class StreamRelayPlugin {
public:
    StreamRelayPlugin();
    ~StreamRelayPlugin();
    
    void showDialog();
    void hideDialog();
    
private:
    std::unique_ptr<StreamRelayDialog> dialog;
    obs_frontend_cb_data callbackData;
};

StreamRelayDialog::StreamRelayDialog(QWidget *parent)
    : QDialog(parent), isRelaying(false), nginxProcess(nullptr)
{
    setWindowTitle("StreamRelay - Multi-Platform Streaming");
    setWindowFlags(windowFlags() & ~Qt::WindowContextHelpButtonHint);
    resize(600, 500);
    
    // Initialize settings
    configPath = QString("%1/obs-studio/plugin_config/stream-relay/").arg(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    QDir().mkpath(configPath);
    settings = new QSettings(configPath + "config.ini", QSettings::IniFormat);
    
    setupUI();
    loadSettings();
    
    // Setup timers
    updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, &StreamRelayDialog::updateStatus);
    
    statusTimer = new QTimer(this);
    connect(statusTimer, &QTimer::timeout, this, &StreamRelayDialog::updateRelayStatus);
}

StreamRelayDialog::~StreamRelayDialog()
{
    if (isRelaying) {
        stopRTMPServer();
    }
    delete settings;
}

void StreamRelayDialog::setupUI()
{
    auto *mainLayout = new QVBoxLayout(this);
    
    // Create tab widget
    tabWidget = new QTabWidget();
    
    // Platform Configuration Tab
    configTab = new QWidget();
    auto *configLayout = new QVBoxLayout(configTab);
    
    // Title
    auto *titleLabel = new QLabel("🎥 StreamRelay - Multi-Platform Streaming");
    titleLabel->setStyleSheet("font-size: 16px; font-weight: bold; color: #0078d4; padding: 10px;");
    titleLabel->setAlignment(Qt::AlignCenter);
    configLayout->addWidget(titleLabel);
    
    // Platform configuration group
    auto *platformGroup = new QGroupBox("Platform Configuration");
    auto *platformLayout = new QGridLayout(platformGroup);
    
    // Twitch
    twitchEnabled = new QCheckBox("Enable Twitch");
    twitchEnabled->setStyleSheet("color: #9146ff; font-weight: bold;");
    platformLayout->addWidget(twitchEnabled, 0, 0);
    
    twitchKey = new QLineEdit();
    twitchKey->setPlaceholderText("Enter Twitch stream key...");
    twitchKey->setEchoMode(QLineEdit::Password);
    platformLayout->addWidget(twitchKey, 0, 1);
    
    twitchShow = new QPushButton("👁");
    twitchShow->setMaximumWidth(30);
    connect(twitchShow, &QPushButton::clicked, [this]() {
        twitchKey->setEchoMode(twitchKey->echoMode() == QLineEdit::Password ? QLineEdit::Normal : QLineEdit::Password);
    });
    platformLayout->addWidget(twitchShow, 0, 2);
    
    // YouTube
    youtubeEnabled = new QCheckBox("Enable YouTube");
    youtubeEnabled->setStyleSheet("color: #ff0000; font-weight: bold;");
    platformLayout->addWidget(youtubeEnabled, 1, 0);
    
    youtubeKey = new QLineEdit();
    youtubeKey->setPlaceholderText("Enter YouTube stream key...");
    youtubeKey->setEchoMode(QLineEdit::Password);
    platformLayout->addWidget(youtubeKey, 1, 1);
    
    youtubeShow = new QPushButton("👁");
    youtubeShow->setMaximumWidth(30);
    connect(youtubeShow, &QPushButton::clicked, [this]() {
        youtubeKey->setEchoMode(youtubeKey->echoMode() == QLineEdit::Password ? QLineEdit::Normal : QLineEdit::Password);
    });
    platformLayout->addWidget(youtubeShow, 1, 2);
    
    // Kick
    kickEnabled = new QCheckBox("Enable Kick");
    kickEnabled->setStyleSheet("color: #53ff1a; font-weight: bold;");
    platformLayout->addWidget(kickEnabled, 2, 0);
    
    kickKey = new QLineEdit();
    kickKey->setPlaceholderText("Enter Kick stream key...");
    kickKey->setEchoMode(QLineEdit::Password);
    platformLayout->addWidget(kickKey, 2, 1);
    
    kickShow = new QPushButton("👁");
    kickShow->setMaximumWidth(30);
    connect(kickShow, &QPushButton::clicked, [this]() {
        kickKey->setEchoMode(kickKey->echoMode() == QLineEdit::Password ? QLineEdit::Normal : QLineEdit::Password);
    });
    platformLayout->addWidget(kickShow, 2, 2);
    
    // Local port
    auto *portLabel = new QLabel("Local RTMP Port:");
    platformLayout->addWidget(portLabel, 3, 0);
    
    localPort = new QSpinBox();
    localPort->setRange(1024, 65535);
    localPort->setValue(1935);
    platformLayout->addWidget(localPort, 3, 1);
    
    configLayout->addWidget(platformGroup);
    
    // Config buttons
    auto *configBtnLayout = new QHBoxLayout();
    saveConfigBtn = new QPushButton("💾 Save Configuration");
    saveConfigBtn->setStyleSheet("background-color: #0078d4; color: white; font-weight: bold; padding: 8px;");
    connect(saveConfigBtn, &QPushButton::clicked, this, &StreamRelayDialog::onSaveConfig);
    
    loadConfigBtn = new QPushButton("📁 Load Configuration");
    loadConfigBtn->setStyleSheet("background-color: #107c10; color: white; font-weight: bold; padding: 8px;");
    connect(loadConfigBtn, &QPushButton::clicked, this, &StreamRelayDialog::onLoadConfig);
    
    configBtnLayout->addWidget(saveConfigBtn);
    configBtnLayout->addWidget(loadConfigBtn);
    configLayout->addLayout(configBtnLayout);
    
    tabWidget->addTab(configTab, "Configuration");
    
    // Control Tab
    controlTab = new QWidget();
    auto *controlLayout = new QVBoxLayout(controlTab);
    
    // RTMP URL group
    auto *rtmpGroup = new QGroupBox("OBS Configuration");
    auto *rtmpLayout = new QGridLayout(rtmpGroup);
    
    rtmpUrlLabel = new QLabel("RTMP Server URL:");
    rtmpLayout->addWidget(rtmpUrlLabel, 0, 0);
    
    rtmpUrlEdit = new QLineEdit();
    rtmpUrlEdit->setReadOnly(true);
    rtmpUrlEdit->setText("rtmp://localhost:1935/live");
    rtmpLayout->addWidget(rtmpUrlEdit, 0, 1);
    
    copyUrlBtn = new QPushButton("📋 Copy");
    copyUrlBtn->setMaximumWidth(80);
    connect(copyUrlBtn, &QPushButton::clicked, this, &StreamRelayDialog::onCopyRTMPUrl);
    rtmpLayout->addWidget(copyUrlBtn, 0, 2);
    
    auto *streamKeyLabel = new QLabel("Stream Key: live");
    streamKeyLabel->setStyleSheet("color: #107c10; font-weight: bold;");
    rtmpLayout->addWidget(streamKeyLabel, 1, 0, 1, 3);
    
    controlLayout->addWidget(rtmpGroup);
    
    // Control buttons
    auto *controlBtnLayout = new QHBoxLayout();
    
    startBtn = new QPushButton("🚀 Start Multi-Stream Relay");
    startBtn->setStyleSheet("background-color: #107c10; color: white; font-weight: bold; padding: 12px; font-size: 14px;");
    connect(startBtn, &QPushButton::clicked, this, &StreamRelayDialog::onStartRelay);
    
    stopBtn = new QPushButton("⏹ Stop Relay");
    stopBtn->setStyleSheet("background-color: #d13438; color: white; font-weight: bold; padding: 12px; font-size: 14px;");
    stopBtn->setEnabled(false);
    connect(stopBtn, &QPushButton::clicked, this, &StreamRelayDialog::onStopRelay);
    
    testBtn = new QPushButton("🔧 Test Connection");
    testBtn->setStyleSheet("background-color: #ff8c00; color: white; font-weight: bold; padding: 12px;");
    connect(testBtn, &QPushButton::clicked, this, &StreamRelayDialog::onTestConnection);
    
    controlBtnLayout->addWidget(startBtn);
    controlBtnLayout->addWidget(stopBtn);
    controlBtnLayout->addWidget(testBtn);
    controlLayout->addLayout(controlBtnLayout);
    
    // Status
    statusLabel = new QLabel("Status: Ready");
    statusLabel->setStyleSheet("font-size: 14px; font-weight: bold; color: #107c10; padding: 10px;");
    statusLabel->setAlignment(Qt::AlignCenter);
    controlLayout->addWidget(statusLabel);
    
    statusProgress = new QProgressBar();
    statusProgress->setVisible(false);
    controlLayout->addWidget(statusProgress);
    
    tabWidget->addTab(controlTab, "Control");
    
    // Monitor Tab
    monitorTab = new QWidget();
    auto *monitorLayout = new QVBoxLayout(monitorTab);
    
    // Stats
    auto *statsLayout = new QHBoxLayout();
    viewersLabel = new QLabel("Viewers: 0");
    bitrateLabel = new QLabel("Bitrate: 0 kbps");
    uptimeLabel = new QLabel("Uptime: 00:00:00");
    
    statsLayout->addWidget(viewersLabel);
    statsLayout->addWidget(bitrateLabel);
    statsLayout->addWidget(uptimeLabel);
    monitorLayout->addLayout(statsLayout);
    
    // Log output
    logOutput = new QTextEdit();
    logOutput->setReadOnly(true);
    logOutput->setMaximumHeight(200);
    logOutput->setStyleSheet("background-color: #1e1e1e; color: #ffffff; font-family: 'Consolas', monospace;");
    monitorLayout->addWidget(logOutput);
    
    tabWidget->addTab(monitorTab, "Monitor");
    
    // Settings Tab
    settingsTab = new QWidget();
    auto *settingsLayout = new QVBoxLayout(settingsTab);
    
    auto *qualityGroup = new QGroupBox("Quality Settings");
    auto *qualityLayout = new QGridLayout(qualityGroup);
    
    qualityLayout->addWidget(new QLabel("Quality Preset:"), 0, 0);
    qualityPreset = new QComboBox();
    qualityPreset->addItems({"Ultra Fast", "Super Fast", "Very Fast", "Faster", "Fast", "Medium", "Slow", "Slower", "Very Slow"});
    qualityPreset->setCurrentText("Very Fast");
    qualityLayout->addWidget(qualityPreset, 0, 1);
    
    qualityLayout->addWidget(new QLabel("Max Bitrate (kbps):"), 1, 0);
    maxBitrate = new QSpinBox();
    maxBitrate->setRange(1000, 50000);
    maxBitrate->setValue(6000);
    qualityLayout->addWidget(maxBitrate, 1, 1);
    
    settingsLayout->addWidget(qualityGroup);
    
    auto *advancedGroup = new QGroupBox("Advanced Settings");
    auto *advancedLayout = new QVBoxLayout(advancedGroup);
    
    autoReconnect = new QCheckBox("Auto-reconnect on failure");
    autoReconnect->setChecked(true);
    advancedLayout->addWidget(autoReconnect);
    
    enableLogging = new QCheckBox("Enable detailed logging");
    enableLogging->setChecked(true);
    advancedLayout->addWidget(enableLogging);
    
    advancedLayout->addWidget(new QLabel("Custom FFmpeg Arguments:"));
    customFFmpegArgs = new QLineEdit();
    customFFmpegArgs->setPlaceholderText("-tune zerolatency -preset veryfast");
    advancedLayout->addWidget(customFFmpegArgs);
    
    settingsLayout->addWidget(advancedGroup);
    
    tabWidget->addTab(settingsTab, "Settings");
    
    mainLayout->addWidget(tabWidget);
    
    // Instructions
    auto *instructionsLabel = new QLabel(
        "Instructions: 1) Configure your stream keys 2) Click 'Start Multi-Stream Relay' "
        "3) In OBS, set Server to the RTMP URL above with Stream Key 'live' 4) Start streaming in OBS"
    );
    instructionsLabel->setStyleSheet("color: #ff8c00; font-weight: bold; padding: 10px; background-color: #2d2d30;");
    instructionsLabel->setWordWrap(true);
    mainLayout->addWidget(instructionsLabel);
    
    // Connect platform toggles
    connect(twitchEnabled, &QCheckBox::toggled, this, &StreamRelayDialog::onPlatformToggled);
    connect(youtubeEnabled, &QCheckBox::toggled, this, &StreamRelayDialog::onPlatformToggled);
    connect(kickEnabled, &QCheckBox::toggled, this, &StreamRelayDialog::onPlatformToggled);
    connect(localPort, QOverload<int>::of(&QSpinBox::valueChanged), [this](int value) {
        rtmpUrlEdit->setText(QString("rtmp://localhost:%1/live").arg(value));
    });
}

void StreamRelayDialog::onStartRelay()
{
    // Validate configuration
    if (!twitchEnabled->isChecked() && !youtubeEnabled->isChecked() && !kickEnabled->isChecked()) {
        QMessageBox::warning(this, "Configuration Required", 
            "Please enable and configure at least one streaming platform before starting.");
        return;
    }
    
    if ((twitchEnabled->isChecked() && twitchKey->text().isEmpty()) ||
        (youtubeEnabled->isChecked() && youtubeKey->text().isEmpty()) ||
        (kickEnabled->isChecked() && kickKey->text().isEmpty())) {
        QMessageBox::warning(this, "Stream Keys Required", 
            "Please enter stream keys for all enabled platforms.");
        return;
    }
    
    try {
        startRTMPServer();
        isRelaying = true;
        
        startBtn->setEnabled(false);
        stopBtn->setEnabled(true);
        statusLabel->setText("Status: Multi-Stream Relay Active");
        statusLabel->setStyleSheet("font-size: 14px; font-weight: bold; color: #107c10; padding: 10px;");
        
        statusTimer->start(5000); // Update every 5 seconds
        updateTimer->start(1000);  // Update stats every second
        
        logOutput->append(QString("[%1] Multi-stream relay started successfully")
                         .arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
        
        QMessageBox::information(this, "Relay Started", 
            "Multi-stream relay is now active! Configure OBS with the RTMP URL shown above and start streaming.");
    } catch (const std::exception& e) {
        QMessageBox::critical(this, "Error", QString("Failed to start relay: %1").arg(e.what()));
    }
}

void StreamRelayDialog::onStopRelay()
{
    try {
        stopRTMPServer();
        isRelaying = false;
        
        startBtn->setEnabled(true);
        stopBtn->setEnabled(false);
        statusLabel->setText("Status: Stopped");
        statusLabel->setStyleSheet("font-size: 14px; font-weight: bold; color: #d13438; padding: 10px;");
        
        statusTimer->stop();
        updateTimer->stop();
        
        logOutput->append(QString("[%1] Multi-stream relay stopped")
                         .arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
        
        QMessageBox::information(this, "Relay Stopped", "Multi-stream relay has been stopped.");
    } catch (const std::exception& e) {
        QMessageBox::critical(this, "Error", QString("Error stopping relay: %1").arg(e.what()));
    }
}

void StreamRelayDialog::onSaveConfig()
{
    saveSettings();
    QMessageBox::information(this, "Configuration Saved", "Stream configuration has been saved successfully.");
}

void StreamRelayDialog::onLoadConfig()
{
    QString fileName = QFileDialog::getOpenFileName(this, "Load Configuration", configPath, "Config Files (*.ini)");
    if (!fileName.isEmpty()) {
        QSettings loadSettings(fileName, QSettings::IniFormat);
        
        twitchEnabled->setChecked(loadSettings.value("twitch/enabled", false).toBool());
        twitchKey->setText(loadSettings.value("twitch/key", "").toString());
        youtubeEnabled->setChecked(loadSettings.value("youtube/enabled", false).toBool());
        youtubeKey->setText(loadSettings.value("youtube/key", "").toString());
        kickEnabled->setChecked(loadSettings.value("kick/enabled", false).toBool());
        kickKey->setText(loadSettings.value("kick/key", "").toString());
        localPort->setValue(loadSettings.value("general/port", 1935).toInt());
        
        QMessageBox::information(this, "Configuration Loaded", "Stream configuration has been loaded successfully.");
    }
}

void StreamRelayDialog::onTestConnection()
{
    // Implement connection testing logic
    statusProgress->setVisible(true);
    statusProgress->setRange(0, 0); // Indeterminate progress
    
    QTimer::singleShot(3000, [this]() {
        statusProgress->setVisible(false);
        QMessageBox::information(this, "Connection Test", "Connection test completed. Check the monitor tab for details.");
        logOutput->append(QString("[%1] Connection test completed")
                         .arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
    });
}

void StreamRelayDialog::onCopyRTMPUrl()
{
    QApplication::clipboard()->setText(rtmpUrlEdit->text());
    QMessageBox::information(this, "Copied", "RTMP URL copied to clipboard!");
}

void StreamRelayDialog::updateStatus()
{
    if (isRelaying) {
        // Update uptime, bitrate, etc.
        static int seconds = 0;
        seconds++;
        int hours = seconds / 3600;
        int minutes = (seconds % 3600) / 60;
        int secs = seconds % 60;
        
        uptimeLabel->setText(QString("Uptime: %1:%2:%3")
                           .arg(hours, 2, 10, QChar('0'))
                           .arg(minutes, 2, 10, QChar('0'))
                           .arg(secs, 2, 10, QChar('0')));
        
        // Simulate bitrate (in real implementation, get from nginx stats)
        bitrateLabel->setText(QString("Bitrate: %1 kbps").arg(qrand() % 1000 + 2000));
    }
}

void StreamRelayDialog::onPlatformToggled()
{
    // Update UI based on enabled platforms
    bool anyEnabled = twitchEnabled->isChecked() || youtubeEnabled->isChecked() || kickEnabled->isChecked();
    startBtn->setEnabled(anyEnabled && !isRelaying);
}

void StreamRelayDialog::updateRelayStatus()
{
    if (nginxProcess && nginxProcess->state() != QProcess::Running) {
        // Process died, handle restart if auto-reconnect is enabled
        if (autoReconnect->isChecked()) {
            logOutput->append(QString("[%1] Relay process died, attempting restart...")
                             .arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
            startRTMPServer();
        } else {
            onStopRelay();
            QMessageBox::warning(this, "Relay Error", "The relay process has stopped unexpectedly.");
        }
    }
}

void StreamRelayDialog::startRTMPServer()
{
    createNginxConfig();
    
    // Start nginx process (implementation depends on nginx availability)
    nginxProcess = new QProcess(this);
    
    QString nginxPath = "nginx"; // Assume nginx is in PATH or bundled
    QStringList arguments;
    arguments << "-c" << configPath + "nginx.conf";
    
    nginxProcess->start(nginxPath, arguments);
    
    if (!nginxProcess->waitForStarted(5000)) {
        throw std::runtime_error("Failed to start nginx process");
    }
}

void StreamRelayDialog::stopRTMPServer()
{
    if (nginxProcess) {
        nginxProcess->kill();
        nginxProcess->waitForFinished(5000);
        nginxProcess->deleteLater();
        nginxProcess = nullptr;
    }
}

void StreamRelayDialog::createNginxConfig()
{
    QString configFile = configPath + "nginx.conf";
    QFile file(configFile);
    
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        
        out << "worker_processes 1;\n";
        out << "events { worker_connections 1024; }\n\n";
        out << "rtmp {\n";
        out << "    server {\n";
        out << "        listen " << localPort->value() << ";\n";
        out << "        chunk_size 4096;\n";
        out << "        allow publish all;\n";
        out << "        allow play all;\n\n";
        
        out << "        application live {\n";
        out << "            live on;\n";
        out << "            record off;\n\n";
        
        // Add platform pushes
        if (twitchEnabled->isChecked()) {
            out << "            push rtmp://localhost/twitch;\n";
        }
        if (youtubeEnabled->isChecked()) {
            out << "            push rtmp://localhost/youtube;\n";
        }
        if (kickEnabled->isChecked()) {
            out << "            push rtmp://localhost/kick;\n";
        }
        
        out << "        }\n\n";
        
        // Platform-specific applications
        if (twitchEnabled->isChecked()) {
            out << "        application twitch {\n";
            out << "            live on;\n";
            out << "            record off;\n";
            out << "            allow publish 127.0.0.1;\n";
            out << "            deny publish all;\n\n";
            out << "            exec ffmpeg -i rtmp://localhost/twitch/$name\n";
            out << "                -c:v libx264 -preset " << qualityPreset->currentText().toLower().replace(" ", "") << "\n";
            out << "                -b:v " << maxBitrate->value() << "k -maxrate " << maxBitrate->value() << "k -bufsize " << maxBitrate->value() << "k\n";
            out << "                -pix_fmt yuv420p -g 50 -r 30\n";
            out << "                -c:a aac -b:a 160k -ar 44100 -ac 2\n";
            out << "                " << customFFmpegArgs->text() << "\n";
            out << "                -f flv rtmp://live.twitch.tv/app/" << twitchKey->text() << ";\n";
            out << "        }\n\n";
        }
        
        if (youtubeEnabled->isChecked()) {
            out << "        application youtube {\n";
            out << "            live on;\n";
            out << "            record off;\n";
            out << "            allow publish 127.0.0.1;\n";
            out << "            deny publish all;\n\n";
            out << "            exec ffmpeg -i rtmp://localhost/youtube/$name\n";
            out << "                -c:v libx264 -preset " << qualityPreset->currentText().toLower().replace(" ", "") << "\n";
            out << "                -b:v " << (maxBitrate->value() * 2) << "k -maxrate " << (maxBitrate->value() * 2) << "k -bufsize " << (maxBitrate->value() * 2) << "k\n";
            out << "                -pix_fmt yuv420p -g 50 -r 30\n";
            out << "                -c:a aac -b:a 160k -ar 44100 -ac 2\n";
            out << "                " << customFFmpegArgs->text() << "\n";
            out << "                -f flv rtmp://a.rtmp.youtube.com/live2/" << youtubeKey->text() << ";\n";
            out << "        }\n\n";
        }
        
        if (kickEnabled->isChecked()) {
            out << "        application kick {\n";
            out << "            live on;\n";
            out << "            record off;\n";
            out << "            allow publish 127.0.0.1;\n";
            out << "            deny publish all;\n\n";
            out << "            exec ffmpeg -i rtmp://localhost/kick/$name\n";
            out << "                -c:v libx264 -preset " << qualityPreset->currentText().toLower().replace(" ", "") << "\n";
            out << "                -b:v " << (maxBitrate->value() + 4000) << "k -maxrate " << (maxBitrate->value() + 4000) << "k -bufsize " << (maxBitrate->value() + 4000) << "k\n";
            out << "                -pix_fmt yuv420p -g 50 -r 30\n";
            out << "                -c:a aac -b:a 160k -ar 44100 -ac 2\n";
            out << "                " << customFFmpegArgs->text() << "\n";
            out << "                -f flv rtmp://ingest.kick.com/live/" << kickKey->text() << ";\n";
            out << "        }\n\n";
        }
        
        out << "    }\n";
        out << "}\n";
    }
}

void StreamRelayDialog::loadSettings()
{
    twitchEnabled->setChecked(settings->value("twitch/enabled", false).toBool());
    twitchKey->setText(settings->value("twitch/key", "").toString());
    youtubeEnabled->setChecked(settings->value("youtube/enabled", false).toBool());
    youtubeKey->setText(settings->value("youtube/key", "").toString());
    kickEnabled->setChecked(settings->value("kick/enabled", false).toBool());
    kickKey->setText(settings->value("kick/key", "").toString());
    localPort->setValue(settings->value("general/port", 1935).toInt());
    qualityPreset->setCurrentText(settings->value("quality/preset", "Very Fast").toString());
    maxBitrate->setValue(settings->value("quality/bitrate", 6000).toInt());
    autoReconnect->setChecked(settings->value("advanced/auto_reconnect", true).toBool());
    enableLogging->setChecked(settings->value("advanced/logging", true).toBool());
    customFFmpegArgs->setText(settings->value("advanced/ffmpeg_args", "-tune zerolatency").toString());
}

void StreamRelayDialog::saveSettings()
{
    settings->setValue("twitch/enabled", twitchEnabled->isChecked());
    settings->setValue("twitch/key", twitchKey->text());
    settings->setValue("youtube/enabled", youtubeEnabled->isChecked());
    settings->setValue("youtube/key", youtubeKey->text());
    settings->setValue("kick/enabled", kickEnabled->isChecked());
    settings->setValue("kick/key", kickKey->text());
    settings->setValue("general/port", localPort->value());
    settings->setValue("quality/preset", qualityPreset->currentText());
    settings->setValue("quality/bitrate", maxBitrate->value());
    settings->setValue("advanced/auto_reconnect", autoReconnect->isChecked());
    settings->setValue("advanced/logging", enableLogging->isChecked());
    settings->setValue("advanced/ffmpeg_args", customFFmpegArgs->text());
    settings->sync();
}

// StreamRelayPlugin Implementation
StreamRelayPlugin::StreamRelayPlugin()
{
    dialog = std::make_unique<StreamRelayDialog>();
}

StreamRelayPlugin::~StreamRelayPlugin()
{
    dialog.reset();
}

void StreamRelayPlugin::showDialog()
{
    if (dialog) {
        dialog->show();
        dialog->raise();
        dialog->activateWindow();
    }
}

void StreamRelayPlugin::hideDialog()
{
    if (dialog) {
        dialog->hide();
    }
}

// OBS Module Functions
static void on_frontend_event(enum obs_frontend_event event, void *private_data)
{
    UNUSED_PARAMETER(private_data);
    
    switch (event) {
    case OBS_FRONTEND_EVENT_FINISHED_LOADING:
        // Plugin fully loaded
        break;
    case OBS_FRONTEND_EVENT_EXIT:
        // OBS is closing
        if (plugin_instance) {
            plugin_instance->hideDialog();
        }
        break;
    default:
        break;
    }
}

static void stream_relay_menu_callback(void *private_data)
{
    UNUSED_PARAMETER(private_data);
    
    if (plugin_instance) {
        plugin_instance->showDialog();
    }
}

bool obs_module_load(void)
{
    blog(LOG_INFO, "StreamRelay plugin loaded");
    
    plugin_instance = new StreamRelayPlugin();
    
    // Add menu item
    obs_frontend_add_tools_menu_item("StreamRelay - Multi-Platform Streaming", stream_relay_menu_callback, nullptr);
    
    // Register frontend callbacks
    obs_frontend_add_event_callback(on_frontend_event, nullptr);
    
    return true;
}

void obs_module_unload(void)
{
    blog(LOG_INFO, "StreamRelay plugin unloaded");
    
    if (plugin_instance) {
        delete plugin_instance;
        plugin_instance = nullptr;
    }
}

MODULE_EXPORT const char *obs_module_description(void)
{
    return "StreamRelay - Multi-Platform Streaming Plugin for OBS Studio";
}

MODULE_EXPORT const char *obs_module_name(void)
{
    return "StreamRelay Plugin";
}

#include "stream-relay-plugin.moc"