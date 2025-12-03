# ✅ Flutter App Terintegrasi dengan Backend!

## 🎉 Apa yang Sudah Dibuat?

### 1. **API Configuration** (`lib/constants/api_config.dart`)
- Base URL configuration
- Semua endpoints (auth, user, events)
- Helper untuk authorization headers

### 2. **Auth Service Updated** (`lib/services/auth_service.dart`)
✅ `login()` - Call API `/api/auth/login`
✅ `register()` - Call API `/api/auth/register`
✅ `updateProfile()` - Call API `/api/users/profile`
✅ Menyimpan JWT token di SharedPreferences
✅ Auto-attach token untuk protected endpoints

### 3. **Event Provider Baru** (`lib/providers/event_provider.dart`)
✅ `getAllEvents()` - Get semua events dari API
✅ `getEventDetail()` - Get detail 1 event
✅ `createEvent()` - Create event baru
✅ `updateEvent()` - Update event
✅ `deleteEvent()` - Delete event
✅ `joinEvent()` - Join event
✅ `leaveEvent()` - Leave event
✅ `getUserEvents()` - Get events milik user
✅ Loading states & error handling

### 4. **Event Model Updated** (`lib/models/event_model.dart`)
✅ Support JSON from/to backend
✅ Compatible dengan struktur database backend
✅ `fromJson()` - Parse data dari API
✅ `toJson()` - Convert untuk kirim ke API

### 5. **Screens Updated**
✅ `event_list_screen.dart` - Menggunakan EventProvider
  - Pull to refresh
  - Loading indicator
  - Error handling
  - Real data dari backend

✅ `create_event_screen.dart` - Create event via API
  - Form validation
  - Loading state saat submit
  - Error handling
  - Auto refresh list setelah create

### 6. **Main App Updated** (`lib/main.dart`)
✅ EventProvider ditambahkan ke MultiProvider
✅ Ready untuk state management

### 7. **Dependencies** (`pubspec.yaml`)
✅ `http: ^1.1.0` - HTTP client untuk API calls
✅ Dependencies sudah di-install (`flutter pub get`)

---

## 🚀 Cara Menjalankan

### 1. **Pastikan Backend Running**
```bash
cd backend
npm run dev
```

Server harus running di: `http://localhost:3000`

### 2. **Update Base URL (PENTING!)**

Buka `lib/constants/api_config.dart`:

#### Untuk Web / iOS Simulator:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

#### Untuk Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

#### Untuk Physical Device (Android/iOS):
```dart
// Cari IP address komputer Anda (cmd: ipconfig)
static const String baseUrl = 'http://192.168.1.100:3000/api';
```

### 3. **Run Flutter App**
```bash
flutter run
```

Pilih device (Chrome, Android Emulator, dll)

---

## 🧪 Testing Flow

### Test 1: Register User Baru
1. Buka app, klik "Daftar Akun"
2. Isi form:
   - Nama: John Doe
   - Email: john@example.com
   - Password: password123
   - Konfirmasi Password: password123
3. Klik "Daftar"
4. Jika berhasil → Auto login → Masuk ke Home Screen

**Verifikasi di Backend:**
```sql
USE orgamind_db;
SELECT * FROM users WHERE email = 'john@example.com';
```

### Test 2: Login
1. Logout dulu (jika sudah login)
2. Klik "Masuk"
3. Isi:
   - Email: john@example.com
   - Password: password123
4. Klik "Masuk"
5. Harus masuk ke Home Screen

### Test 3: Lihat List Events
1. Setelah login, lihat tab "Acara Ku"
2. List events akan muncul dari database
3. Pull down untuk refresh
4. Klik event untuk lihat detail

**Note:** List akan kosong jika belum ada events di database

### Test 4: Create Event (Admin/Organizer)
1. Login sebagai admin/organizer
2. Di tab "Acara Ku", klik tombol "+" (FloatingActionButton)
3. Isi form:
   - Judul: Workshop Flutter
   - Lokasi: Ruang Meeting A
   - Tanggal: Pilih tanggal
   - Jam Mulai: 09:00
   - Jam Selesai: 12:00
   - Deskripsi: Belajar Flutter
   - Kategori: Workshop
   - Kapasitas: 30
4. Klik "Simpan"
5. Event baru muncul di list

**Verifikasi di Backend:**
```sql
SELECT * FROM events ORDER BY created_at DESC LIMIT 1;
```

### Test 5: Join Event
1. Login sebagai participant
2. Lihat list events
3. Klik event yang ingin diikuti
4. Klik tombol "Daftar" / "Join"
5. Verify participant count bertambah

**Verifikasi di Backend:**
```sql
SELECT * FROM event_participants WHERE user_id = 1 AND event_id = 1;
```

---

## 📋 API Endpoints yang Sudah Terintegrasi

| Feature | Endpoint | Status |
|---------|----------|--------|
| Register | POST /api/auth/register | ✅ |
| Login | POST /api/auth/login | ✅ |
| Get Profile | GET /api/users/profile | ✅ |
| Update Profile | PUT /api/users/profile | ✅ |
| Get All Events | GET /api/events | ✅ |
| Get Event Detail | GET /api/events/:id | ✅ |
| Create Event | POST /api/events | ✅ |
| Update Event | PUT /api/events/:id | ✅ |
| Delete Event | DELETE /api/events/:id | ✅ |
| Join Event | POST /api/events/:id/join | ✅ |
| Leave Event | DELETE /api/events/:id/leave | ✅ |

---

## 🐛 Troubleshooting

### Error: "Connection refused"
**Penyebab:** Backend tidak running atau URL salah

**Solusi:**
1. Pastikan backend running: `npm run dev`
2. Cek base URL di `api_config.dart`
3. Untuk Android Emulator, gunakan `10.0.2.2` bukan `localhost`

### Error: "401 Unauthorized"
**Penyebab:** Token tidak valid atau expired

**Solusi:**
1. Logout dan login ulang
2. Token otomatis refresh saat login

### Error: "No events found"
**Penyebab:** Database masih kosong

**Solusi:**
1. Create event pertama via app (sebagai admin)
2. Atau insert manual ke database untuk testing

### Events tidak muncul setelah create
**Penyebab:** List tidak refresh otomatis

**Solusi:**
1. Pull down untuk refresh
2. Atau navigate keluar dan masuk lagi

---

## 📱 Screenshots Expected

### 1. Login Screen
- Input email & password
- Button "Masuk"
- Link "Daftar Akun"

### 2. Register Screen
- Input nama, email, password
- Button "Daftar"
- Auto login setelah success

### 3. Event List (Empty State)
- Icon calendar dengan pesan "Belum ada acara"
- Button "+" untuk create (jika admin)

### 4. Event List (With Data)
- Card untuk setiap event
- Tampil: Title, Date, Location
- Status badge (Terkonfirmasi, dll)
- Pull to refresh

### 5. Event Detail
- Detail lengkap event
- Button "Join" (jika belum join)
- Button "Leave" (jika sudah join)
- Participant count

### 6. Create Event
- Form lengkap
- Date & time picker
- Loading indicator saat submit
- Success message

---

## ✅ Next Steps

1. ✅ Backend running
2. ✅ Flutter app updated
3. ⏭️ Test register → login
4. ⏭️ Test create event
5. ⏭️ Test join event
6. ⏭️ Implementasi upload photo profile (optional)
7. ⏭️ Add more features (notifications, search, filter)

---

## 🎯 Summary

**Backend:** ✅ Running di `http://localhost:3000`
**Flutter:** ✅ Terintegrasi dengan API
**Database:** ✅ Schema ready
**Auth:** ✅ JWT token authentication
**Events:** ✅ Full CRUD + join/leave

**Status:** 🎉 **READY TO TEST!**

Silakan jalankan app dan test semua fitur!
