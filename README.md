# TownKart 🛒

> **A hyper-local multi-vendor e-commerce platform connecting neighborhood merchants, customers, and platform administrators.**

TownKart is a full-stack on-demand delivery ecosystem engineered with a **Flutter** cross-platform mobile client, a modular **Node.js / Express / TypeScript** RESTful backend, and a relational **MySQL** database architecture.

---

## 📑 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Database Architecture](#database-architecture)
- [API Specification](#api-specification)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#1-backend-setup)
  - [Database Setup](#2-database-setup)
  - [Mobile App Setup](#3-mobile-app-setup)
- [License](#license)

---

## 🏛 Architecture Overview

TownKart operates as a multi-role, modular platform:
1. **Customer App (Flutter)**: Allows users to explore local stores, browse categorized master products, compare merchant pricing, and place transactional orders.
2. **Merchant Portal**: Enables local shop owners to manage shop details, map catalog items to store inventory, update stock levels, and fulfill incoming orders.
3. **Admin Dashboard**: Moderation system for reviewing merchant applications, monitoring customer accounts, and managing product categories.
4. **Backend Engine (Node.js/Express/TypeScript)**: Centralized REST API coordinating role-based workflows, ACID checkout transactions, and inventory updates.
5. **Relational Core (MySQL)**: 32 normalized tables with referential integrity constraints, automated audit triggers, and connection pooling.

---

## ✨ Key Features

- **Multi-Role User System**: Role-Based Access (Customer, Merchant, Admin) with phone/OTP and credential-based verification.
- **Hyperlocal Discovery**: Compares price, distance, and stock levels across multiple local sellers for the exact same master product variant.
- **Atomic Checkout Engine**: Multi-vendor cart split and order generation wrapped in transactional integrity (`BEGIN TRANSACTION` -> `COMMIT`/`ROLLBACK`) ensuring zero overselling.
- **Dynamic Inventory Management**: Merchants can add, edit, toggle availability, and track stock counts in real time.
- **Responsive Mobile UI**: Built with Flutter following Material 3 design patterns and powered by Riverpod state management.

---

## 💻 Tech Stack

### Mobile Frontend
- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Platforms**: Android, iOS, Web

### Backend & API
- **Runtime**: [Node.js](https://nodejs.org/)
- **Framework**: [Express.js](https://expressjs.com/)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Tooling**: `nodemon`, `ts-node`

### Database
- **Engine**: [MySQL](https://www.mysql.com/) (InnoDB)
- **Driver**: `mysql2/promise` with Connection Pooling (limit: 10 connections)
- **Features**: Foreign key cascades, UUID primary keys, `BEFORE UPDATE` audit triggers

---

## 🗄 Database Architecture

The schema contains **32 normalized relational entities**:

- **Authentication & Roles**: `users`, `customers`, `customer_addresses`, `admins`, `merchants`, `shops`
- **Global Catalog**: `categories`, `subcategories`, `units`, `brands`, `master_products`, `master_product_variants`, `product_images`
- **Merchant Inventory**: `merchant_categories`, `merchant_products`, `merchant_inventory`, `inventory_transactions`
- **Checkout & Orders**: `carts`, `cart_items`, `orders`, `merchant_orders`, `order_items`, `payments`
- **Delivery & Auditing**: `delivery_tracking`, `delivery_settings`, `reviews`, `wishlists`, `wishlist_items`, `notifications`, `otp_verifications`, `admin_logs`

---

## 🔌 API Specification

The backend serves **32 RESTful endpoints** partitioned into modular domains:

| Route Group | Base Path | Key Endpoints |
| :--- | :--- | :--- |
| **Authentication** | `/api/auth` | Customer/Merchant signup, login, OTP verification |
| **Customer** | `/api/customer` | Category browsing, product search, multi-seller variant lookup, order creation, order history |
| **Merchant** | `/api/merchant` | Store dashboard metrics, inventory management, status toggles, order lifecycle updates |
| **Admin** | `/api/admin` | Merchant approval workflows, platform analytics, catalog moderation |

---

## 📂 Project Structure

```
TownKart/
├── backend/
│   ├── src/
│   │   ├── config/          # Database connection pool setup
│   │   ├── controllers/     # Route logic for auth, customer, merchant, admin
│   │   ├── routes/          # Express route definitions
│   │   └── server.ts        # Server entrypoint and middleware
│   ├── seed_catalog.ts      # Automated catalog & category seeder
│   └── package.json
├── database/
│   ├── mysql_schema.sql     # Consolidated complete database DDL schema
│   └── *.sql                # Modular migration and trigger scripts
└── frontend/
    ├── customer_app/        # Flutter shopper & customer interface
    │   ├── lib/
    │   │   ├── core/        # Theme, routing, Riverpod providers, API services
    │   │   └── presentation/# UI screens (auth, home, categories, orders)
    │   └── pubspec.yaml
    └── merchant_app/        # Flutter merchant dashboard application
```

---

## 🚀 Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/) (v18+)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0+)
- [MySQL Server](https://dev.mysql.com/downloads/mysql/) (v8.0+)

---

### 1. Database Setup
1. Start your local MySQL service.
2. Create the database and run the consolidated schema:
```sql
CREATE DATABASE townkart;
USE townkart;
SOURCE database/mysql_schema.sql;
```

---

### 2. Backend Setup
1. Navigate to the backend directory:
```bash
cd backend
npm install
```

2. Configure environment variables in `backend/.env`:
```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=townkart
```

3. Seed initial categories and master catalog:
```bash
npx ts-node seed_catalog.ts
```

4. Start the development server:
```bash
npm run dev
```
The API server will listen on `http://localhost:3000`.

---

### 3. Mobile App Setup
1. Navigate to the customer app directory:
```bash
cd frontend/customer_app
flutter pub get
```

2. Run the application:
```bash
# Run on Chrome / Web
flutter run -d chrome

# Or run on connected Android/iOS device
flutter run
```

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
