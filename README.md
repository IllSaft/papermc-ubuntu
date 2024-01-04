
# 🌟 MC4ALL PaperMC Server Management Script 🌟

## 🚀 Introduction
🔹 **The MC4ALL PaperMC Server Management Script** is a versatile **Bash script** designed for managing a Minecraft server powered by PaperMC. This script offers an automated approach to handling server startup, updating builds, and integrating with `systemd` for consistent and reliable server management.

## 🌈 Features
- **🔥 Automatic Server Startup**: Seamlessly start the PaperMC server either manually or as a `systemd` service.
- **🛠 Build Management**: Easy updating to the latest build or a specific build number of PaperMC.
- **📜 EULA Management**: Automatic prompting for Minecraft EULA acceptance to ensure compliance.
- **📊 Logging**: Detailed logging for server actions, aiding in troubleshooting and monitoring.
- **💻 Screen Session Management**: Utilizes `screen` for running the server in the background and allowing easy attachment/detachment.

## 📌 Prerequisites
- A Linux environment.
- `bash`, `curl`, `jq`, `screen`, and `systemd` must be installed.
- Java installed (Java 21 recommended).
- Access to the terminal with permissions to create `systemd` services.

## 🛠️ Installation
1. **🌐 Clone the repository**:

```bash
git clone https://github.com/yourusername/mc4all-papermc-server.git
cd mc4all-papermc-server
```

2. **🔑 Set execute permissions for the main script**:

```bash
chmod +x main.sh
```

## 🚀 Usage

### ✨ Starting the Server Manually
- Run the script without any arguments to start the server manually with the latest PaperMC build:

```bash
./main.sh
```

- To start the server with a specific build:

```bash
./main.sh 365 # Replace '365' with the desired build number
```

### 🔄 Using Systemd for Automatic Startup
- To enable automatic startup with `systemd`, edit the `settings.cfg` file and set `SYSTEMCTL_AUTO_START=true`. Then, run the script normally. The script will configure and start a `systemd` service for your PaperMC server.

### 💻 Attaching to the Server Console
- If the server is running in a `screen` session, you can attach to the session using:

```bash
screen -r MC4ALL
```

- To detach from the screen session and leave the server running in the background, press `Ctrl+A` followed by `D`.

### 🛑 Stopping the Server
- To stop the server when running under `systemd`, use:

```bash
sudo systemctl stop mc4all-server
```

### 🆕 Updating the Server
- To update to the latest build, simply restart the server script. It checks for the latest build and updates if necessary.

## ⚙️ Configuration
- Configuration parameters like server directory, session name, Java options, and others can be adjusted in the `settings.cfg` file.

## 📚 Logs
- Logs are stored in the `logs` directory, providing detailed information about server operations and aiding in troubleshooting.

## 👥 Contributing
- Contributions to the script are welcome. Please follow the standard Git workflow - fork the repository, make your changes, and submit a pull request.

## 📜 License
- This project is licensed under the [MIT License](LICENSE).

## 📞 Support
- For support and inquiries, create an issue in the GitHub repository, and we will assist you promptly.

---

🚨 **Important Note**: This script is designed for server administrators with basic knowledge of Linux and Minecraft server operations. Always back up your server data before making significant changes.
