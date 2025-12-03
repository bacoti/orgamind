# 🚀 Setup Backend OrgaMind - Panduan Lengkap

Backend OrgaMind sudah siap! Berikut langkah-langkah untuk menjalankannya.

## 📁 Struktur Folder Backend

```
orga_mind/backend/
├── src/
│   ├── config/
│   │   └── database.js          # Konfigurasi MySQL
│   ├── controllers/
│   │   ├── authController.js    # Login, Register, Forgot Password
│   │   ├── userController.js    # Profile user
│   │   └── eventController.js   # Event management
│   ├── middleware/
│   │   └── authMiddleware.js    # JWT authentication
│   ├── routes/
│   │   ├── authRoutes.js        # Auth endpoints
│   │   ├── userRoutes.js        # User endpoints
│   │   └── eventRoutes.js       # Event endpoints
│   ├── utils/
│   │   ├── responseHandler.js   # Response formatter
│   │   ├── passwordUtils.js     # Password hashing
│   │   └── jwtUtils.js          # JWT token
│   └── index.js                 # Main server file
├── database/
│   └── schema.sql               # Database schema
├── .env                         # Environment variables
├── .env.example                 # Template env
├── package.json                 # Dependencies
└── README.md                    # Dokumentasi
```

## ✅ Checklist Setup

### 1. ✅ Dependencies Sudah Diinstall
```bash
npm install
```
**Status:** DONE ✅

### 2. ⚙️ Setup MySQL Database

**LANGKAH PENTING:** Buat database terlebih dahulu!

#### Opsi A: Menggunakan Command Line
```bash
# Buka MySQL CLI
mysql -u root -p

# Jalankan perintah SQL berikut:
CREATE DATABASE orgamind_db;
USE orgamind_db;
```

Kemudian jalankan schema SQL:
```bash
mysql -u root -p orgamind_db < database/schema.sql
```

#### Opsi B: Menggunakan MySQL Workbench atau phpmyadmin
1. Buat database baru bernama `orgamind_db`
2. Copy semua isi file `database/schema.sql`
3. Paste dan execute di query editor

### 3. 🔧 Konfigurasi Environment (`.env`)

File `.env` sudah dibuat dengan template dasar:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=          # Kosongkan jika MySQL root tidak punya password
DB_NAME=orgamind_db
DB_PORT=3306
PORT=3000
NODE_ENV=development
JWT_SECRET=your_secret_key_change_this_in_production
JWT_EXPIRE=7d
```

**Sesuaikan dengan konfigurasi MySQL Anda:**
- Jika MySQL Anda punya password, isi di `DB_PASSWORD`
- Jika port MySQL bukan 3306, ubah `DB_PORT`

### 4. 🚀 Jalankan Server

**Development Mode (dengan auto-reload):**
```bash
npm run dev
```

**Production Mode:**
```bash
npm start
```

Server akan berjalan di: **http://localhost:3000**

Output:
```
🚀 Server is running on http://localhost:3000
📝 API Documentation:
   - Health Check: GET /api/health
   - Auth: POST /api/auth/register, /api/auth/login, /api/auth/forgot-password
   - Users: GET/PUT /api/users/profile
   - Events: GET /api/events, POST /api/events, etc.
```

## 🧪 Test API dengan Postman

### Health Check (Tanpa token)
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

### 1. Register User
```
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "+6281234567890"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "userId": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 2. Login User
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "userId": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+6281234567890",
    "photoUrl": null,
    "bio": null,
    "role": "participant",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Simpan token ini untuk request berikutnya!**

### 3. Get User Profile (Protected)
```
GET http://localhost:3000/api/users/profile
Authorization: Bearer {TOKEN_DARI_LOGIN}
```

### 4. Create Event (Protected)
```
POST http://localhost:3000/api/events
Authorization: Bearer {TOKEN_DARI_LOGIN}
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

### 5. Get All Events
```
GET http://localhost:3000/api/events
```

### 6. Join Event (Protected)
```
POST http://localhost:3000/api/events/1/join
Authorization: Bearer {TOKEN_DARI_LOGIN}
```

## 📚 Semua Endpoints

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | /api/auth/register | ❌ | Daftar user |
| POST | /api/auth/login | ❌ | Login |
| POST | /api/auth/forgot-password | ❌ | Request reset password |
| GET | /api/users/profile | ✅ | Get profile |
| PUT | /api/users/profile | ✅ | Update profile |
| GET | /api/events | ❌ | Get semua event |
| GET | /api/events/:id | ❌ | Get event detail |
| POST | /api/events | ✅ | Create event |
| PUT | /api/events/:id | ✅ | Update event |
| DELETE | /api/events/:id | ✅ | Delete event |
| POST | /api/events/:id/join | ✅ | Join event |
| DELETE | /api/events/:id/leave | ✅ | Leave event |
| GET | /api/events/user/events | ✅ | Get user events |

**Auth ✅** = Memerlukan token JWT di header Authorization

## 🔐 Cara Menggunakan Token

Di Postman, untuk request yang perlu authentication:

1. Buka tab **Headers**
2. Tambah key: `Authorization`
3. Value: `Bearer {TOKEN}`

Contoh:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImlhdCI6MTcwMTU2MzIwMCwiZXhwIjoxNzAyMTY4MDAwfQ.abc123...
```

## 🐛 Troubleshooting

### Error: "Cannot connect to database"
```
Error: connect ECONNREFUSED 127.0.0.1:3306
```
**Solusi:**
- Pastikan MySQL sudah running
- Check kredensial di file `.env`
- Pastikan database `orgamind_db` sudah dibuat

### Error: "Unknown database 'orgamind_db'"
```
Error: ER_BAD_DB_ERROR: Unknown database 'orgamind_db'
```
**Solusi:**
- Jalankan perintah: `mysql -u root -p orgamind_db < database/schema.sql`
- Atau buat database manual terlebih dahulu

### Error: "No token provided"
```
{
  "success": false,
  "message": "No token provided"
}
```
**Solusi:**
- Pastikan header `Authorization` sudah ditambahkan
- Format header harus: `Authorization: Bearer {token}`

## 🔄 Integrasi dengan Flutter App

Untuk menghubungkan Flutter app dengan backend ini:

1. Update `lib/providers/auth_provider.dart`:
   ```dart
   final apiUrl = 'http://localhost:3000/api';
   // atau jika di Android Emulator: http://10.0.2.2:3000/api
   ```

2. Update semua HTTP calls untuk menggunakan endpoints backend

3. Simpan token dari login untuk request berikutnya:
   ```dart
   SharedPreferences prefs = await SharedPreferences.getInstance();
   prefs.setString('auth_token', responseData['data']['token']);
   ```

4. Gunakan token di setiap request protected:
   ```dart
   var headers = {
     'Authorization': 'Bearer $token',
   };
   ```

## ✨ Features Backend yang Sudah Ada

✅ User Authentication (Register, Login, Forgot Password)
✅ JWT Token-based Security
✅ Password Hashing dengan bcryptjs
✅ Event Management (CRUD)
✅ Event Participants Management
✅ User Profile Management
✅ Input Validation
✅ Error Handling
✅ CORS Support

## 📦 Dependencies Installed

- **express** ^4.18.2 - Web framework
- **mysql2** ^3.6.0 - MySQL driver
- **dotenv** ^16.3.1 - Environment variables
- **bcryptjs** ^2.4.3 - Password hashing
- **jsonwebtoken** ^9.0.0 - JWT
- **cors** ^2.8.5 - CORS support
- **express-validator** ^7.0.0 - Input validation
- **multer** ^1.4.5-lts.1 - File upload

## 🎯 Langkah Selanjutnya

1. ✅ Setup database dan jalankan server
2. ⏭️ Test semua endpoints dengan Postman
3. ⏭️ Hubungkan Flutter app ke backend
4. ⏭️ Implementasi upload profile photo
5. ⏭️ Setup email untuk reset password
6. ⏭️ Deploy ke production server

---

Backend sudah ready to use! 🎉

Untuk pertanyaan atau issue, check README.md di folder backend atau hubungi tim development.
