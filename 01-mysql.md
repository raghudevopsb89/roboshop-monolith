# 01-MySQL

> **Hint** MySQL stores all application data. The monolith uses a single shared database with multiple tables for all modules.

---

## Install

> **RHEL 10 Note** The package is named `mysql8.4-server` (not `mysql-server`). RHEL 10 ships MySQL 8.4 from the AppStream repository.

Install the MySQL server package and enable it to start on boot:

```shell
dnf install -y mysql8.4-server
systemctl enable mysqld
systemctl start mysqld
```

---

## Configure

### Set Root Password

On RHEL 10, MySQL starts with the `root@localhost` user using `auth_socket` (no password). Set a password for root access:

```shell
mysql -u root -e "
  CREATE USER 'root'@'%' IDENTIFIED BY 'RoboShop@1';
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';
  FLUSH PRIVILEGES;
"
```

> **Note** The password `RoboShop@1` is used throughout. If you choose a different password, update every service configuration accordingly.
### Create Application User and Database

Connect as root and provision the application database and user:

```shell
mysql -u root -pRoboShop@1 -e "
  CREATE USER IF NOT EXISTS 'roboshop'@'%' IDENTIFIED BY 'RoboShop@1';
  CREATE DATABASE IF NOT EXISTS roboshop;
  GRANT ALL PRIVILEGES ON roboshop.* TO 'roboshop'@'%';
  FLUSH PRIVILEGES;
"
```

> **Note** The schema and master data are loaded automatically by the application on first startup via Spring Boot's `spring.sql.init.mode=always`. No manual schema import is required.

---

## Verify

Test that the application user can connect and see the database:

```shell
mysql -u roboshop -pRoboShop@1 -e "SHOW DATABASES;"
```

The output should include `roboshop` in the list of databases.
