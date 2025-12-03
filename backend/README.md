# OrgaMind Backend API

Backend untuk aplikasi OrgaMind dibangun dengan **Express.js** dan **MySQL**.

## 🚀 Instalasi & Setup

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Setup Database
Buat database baru di MySQL:
```sql
CREATE DATABASE orgamind_db;
```

Jalankan script SQL dari `database/schema.sql` untuk membuat tabel:
```bash
mysql -u root -p orgamind_db < database/schema.sql
```

### 3. Konfigurasi Environment
Copy `.env.example` ke `.env`:
```bash
cp .env.example .env
```

Edit `.env` dan sesuaikan dengan konfigurasi MySQL Anda:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=orgamind_db
DB_PORT=3306
JWT_SECRET=your_secret_key_change_this
```

### 4. Jalankan Server
**Development mode** (dengan auto-reload):
```bash
npm run dev
```

**Production mode**:
```bash
npm start
```

Server akan berjalan di `http://localhost:3000`

## 📚 API Endpoints

### Authentication
- `POST /api/auth/register` - Daftar user baru
- `POST /api/auth/login` - Login user
- `POST /api/auth/forgot-password` - Request reset password

### User Profile (Protected)
- `GET /api/users/profile` - Get profile user
- `PUT /api/users/profile` - Update profile user

### Events
- `GET /api/events` - Get semua events
- `GET /api/events/:id` - Get detail event
- `POST /api/events` - Create event baru (Protected)
- `PUT /api/events/:id` - Update event (Protected)
- `DELETE /api/events/:id` - Delete event (Protected)
- `POST /api/events/:id/join` - Join event (Protected)
- `DELETE /api/events/:id/leave` - Leave event (Protected)
- `GET /api/events/user/events` - Get events milik user (Protected)

## 🔐 Authentication

API menggunakan JWT (JSON Web Tokens).

**Header yang diperlukan untuk request protected:**
```
Authorization: Bearer <token>
```

Contoh:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 📋 Database Schema

### Users Table
- `id` - User ID (Primary Key)
- `name` - Nama user
- `email` - Email (Unique)
- `password` - Password (hashed)
- `phone` - Nomor telepon
- `photo_url` - URL foto profil
- `bio` - Biodata
- `role` - Role (participant/admin)
- `created_at` - Waktu membuat akun
- `updated_at` - Waktu update terakhir

### Events Table
- `id` - Event ID (Primary Key)
- `title` - Judul event
- `description` - Deskripsi
- `location` - Lokasi event
- `date` - Tanggal event
- `time` - Jam event
- `category` - Kategori event
- `image_url` - URL gambar event
- `capacity` - Kapasitas peserta
- `organizer_id` - ID pengorganisir (Foreign Key)
- `created_at`, `updated_at` - Timestamp

### Event Participants Table
- `id` - Primary Key
- `event_id` - ID event (Foreign Key)
- `user_id` - ID user (Foreign Key)
- `joined_at` - Waktu join

## 📝 Contoh Request

### Register
```json
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "+6281234567890"
}
```

### Login
```json
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

### Create Event
```json
POST /api/events
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Workshop Flutter",
  "description": "Belajar Flutter dari dasar",
  "location": "Ruang Meeting A",
  "date": "2024-12-15",
  "time": "09:00:00",
  "category": "Workshop",
  "capacity": 30,
  "imageUrl": "https://example.com/image.jpg"
}
```

### Get All Events
```json
GET /api/events
```

### Join Event
```json
POST /api/events/1/join
Authorization: Bearer <token>
```

## 🐛 Troubleshooting

### Error: Cannot connect to database
- Pastikan MySQL sudah running
- Check kredensial di `.env`
- Pastikan database `orgamind_db` sudah dibuat

### Error: "No token provided"
- Pastikan header `Authorization` sudah ditambahkan
- Format: `Authorization: Bearer <token>`

## 📦 Dependencies

- **express** - Web framework
- **mysql2** - MySQL driver
- **dotenv** - Environment variables
- **bcryptjs** - Password hashing
- **jsonwebtoken** - JWT token
- **cors** - CORS middleware
- **express-validator** - Input validation
- **multer** - File upload (optional)

## 🎯 Next Steps

1. Hubungkan Flutter app dengan API (ganti mock data)
2. Implementasi upload foto profile
3. Setup email untuk reset password
4. Implementasi notifikasi
5. Deploy ke production server

---

Untuk pertanyaan atau issue, hubungi tim development!
