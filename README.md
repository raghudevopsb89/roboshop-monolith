# 00-Overview

## Application Description

RoboShop Monolith is a Java Spring Boot e-commerce web application for robotics components. It is a single deployable WAR running on Tomcat with a Thymeleaf UI, served behind Nginx. All modules (User, Catalogue, Cart, Orders, Payment, Shipping, Ratings) share a single MySQL database.

## Architecture

![RoboShop Monolith Architecture](architecture.jpg)

## Components

| Component        | Port          | Role                                      |
|------------------|---------------|-------------------------------------------|
| Nginx            | 80            | Static files + reverse proxy to Tomcat    |
| MySQL 8.4        | 3306          | Relational database for all modules       |
| RoboShop App     | 8080 (internal) | Java Spring Boot WAR, all business modules |

## Server Allocation

> **Important** Record the **private IP** of every server after creation — the application server needs the MySQL server's private IP in its configuration.

| Server   | AWS         | Azure          | OS      | Runs                      |
|----------|-------------|----------------|---------|---------------------------|
| Server 1 | t3.small    | Standard_B1ms   | RHEL 10 | Nginx + Tomcat (RoboShop) |
| Server 2 | t3.small    | Standard_B1ms   | RHEL 10 | MySQL                     |

## Setup Order

Components must be set up in the following order due to startup dependencies:

1. **Nginx** — set up first to show the UI shell; proves the web server works before any backend is running
2. **MySQL** — the database must exist before the application starts
3. **Application** — the Spring Boot app connects to MySQL on startup and initialises the schema

## Artifact

The application source is downloaded from:

```
https://raw.githubusercontent.com/r-devops/roboshop-v3/main/monolith/artifacts/roboshop-monolith.zip
```

This archive contains the Maven project source. It is built locally on the application server during setup.
