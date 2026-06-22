# 📊 Debt Management System

A full-stack mobile application designed to help retail shop owners efficiently manage customer debts, credits, and outstanding balances. The application provides secure account-based access, real-time cloud synchronization, encrypted local storage, and automated balance calculations.

---

## 🚀 Overview

Debt Management System is a production-style mobile application built using Flutter, Node.js, Express.js, and MongoDB Atlas. It enables business owners to track customer transactions, monitor outstanding balances, and securely manage financial records from anywhere.

The application eliminates the challenges of traditional notebook-based debt tracking by providing a modern, secure, and scalable digital solution.

---

## ✨ Features

* 🔐 JWT-based Authentication
* 👤 User-specific data isolation
* 📱 Cross-platform Flutter mobile application
* ☁️ Real-time cloud synchronization
* 🔒 AES-256 encrypted local storage
* 📊 Automatic balance calculations
* 🔍 Customer search and filtering
* 📈 Transaction history tracking
* 🌐 RESTful API architecture
* 🚀 Production deployment support

---

## 🛠 Tech Stack

### Frontend

* Flutter
* Dart
* Riverpod State Management

### Backend

* Node.js
* Express.js
* REST APIs

### Database

* MongoDB Atlas

### Security

* JWT Authentication
* AES-256 Local Data Encryption

### Deployment

* Render
* MongoDB Atlas Cloud

---

## 🏗 System Architecture

```text
Flutter Mobile App
        │
        ▼
REST API (Node.js + Express)
        │
        ▼
MongoDB Atlas Database
        │
        ▼
Real-Time Data Synchronization

Additional Components:
• JWT Authentication
• AES-256 Encrypted Storage
• Riverpod State Management
```

## 🎯 Problem Statement

Small businesses often manage customer debts using notebooks or spreadsheets, leading to:

* Calculation errors
* Missing payment records
* Difficulty tracking outstanding balances
* Lack of backup and recovery systems
* Limited accessibility across devices

This project addresses these challenges through a secure cloud-based debt management platform.

---

## 💡 Key Features Implemented

### Secure Authentication

Implemented JWT-based authentication to ensure secure user access and account isolation.

### Customer Management

Create, update, search, and manage customer records efficiently.

### Debt & Credit Tracking

Record customer debts and credit settlements while maintaining accurate balances.

### Automatic Balance Calculation

Outstanding balances are calculated dynamically to reduce manual errors.

### Cloud Synchronization

Data is stored securely in MongoDB Atlas and synchronized in real-time.

### Encrypted Local Storage

Sensitive information is protected using AES-256 encryption for improved security and offline persistence.

---

## 📱 Screenshots

Add application screenshots here.

```md
assets/screenshots/login.png
assets/screenshots/dashboard.png
assets/screenshots/customer_details.png
```

---

## ⚙️ Installation

### Clone Repository

```bash
git clone https://github.com/kapilsuriya23/dept_manager.git
cd dept_manager
```

### Flutter App Setup

```bash
flutter pub get
flutter run
```

### Backend Setup

```bash
cd backend

npm install
npm start
```

### Environment Variables

Create a `.env` file:

```env
PORT=5000

MONGO_URI=your_mongodb_connection_string

JWT_SECRET=your_jwt_secret_key
```

---

## 🔒 Security Features

* JWT Token Authentication
* Protected API Routes
* User Data Isolation
* AES-256 Encrypted Storage
* Secure Password Handling
* Environment Variable Protection

---

## 📈 Learning Outcomes

Through this project, I gained practical experience in:

* Full-Stack Mobile Development
* Flutter State Management with Riverpod
* REST API Development
* Authentication & Authorization
* MongoDB Database Design
* Cloud Deployment
* Secure Data Storage
* Production-Level Application Architecture

---

## 🔮 Future Improvements

* Push Notifications
* PDF Invoice Generation
* Multi-Shop Support
* Customer Analytics Dashboard
* Data Export (Excel/PDF)
* Offline Synchronization Queue
* Role-Based Access Control

---

## 📜 License

This project is developed for educational and portfolio purposes.
