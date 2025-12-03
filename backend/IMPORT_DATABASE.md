# 📝 Cara Import Database Schema - Panduan Praktis

## ✅ Database `orgamind_db` sudah dibuat? 

Jika belum, buat dulu database-nya.

---

## 🔧 Pilihan Cara Import Schema

### **Cara 1: MySQL Workbench (RECOMMENDED)** ⭐

1. **Buka MySQL Workbench**
2. **Connect ke MySQL Server** (klik connection Anda)
3. **Buat database jika belum ada:**
   ```sql
   CREATE DATABASE orgamind_db;
   ```
4. **Klik icon folder "Open SQL Script"** atau File → Open SQL Script
5. **Navigate ke:**
   ```
   D:\Kampus\Semester 5\Mobile\Tugas Kelompok\orgamind\orga_mind\backend\database\schema.sql
   ```
6. **Klik Execute** (icon petir ⚡) atau tekan **Ctrl + Shift + Enter**
7. **Refresh** → Lihat tables sudah muncul di sidebar kiri

✅ **Done!** Tables `users`, `events`, `event_participants`, `notifications` sudah dibuat.

---

### **Cara 2: phpMyAdmin**

1. **Buka phpMyAdmin** (biasanya `http://localhost/phpmyadmin`)
2. **Login** dengan username/password MySQL Anda
3. **Pilih atau buat database `orgamind_db`** di sidebar kiri
4. **Klik tab "SQL"** di bagian atas
5. **Copy semua isi file `schema.sql`** (lihat di bawah)
6. **Paste di text area**
7. **Klik tombol "Go"** atau "Execute"

✅ **Done!**

---

### **Cara 3: HeidiSQL / DBeaver / Tool Lain**

Sama seperti MySQL Workbench:
1. Connect ke MySQL
2. Open/Import SQL file `backend/database/schema.sql`
3. Execute

---

## 📋 Schema SQL (Copy ini jika perlu)

```sql
-- Create Database
CREATE DATABASE IF NOT EXISTS orgamind_db;
USE orgamind_db;

-- Create Users Table
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(15),
  photo_url VARCHAR(255),
  bio TEXT,
  role ENUM('participant', 'admin') DEFAULT 'participant',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Create Events Table
CREATE TABLE IF NOT EXISTS events (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  location VARCHAR(255) NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  category VARCHAR(50),
  image_url VARCHAR(255),
  capacity INT DEFAULT 100,
  organizer_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (organizer_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_date (date),
  INDEX idx_category (category)
);

-- Create Event Participants Table
CREATE TABLE IF NOT EXISTS event_participants (
  id INT PRIMARY KEY AUTO_INCREMENT,
  event_id INT NOT NULL,
  user_id INT NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_participant (event_id, user_id),
  INDEX idx_user (user_id)
);

-- Create Notifications Table (Optional)
CREATE TABLE IF NOT EXISTS notifications (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  event_id INT,
  title VARCHAR(200) NOT NULL,
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE SET NULL,
  INDEX idx_user_read (user_id, is_read)
);
```

---

## ✅ Cara Verifikasi Schema Sudah Berhasil

Setelah import, cek dengan query ini:

```sql
USE orgamind_db;
SHOW TABLES;
```

**Output yang benar:**
```
+------------------------+
| Tables_in_orgamind_db  |
+------------------------+
| users                  |
| events                 |
| event_participants     |
| notifications          |
+------------------------+
```

Atau cek struktur table:
```sql
DESCRIBE users;
DESCRIBE events;
```

---

## 🚀 Setelah Schema Berhasil di-Import

### 1. Update file `.env` jika perlu
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=          # Isi jika MySQL punya password
DB_NAME=orgamind_db
DB_PORT=3306
```

### 2. Jalankan Backend Server
```bash
cd backend
npm run dev
```

**Output yang benar:**
```
🚀 Server is running on http://localhost:3000
📝 API Documentation:
   - Health Check: GET /api/health
   ...
```

### 3. Test Connection
Buka browser atau Postman:
```
GET http://localhost:3000/api/health
```

**Response:**
```json
{
  "status": "OK",
  "message": "Backend is running"
}
```

✅ **Backend ready!**

---

## 🐛 Troubleshooting

### Error: "Table already exists"
```
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS event_participants;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS users;
```
Lalu jalankan ulang schema.sql

### Error: "Foreign key constraint fails"
Pastikan urutan pembuatan table benar (users → events → event_participants)

### Error: "Access denied"
Pastikan username/password MySQL benar di `.env`

---

## 📞 Need Help?

Jika masih ada error, cek:
1. MySQL service sudah running?
   - Windows: Services → MySQL → Running
   - Cek di Task Manager → Services → MySQL
2. Port 3306 tidak bentrok dengan aplikasi lain?
3. Kredensial di `.env` sudah benar?

---

**Status:** Database schema ready to import! 🎉

Pilih salah satu cara di atas (Cara 1 paling mudah dengan MySQL Workbench)
