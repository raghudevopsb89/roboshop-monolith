# 03-Nginx

> **Hint** Nginx serves static assets (CSS, JS, images) directly from disk and proxies all dynamic requests to the Tomcat application.

> **Dependency** The application (Tomcat on port 8080) must be running before configuring and starting the Nginx reverse proxy.

---

## Install

### Disable SELinux and Firewall

RHEL 10 ships with SELinux in enforcing mode and firewalld active. SELinux blocks Nginx from proxying requests to the application backend (`502 Bad Gateway`), and firewalld blocks external users from reaching port 80.

```shell
setenforce 0
systemctl stop firewalld
systemctl disable firewalld
```

> **Note** In production, configure SELinux policies and firewall rules properly instead of disabling them.

### Install Nginx

> **RHEL 10 Note** RHEL 10 dropped module streams. Nginx 1.26 is available directly from the AppStream repository.

```shell
dnf install -y nginx
systemctl enable nginx
systemctl start nginx
```

---

## Configure

### Nginx Configuration

Replace the entire contents of `/etc/nginx/nginx.conf` with the following. This configuration serves static assets from `/usr/share/nginx/html` with a 7-day browser cache and proxies all other requests to the Tomcat application:

```nginx
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
```

> **Important** Replace `localhost` in the `proxy_pass` directive with the private IP address of the application server if Nginx and the RoboShop application are running on separate servers.

### Copy Static Assets

The application source contains the static frontend assets. Copy them into the Nginx web root so they are served directly:

```shell
mkdir -p /usr/share/nginx/html/css /usr/share/nginx/html/js /usr/share/nginx/html/images
cp -r /tmp/roboshop-monolith/src/main/resources/static/css/* /usr/share/nginx/html/css/
cp -r /tmp/roboshop-monolith/src/main/resources/static/js/* /usr/share/nginx/html/js/
cp -r /tmp/roboshop-monolith/src/main/resources/static/images/* /usr/share/nginx/html/images/
```

---

## Start

Test the configuration for syntax errors, then apply it:

```shell
nginx -t
systemctl restart nginx
```

---

## Verify

Open a browser and navigate to:

```
http://<SERVER-PUBLIC-IP>
```

The RoboShop storefront should load.
