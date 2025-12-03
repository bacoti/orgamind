# 🎉 Backend OrgaMind - Selesai!

Backend untuk aplikasi OrgaMind dengan **Express.js** dan **MySQL** sudah siap digunakan!

## 📦 Yang Sudah Dibuat

✅ **Backend Structure**
- Express.js server
- MySQL database connection
- Authentication dengan JWT
- CRUD untuk Events
- User profile management
- Complete API endpoints

✅ **Files & Folders**
```
backend/
├── src/
│   ├── config/database.js
│   ├── controllers/ (auth, user, event)
│   ├── middleware/authMiddleware.js
│   ├── routes/ (auth, user, event)
│   ├── utils/ (password, jwt, response)
│   └── index.js (main server)
├── database/schema.sql
├── package.json
├── .env
├── .gitignore
├── README.md
├── SETUP_GUIDE.md
├── FLUTTER_INTEGRATION.md
├── OrgaMind_API.postman_collection.json
└── node_modules/
```

✅ **Dependencies Installed**
- express ^4.18.2
- mysql2 ^3.6.0
- bcryptjs ^2.4.3
- jsonwebtoken ^9.0.0
- cors ^2.8.5
- express-validator ^7.0.0
- dotenv ^16.3.1

## 🚀 Quick Start

### 1️⃣ Setup Database (WAJIB!)

```bash
# Buka MySQL
mysql -u root -p

# Jalankan ini
CREATE DATABASE orgamind_db;
```

Kemudian:
```bash
cd backend
mysql -u root -p orgamind_db < database/schema.sql
```

### 2️⃣ Konfigurasi .env

File `.env` sudah ada, sesuaikan password MySQL jika ada:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=          # Isi jika ada
DB_NAME=orgamind_db
DB_PORT=3306
```

### 3️⃣ Jalankan Server

```bash
cd backend
npm run dev
```

Server berjalan di: **http://localhost:3000** ✅

## 📚 Documentation Files

| File | Untuk |
|------|-------|
| `README.md` | Overview dan API endpoints |
| `SETUP_GUIDE.md` | Setup lengkap step-by-step |
| `FLUTTER_INTEGRATION.md` | Cara integrate dengan Flutter |
| `OrgaMind_API.postman_collection.json` | Import ke Postman untuk testing |

## 🧪 Testing dengan Postman

1. Download Postman: https://www.postman.com/downloads/
2. Open Postman
3. Import file: `backend/OrgaMind_API.postman_collection.json`
4. Set variable `base_url` = `http://localhost:3000`
5. Test endpoints (register → login → create event → dll)

## 📋 API Endpoints Summary

| Method | Endpoint | Auth | 
|--------|----------|------|
| POST | /api/auth/register | ❌ |
| POST | /api/auth/login | ❌ |
| GET | /api/users/profile | ✅ |
| PUT | /api/users/profile | ✅ |
| GET | /api/events | ❌ |
| POST | /api/events | ✅ |
| POST | /api/events/:id/join | ✅ |
| DELETE | /api/events/:id/leave | ✅ |
| GET | /api/events/user/events | ✅ |

**✅ = Perlu JWT Token**

## 🔗 Integrasi Flutter

Update provider di Flutter app untuk menggunakan endpoint backend:

1. Create `lib/constants/api_config.dart` dengan base URL
2. Update `AuthProvider` untuk call `/api/auth/login`, `/api/auth/register`
3. Update `EventProvider` untuk call `/api/events`, dll
4. Simpan token dari login dan gunakan di header

Lihat file `FLUTTER_INTEGRATION.md` untuk detail lengkap!

## 🐛 Common Issues & Solutions

### ❌ "Cannot connect to database"
```
mysql -u root -p
CREATE DATABASE orgamind_db;
mysql -u root -p orgamind_db < database/schema.sql
```

### ❌ "Unknown database 'orgamind_db'"
Pastikan sudah run `schema.sql` atau buat table manual

### ❌ "CORS Error" di Flutter
Sudah include `cors()` di server, tapi pastikan URL sesuai

### ❌ "Token invalid"
Pastikan format header: `Authorization: Bearer {token}`

## 📱 For Android Emulator Users

Ganti `localhost` dengan `10.0.2.2`:
```dart
const String baseUrl = 'http://10.0.2.2:3000/api';
```

## 🎯 Next Steps

1. ✅ Database setup & test
2. ✅ Jalankan backend server
3. ⏭️ Test API dengan Postman
4. ⏭️ Update Flutter app untuk use backend
5. ⏭️ Test integration Flutter + Backend
6. ⏭️ Implementasi upload photo (optional)
7. ⏭️ Deploy ke production

## 📞 Need Help?

- Backend issues → Check README.md & SETUP_GUIDE.md
- Flutter integration → Check FLUTTER_INTEGRATION.md
- API testing → Use Postman collection
- Database issues → Check schema.sql

---

## 📝 Summary of What's Included

### ✨ Features

✅ User Registration & Login
✅ Password Hashing (bcryptjs)
✅ JWT Authentication
✅ Event CRUD Operations
✅ Event Participants Management
✅ User Profile Management
✅ Input Validation
✅ Error Handling
✅ CORS Support
✅ Response Formatting

### 🗄️ Database Tables

- **users** - User accounts & profiles
- **events** - Event information
- **event_participants** - Who joined which event
- **notifications** - Optional, for future use

### 🔐 Security Features

✅ Password hashing dengan bcryptjs
✅ JWT token-based auth
✅ Token expiration (7 days)
✅ Protected routes dengan middleware
✅ Input validation dengan express-validator
✅ CORS protection

## 🎉 Congratulations!

Backend Anda sudah siap! Tinggal:
1. Setup MySQL database
2. Jalankan `npm run dev`
3. Connect dengan Flutter app

Happy coding! 🚀

---

**Created:** December 3, 2025
**Status:** ✅ Ready to Use
**Version:** 1.0.0
