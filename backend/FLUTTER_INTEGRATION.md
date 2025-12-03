# 🔗 Integrasi Flutter dengan Backend Express.js

Panduan cara menghubungkan aplikasi Flutter dengan backend Express.js yang sudah dibuat.

## 1. Update Konfigurasi Base URL

Buka atau buat file `lib/constants/api_config.dart`:

```dart
class ApiConfig {
  // Ganti dengan URL backend Anda
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Jika menggunakan Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Production
  // static const String baseUrl = 'https://api.orgamind.com/api';

  // Endpoints
  static const String authRegister = '$baseUrl/auth/register';
  static const String authLogin = '$baseUrl/auth/login';
  static const String authForgotPassword = '$baseUrl/auth/forgot-password';
  
  static const String userProfile = '$baseUrl/users/profile';
  static const String userUpdateProfile = '$baseUrl/users/profile';
  
  static const String eventsGetAll = '$baseUrl/events';
  static const String eventsCreate = '$baseUrl/events';
  static const String eventsGetDetail = '$baseUrl/events';
  static const String eventsUpdate = '$baseUrl/events';
  static const String eventsDelete = '$baseUrl/events';
  static const String eventsJoin = '$baseUrl/events';
  static const String eventsLeave = '$baseUrl/events';
  static const String eventsGetUserEvents = '$baseUrl/events/user/events';
}
```

## 2. Update Auth Provider

Buka `lib/providers/auth_provider.dart` dan update implementasi:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_config.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  // Load token dari SharedPreferences saat startup
  Future<void> loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        // Load user profile jika token ada
        await getUserProfile();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load token: $e';
      notifyListeners();
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('auth_token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _user = User.fromJson(data['data']);
        
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('auth_token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get User Profile
  Future<bool> getUserProfile() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userProfile),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['data']);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? bio,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.userUpdateProfile),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authForgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        _errorMessage = 'Reset link sent to your email';
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Failed to process request';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('auth_token');
    
    notifyListeners();
  }
}
```

## 3. Update Event Provider

Buat atau update `lib/providers/event_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_config.dart';
import '../models/event_model.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _userEvents = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<EventModel> get events => _events;
  List<EventModel> get userEvents => _userEvents;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get All Events
  Future<bool> getAllEvents(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.eventsGetAll),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _events = (data['data'] as List)
            .map((event) => EventModel.fromJson(event))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get Event Detail
  Future<bool> getEventDetail(int eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.eventsGetDetail}/$eventId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _selectedEvent = EventModel.fromJson(data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create Event
  Future<bool> createEvent({
    required String token,
    required String title,
    required String description,
    required String location,
    required String date,
    required String time,
    required String category,
    required int capacity,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eventsCreate),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'date': date,
          'time': time,
          'category': category,
          'capacity': capacity,
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        await getAllEvents(token);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Join Event
  Future<bool> joinEvent(int eventId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.eventsJoin}/$eventId/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        await getAllEvents(token);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Failed to join event';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Leave Event
  Future<bool> leaveEvent(int eventId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.eventsLeave}/$eventId/leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await getAllEvents(token);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get User Events
  Future<bool> getUserEvents(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.eventsGetUserEvents),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userEvents = (data['data'] as List)
            .map((event) => EventModel.fromJson(event))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
```

## 4. Update Main App dengan Provider

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadTokenFromStorage()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'OrgaMind',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const SplashScreen(), // Atau langsung ke login/home sesuai kebutuhan
      ),
    );
  }
}
```

## 5. Update Login Screen

Contoh implementasi di `lib/screens/login_screen.dart`:

```dart
// Di dalam class state
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Di tombol login
ElevatedButton(
  onPressed: () async {
    final email = _emailController.text;
    final password = _passwordController.text;
    
    final success = await authProvider.login(
      email: email,
      password: password,
    );
    
    if (success) {
      // Navigate ke home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  },
  child: const Text('Login'),
)
```

## 6. Update pubspec.yaml

Pastikan dependencies sudah ada:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  http: ^1.1.0
  shared_preferences: ^2.0.15
```

## 7. Important Notes

### Untuk Android Emulator:
Jika menggunakan Android Emulator, ganti `localhost` dengan `10.0.2.2`:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

### Untuk Physical Device:
Ganti dengan IP address lokal Anda:

```dart
static const String baseUrl = 'http://192.168.x.x:3000/api'; // Sesuaikan dengan IP Anda
```

Cari IP address Anda dengan command:
```bash
ipconfig  # Windows
ifconfig # Mac/Linux
```

## 8. Testing

1. Pastikan backend sudah berjalan: `npm run dev`
2. Jalankan Flutter app: `flutter run`
3. Test registration dan login di app
4. Verifikasi token disimpan dengan benar
5. Test create event dan join event

---

Backend sudah siap diintegrasikan! 🎉
