# 02-Application

> **Hint** Developer has chosen Java 21 with Spring Boot 3.2 packaged as a WAR deployed on Tomcat 10. The app auto-creates the DB schema on first run.

> **Dependency** MySQL must be running and accessible before starting the application.

---

## Install

### Java 21

> **Note** The application is developed with Java 21. Install the matching JDK version to build and run it.

```shell
dnf install -y java-21-openjdk java-21-openjdk-devel
java -version
```

### Maven

Install Maven for building the application from source:

```shell
dnf install -y maven
```

### Application User

Create a dedicated system user to run the application process:

```shell
useradd -r -s /bin/false appuser
```

### Application Directory

Create the directory where the built WAR will be placed:

```shell
mkdir -p /app
```

---

## Configure

### Download and Build from Source

Download the source archive, extract it, build the WAR with Maven, and place it in `/app`:

```shell
curl -L -o /tmp/roboshop-monolith.zip https://raw.githubusercontent.com/r-devops/roboshop-v3/main/monolith/artifacts/roboshop-monolith.zip
mkdir -p /tmp/roboshop-monolith
cd /tmp/roboshop-monolith
unzip /tmp/roboshop-monolith.zip
mvn clean package -DskipTests
cp target/roboshop.war /app/roboshop.war
```

### Set Ownership and Permissions

Restrict access to the application directory so only `appuser` can read and execute files:

```shell
chown -R appuser:appuser /app
chmod o-rwx /app -R
```

### Systemd Service

Create the systemd unit file at `/etc/systemd/system/roboshop.service`:

```ini
[Unit]
Description=RoboShop Monolith Application
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=java -jar /app/roboshop.war
Restart=on-failure
RestartSec=10

Environment=SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/roboshop?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
Environment=SPRING_DATASOURCE_USERNAME=roboshop
Environment=SPRING_DATASOURCE_PASSWORD=RoboShop@1
Environment=SERVER_PORT=8080

[Install]
WantedBy=multi-user.target
```

> **Important** Replace `localhost` in `SPRING_DATASOURCE_URL` with the private IP address of the MySQL server if MySQL is running on a separate server (Server 2).

---

## Start

Reload systemd so it picks up the new unit file, then enable and start the service:

```shell
systemctl daemon-reload
systemctl enable roboshop
systemctl start roboshop
```

---

## Verify

Check the service status:

```shell
systemctl status roboshop
```

Follow the live application logs:

```shell
journalctl -u roboshop -f
```

Confirm the application is accepting HTTP requests on port 8080:

```shell
curl http://localhost:8080/health
```

