#!/bin/bash
set -e

echo "############################################"
echo "# RoboShop Monolith - RHEL 10 Setup Script #"
echo "############################################"

# ---- Prerequisites ----
echo ">> Disabling SELinux and Firewall"
setenforce 0
systemctl stop firewalld
systemctl disable firewalld

# ---- 1. MySQL ----
echo ">> Installing MySQL 8.4"
dnf install -y mysql8.4-server
systemctl enable mysqld
systemctl start mysqld

echo ">> Setting MySQL root password"
mysql -u root -e "
  CREATE USER 'root'@'%' IDENTIFIED BY 'RoboShop@1';
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';
  FLUSH PRIVILEGES;
"

echo ">> Creating roboshop database and user"
mysql -u root -pRoboShop@1 -e "
  CREATE USER IF NOT EXISTS 'roboshop'@'%' IDENTIFIED BY 'RoboShop@1';
  CREATE DATABASE IF NOT EXISTS roboshop;
  GRANT ALL PRIVILEGES ON roboshop.* TO 'roboshop'@'%';
  FLUSH PRIVILEGES;
"

echo ">> Verifying MySQL"
mysql -u roboshop -pRoboShop@1 -e "SHOW DATABASES;"

# ---- 2. Application ----
echo ">> Installing Java 21 and Maven"
dnf install -y java-21-openjdk java-21-openjdk-devel maven unzip
java -version

echo ">> Creating application user and directory"
useradd -r -s /bin/false appuser || true
mkdir -p /app

echo ">> Downloading and building application"
curl -L -o /tmp/roboshop-monolith.zip https://raw.githubusercontent.com/r-devops/roboshop-v3/main/monolith/artifacts/roboshop-monolith.zip
mkdir -p /tmp/roboshop-monolith
cd /tmp/roboshop-monolith
unzip -o /tmp/roboshop-monolith.zip
mvn clean package -DskipTests
cp target/roboshop.war /app/roboshop.war

echo ">> Setting ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R

echo ">> Creating systemd service"
cat > /etc/systemd/system/roboshop.service << 'EOF'
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
EOF

echo ">> Starting application"
systemctl daemon-reload
systemctl enable roboshop
systemctl start roboshop

echo ">> Waiting for Spring Boot to start..."
sleep 30
curl -s http://localhost:8080/health
echo

# ---- 3. Nginx ----
echo ">> Installing Nginx"
dnf install -y nginx
systemctl enable nginx
systemctl start nginx

echo ">> Configuring Nginx"
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    keepalive_timeout   65;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen 80;
        server_name _;

        location /css/ {
            root /usr/share/nginx/html;
            expires 7d;
            add_header Cache-Control "public";
        }

        location /js/ {
            root /usr/share/nginx/html;
            expires 7d;
            add_header Cache-Control "public";
        }

        location /images/ {
            root /usr/share/nginx/html;
            expires 7d;
            add_header Cache-Control "public";
        }

        location / {
            proxy_pass http://localhost:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

echo ">> Copying static assets"
mkdir -p /usr/share/nginx/html/css /usr/share/nginx/html/js /usr/share/nginx/html/images
cp -r /tmp/roboshop-monolith/src/main/resources/static/css/* /usr/share/nginx/html/css/
cp -r /tmp/roboshop-monolith/src/main/resources/static/js/* /usr/share/nginx/html/js/
cp -r /tmp/roboshop-monolith/src/main/resources/static/images/* /usr/share/nginx/html/images/

echo ">> Restarting Nginx"
nginx -t
systemctl restart nginx

echo ""
echo "############################################"
echo "# Setup Complete!                          #"
echo "# Access: http://<SERVER-PUBLIC-IP>        #"
echo "############################################"
