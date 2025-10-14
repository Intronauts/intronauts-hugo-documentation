---
title: "Authentication Sistemi"
weight: 25
---

# 🔐 Authentication System Implementation

## 📋 İçindekiler
- [Genel Bakış](#genel-bakış)
- [Mimari Yapı](#mimari-yapı)
- [Database Şeması](#database-şeması)
- [Flutter Implementation](#flutter-implementation)
- [Supabase Configuration](#supabase-configuration)
- [Akış Diyagramları](#akış-diyagramları)
- [Sorun Giderme](#sorun-giderme)
- [Güvenlik Notları](#güvenlik-notları)

---

## 🎯 Genel Bakış

Bu proje **Supabase Auth** kullanarak native authentication sistemi implementasyonu içerir. Custom Edge Functions veya trigger'lar yerine, **Supabase'in built-in Auth API'sı** kullanılmıştır.

### ✅ Temel Özellikler
- ✅ **Email/Password** ile kayıt ve giriş
- ✅ **JWT Token** based authentication
- ✅ **SharedPreferences** ile session persistence
- ✅ **Role-based access control** (student, teacher, admin, editor)
- ✅ **Automatic profile creation** after auth
- ✅ **Secure password handling** (Supabase Auth tarafında)

### 🚫 Kullanılmayan Yöntemler
- ❌ Custom Edge Functions (auth-register-local, auth-login)
- ❌ Database triggers for user creation
- ❌ Manual password hashing with bcrypt
- ❌ Direct PostgreSQL user management

---

## 🏗️ Mimari Yapı

### 1. Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     REGISTRATION FLOW                            │
└─────────────────────────────────────────────────────────────────┘

Flutter App
    │
    ├─► supabase.auth.signUp(email, password, data)
    │       │
    │       ├─► Supabase Auth (Backend)
    │       │       │
    │       │       ├─► Creates user in auth.users table
    │       │       ├─► Sends email verification (optional)
    │       │       └─► Returns User + Session (JWT)
    │       │
    │       └─► Returns: AuthResponse {
    │               user: User (UUID),
    │               session: Session (access_token, refresh_token)
    │           }
    │
    ├─► Create profile in public.users table
    │       │
    │       └─► INSERT INTO users (auth_user_id, email, name, role_id, ...)
    │
    └─► Save session to SharedPreferences
            │
            └─► Store: {user: {...}, token: "jwt_token"}


┌─────────────────────────────────────────────────────────────────┐
│                        LOGIN FLOW                                │
└─────────────────────────────────────────────────────────────────┘

Flutter App
    │
    ├─► supabase.auth.signInWithPassword(email, password)
    │       │
    │       ├─► Supabase Auth validates credentials
    │       │
    │       └─► Returns: AuthResponse {
    │               user: User (UUID),
    │               session: Session (JWT)
    │           }
    │
    ├─► Fetch profile from public.users
    │       │
    │       └─► SELECT * FROM users WHERE auth_user_id = user.id
    │
    └─► Save session to SharedPreferences
```

### 2. Katmanlar (Layers)

```
┌──────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                      │
│  (register_screen.dart, login_screen.dart)               │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                          │
│           (auth_service.dart)                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • register()                                       │   │
│  │ • login()                                          │   │
│  │ • logout()                                         │   │
│  │ • getCurrentUser()                                 │   │
│  │ • isLoggedIn()                                     │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│                  PERSISTENCE LAYER                        │
│          (session_manager.dart)                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • saveSession()                                    │   │
│  │ • getCurrentUser()                                 │   │
│  │ • getToken()                                       │   │
│  │ • clearSession()                                   │   │
│  │ • isLoggedIn()                                     │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│                     DATA LAYER                            │
│         (Supabase Client + SharedPreferences)            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • auth.users (Supabase Auth)                      │   │
│  │ • public.users (Profile Data)                     │   │
│  │ • public.roles (Role Definitions)                 │   │
│  │ • SharedPreferences (Local Cache)                 │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Şeması

### 1. Supabase Auth Schema (auth.users)

**Supabase tarafından otomatik yönetilir:**

```sql
-- auth.users (Supabase managed)
-- NOT VISIBLE IN public SCHEMA
CREATE TABLE auth.users (
  id UUID PRIMARY KEY,                    -- Unique user ID
  email VARCHAR UNIQUE NOT NULL,
  encrypted_password VARCHAR,             -- Bcrypt hashed
  email_confirmed_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  raw_user_meta_data JSONB,              -- Custom metadata
  raw_app_meta_data JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  -- ... other Supabase fields
);
```

### 2. Public Schema (Application Data)

#### **roles Table**

```sql
CREATE TABLE public.roles (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT
);

-- Default roles
INSERT INTO roles (id, name, description) VALUES
  (1, 'student', 'Öğrenci'),
  (2, 'teacher', 'Öğretmen'),
  (3, 'admin', 'Yönetici'),
  (4, 'editor', 'Editör');
```

#### **users Table**

```sql
CREATE TABLE public.users (
  -- Primary Key: Auto-increment integer
  id INTEGER PRIMARY KEY DEFAULT nextval('users_id_seq'),
  
  -- Supabase Auth Reference (UUID)
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- User Information
  email VARCHAR(150) UNIQUE NOT NULL,
  name VARCHAR(100),
  school_number VARCHAR(50),
  
  -- Role Reference
  role_id INTEGER NOT NULL DEFAULT 1 REFERENCES roles(id),
  
  -- Legacy field (not used with Supabase Auth)
  password_hash VARCHAR(255),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX idx_users_role_id ON users(role_id);
```

### 3. Row Level Security (RLS) Policies

```sql
-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = auth_user_id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = auth_user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = auth_user_id);
```

### 4. Database Triggers

```sql
-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

---

## 📱 Flutter Implementation

### 1. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Supabase
  supabase_flutter: ^2.8.0
  
  # Local Storage
  shared_preferences: ^2.2.2
  
  # State Management (if used)
  # provider: ^6.1.1
```

### 2. Supabase Initialization (main.dart)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}
```

### 3. Environment Configuration (lib/config/env.dart)

```dart
class AppEnv {
  // Production Supabase
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // Local Supabase (for development)
  // static const String supabaseUrl = 'http://127.0.0.1:54321';
  // static const String supabaseAnonKey = 'your-local-anon-key';
}
```

### 4. Auth Service (lib/services/auth_service.dart)

#### **Complete Implementation:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_manager.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Register new user via Supabase Auth
  /// 
  /// Process:
  /// 1. Create user in auth.users (Supabase Auth)
  /// 2. Create profile in public.users
  /// 3. Save session locally
  static Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? birthDate,
    String userType = 'student',
    int? schoolId,
  }) async {
    try {
      print('DEBUG AUTH: Starting registration via Supabase Auth for $email');

      // Step 1: Register with Supabase Auth
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed - no user returned');
      }

      print('DEBUG AUTH: Supabase Auth registration successful for user: ${response.user!.id}');

      // Step 2: Convert userType to role_id
      // student=1, teacher=2, admin=3, editor=4
      int roleId = 1; // default to student
      switch (userType.toLowerCase()) {
        case 'student':
          roleId = 1;
          break;
        case 'teacher':
          roleId = 2;
          break;
        case 'admin':
          roleId = 3;
          break;
        case 'editor':
          roleId = 4;
          break;
      }

      // Step 3: Create profile in users table
      final profileData = {
        // 'id' is auto-increment, don't send it
        'auth_user_id': response.user!.id, // ✅ UUID from Supabase Auth
        'email': email,
        'name': fullName,
        'school_number': phone,
        'role_id': roleId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profileResponse = await _client
          .from('users')
          .insert(profileData)
          .select()
          .single();

      print('DEBUG AUTH: Profile created successfully');

      // Step 4: Save session
      await SessionManager.saveSession(
        user: profileResponse,
        token: response.session?.accessToken,
      );

      return profileResponse;
    } catch (error) {
      print('DEBUG AUTH: Registration error: $error');
      rethrow;
    }
  }

  /// Login user via Supabase Auth
  /// 
  /// Process:
  /// 1. Authenticate with Supabase Auth
  /// 2. Fetch profile from public.users
  /// 3. Save session locally
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG AUTH: Starting login via Supabase Auth for $email');

      // Step 1: Sign in with Supabase Auth
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw Exception('Login failed - invalid credentials');
      }

      print('DEBUG AUTH: Supabase Auth login successful for user: ${response.user!.id}');

      // Step 2: Get user profile from database
      final profileResponse = await _client
          .from('users')
          .select()
          .eq('auth_user_id', response.user!.id) // ✅ Query by auth_user_id
          .single();

      print('DEBUG AUTH: Profile retrieved successfully');

      // Step 3: Save session
      await SessionManager.saveSession(
        user: profileResponse,
        token: response.session!.accessToken,
      );

      return profileResponse;
    } catch (error) {
      print('DEBUG AUTH: Login error: $error');
      rethrow;
    }
  }

  /// Get current user from Supabase Auth and session
  static Future<Map<String, dynamic>?> getCurrentUser({String? token}) async {
    try {
      print('DEBUG AUTH: Getting current user');

      // Check if user is authenticated with Supabase
      final User? currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('DEBUG AUTH: No authenticated user');
        return null;
      }

      // Try to get from session first
      final sessionUser = await SessionManager.getCurrentUser();
      if (sessionUser != null) {
        print('DEBUG AUTH: User found in session');
        return sessionUser;
      }

      // If not in session, get from database
      final profileResponse = await _client
          .from('users')
          .select()
          .eq('auth_user_id', currentUser.id) // ✅ Query by auth_user_id
          .single();

      // Save to session for next time
      await SessionManager.saveSession(
        user: profileResponse,
        token: _client.auth.currentSession?.accessToken,
      );

      print('DEBUG AUTH: User retrieved from database');
      return profileResponse;
    } catch (error) {
      print('DEBUG AUTH: Get current user error: $error');
      return null;
    }
  }

  /// Logout - clear Supabase session and local session
  static Future<void> logout({String? token}) async {
    try {
      print('DEBUG AUTH: Starting logout');
      
      // Sign out from Supabase Auth
      await _client.auth.signOut();
      
      // Clear local session
      await SessionManager.clearSession();
      
      print('DEBUG AUTH: Logout completed');
    } catch (error) {
      print('DEBUG AUTH: Logout error: $error');
    }
  }

  /// Check if user is logged in (Supabase Auth + Session)
  static Future<bool> isLoggedIn() async {
    try {
      // Check Supabase Auth
      final User? currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Also check session manager
      return await SessionManager.isLoggedIn();
    } catch (error) {
      print('DEBUG AUTH: isLoggedIn error: $error');
      return false;
    }
  }

  /// Get auth state stream
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
```

### 5. Session Manager (lib/services/session_manager.dart)

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionManager {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Save user session to local storage
  static Future<void> saveSession({
    required Map<String, dynamic> user,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_userKey, json.encode(user));
    await prefs.setBool(_isLoggedInKey, true);
    
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    
    print('DEBUG SESSION: Session saved for user: ${user['email']}');
  }

  /// Get current user from session
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn) return null;
    
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    
    return json.decode(userJson) as Map<String, dynamic>;
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Update user data in session
  static Future<void> updateUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
    print('DEBUG SESSION: User data updated');
  }

  /// Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.setBool(_isLoggedInKey, false);
    print('DEBUG SESSION: Session cleared');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
```

### 6. Usage Example (register_screen.dart)

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedUserType = 'student';
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        userType: _selectedUserType,
      );

      if (user != null) {
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            DropdownButton<String>(
              value: _selectedUserType,
              items: ['student', 'teacher'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedUserType = value!);
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ⚙️ Supabase Configuration

### 1. Local Development Setup

#### **Install Supabase CLI:**

```bash
# macOS/Linux
brew install supabase/tap/supabase

# Windows (with Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

#### **Initialize Supabase:**

```bash
cd your-project
supabase init
```

#### **Start Local Supabase:**

```bash
supabase start
```

**Output:**
```
API URL: http://127.0.0.1:54321
Database URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL: http://127.0.0.1:54323
Anon Key: eyJhbGc...
Service Role Key: eyJhbGc...
```

#### **Pull Remote Schema:**

```bash
supabase link --project-ref your-project-id
supabase db pull
```

### 2. Database Migrations

#### **Create Migration:**

```bash
supabase migration new init_auth_tables
```

#### **Apply Migrations:**

```bash
# Local
supabase db reset

# Remote
supabase db push
```

### 3. Environment Variables

#### **.env.example:**

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 📊 Akış Diyagramları

### 1. Registration Flow (Detaylı)

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant SA as Supabase Auth
    participant DB as PostgreSQL
    participant SP as SharedPreferences

    U->>F: Enter email, password, name
    F->>F: Validate input
    F->>SA: signUp(email, password, metadata)
    
    SA->>SA: Hash password (bcrypt)
    SA->>DB: INSERT INTO auth.users
    DB-->>SA: User created (UUID)
    SA-->>F: AuthResponse {user, session}
    
    F->>F: Convert userType to role_id
    F->>DB: INSERT INTO public.users (auth_user_id, email, name, role_id)
    DB-->>F: Profile created
    
    F->>SP: saveSession(user, token)
    SP-->>F: Session saved
    
    F-->>U: Navigate to Home Screen
```

### 2. Login Flow (Detaylı)

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant SA as Supabase Auth
    participant DB as PostgreSQL
    participant SP as SharedPreferences

    U->>F: Enter email, password
    F->>F: Validate input
    F->>SA: signInWithPassword(email, password)
    
    SA->>SA: Validate credentials
    SA->>DB: SELECT FROM auth.users WHERE email=?
    DB-->>SA: User found
    SA->>SA: Verify password hash
    SA-->>F: AuthResponse {user, session(JWT)}
    
    F->>DB: SELECT FROM public.users WHERE auth_user_id=?
    DB-->>F: User profile
    
    F->>SP: saveSession(profile, token)
    SP-->>F: Session saved
    
    F-->>U: Navigate to Home Screen
```

### 3. Session Check Flow

```mermaid
flowchart TD
    A[App Starts] --> B{Check Supabase Auth}
    B -->|No User| C[Show Login Screen]
    B -->|User Exists| D{Check SharedPreferences}
    D -->|No Session| E[Fetch from Database]
    D -->|Session Exists| F[Use Cached Data]
    E --> G[Save to Session]
    F --> H[Navigate to Home]
    G --> H
    C --> I[User Logs In]
    I --> H
```

---

## 🔧 Sorun Giderme

### 1. Common Errors

#### **Error: `invalid input syntax for type integer`**

**Sebep:** `users.id` field'ına UUID göndermeye çalışıyorsunuz.

**Çözüm:**
```dart
// ❌ YANLIŞ
final profileData = {
  'id': response.user!.id,  // UUID
};

// ✅ DOĞRU
final profileData = {
  'auth_user_id': response.user!.id,  // UUID
  // 'id' auto-increment, göndermeyin
};
```

#### **Error: `relation "roles" does not exist`**

**Sebep:** roles tablosu oluşturulmamış.

**Çözüm:**
```sql
-- Migration'a ekle veya manuel çalıştır
CREATE TABLE IF NOT EXISTS roles (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT
);

INSERT INTO roles (id, name, description) VALUES
  (1, 'student', 'Öğrenci'),
  (2, 'teacher', 'Öğretmen'),
  (3, 'admin', 'Yönetici'),
  (4, 'editor', 'Editör')
ON CONFLICT (id) DO NOTHING;
```

#### **Error: `User already registered`**

**Sebep:** Email zaten auth.users'da kayıtlı.

**Çözüm:**
- Farklı bir email kullan
- Veya test için kullanıcıyı sil:
  ```sql
  DELETE FROM auth.users WHERE email = 'test@example.com';
  ```

#### **Error: `Could not find the 'role_id' column`**

**Sebep:** Migration çalışmamış veya tablo yapısı güncel değil.

**Çözüm:**
```bash
supabase db reset  # Local
# veya
supabase db push   # Remote
```

### 2. Docker Issues (Local Development)

#### **Error: `mounts denied: /socket_mnt/...`**

**Sebep:** Docker Desktop file sharing ayarları.

**Çözüm:**
```bash
# Docker context'i değiştir
docker context use default

# Docker Desktop'ı restart et
# Settings → Resources → File Sharing → Add /home
```

### 3. Network Issues

#### **Error: `could not translate host name`**

**Sebep:** DNS veya internet bağlantısı.

**Çözüm:**
```bash
# DNS cache temizle
sudo systemd-resolve --flush-caches

# veya farklı DNS kullan
# /etc/resolv.conf → nameserver 8.8.8.8
```

---

## 🔒 Güvenlik Notları

### 1. Best Practices

#### ✅ **DO:**
- ✅ Supabase Auth kullan (password hashing otomatik)
- ✅ JWT token'ları secure storage'da tut
- ✅ RLS (Row Level Security) aktif et
- ✅ Email verification kullan (production'da)
- ✅ HTTPS kullan (production'da)
- ✅ Rate limiting ekle (brute force prevention)
- ✅ Environment variables kullan (API keys için)

#### ❌ **DON'T:**
- ❌ Password'leri plain text sakla
- ❌ Service role key'i client-side kullan
- ❌ API keys'i hardcode etme
- ❌ RLS bypass etmeye çalışma
- ❌ Token'ları localStorage'a kaydetme (XSS riski)

### 2. RLS (Row Level Security)

**users tablosunda sadece kendi verisini görebilir:**

```sql
-- Kullanıcı sadece kendi profilini görür
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = auth_user_id);

-- Kullanıcı sadece kendi profilini güncelleyebilir
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = auth_user_id);
```

### 3. Token Management

**Access Token** (JWT):
- Short-lived (1 hour default)
- Client-side'da saklanır
- Her istekte gönderilir

**Refresh Token**:
- Long-lived (30 days default)
- Automatic refresh by Supabase SDK
- Secure storage'da tutulur

**Example:**
```dart
// Token otomatik yenilenir
final session = _client.auth.currentSession;
if (session != null) {
  print('Access Token: ${session.accessToken}');
  print('Expires At: ${session.expiresAt}');
}
```

### 4. Email Verification

**Enable in Supabase Dashboard:**

1. Authentication → Settings
2. Enable "Email Confirmations"
3. Configure email templates

**Flutter'da:**
```dart
final response = await _client.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: 'myapp://verify-email',
);

// User receives verification email
// Supabase automatically handles verification
```

---

## 📈 Performance Optimization

### 1. Session Caching

```dart
// İlk önce cache'den kontrol et
final cachedUser = await SessionManager.getCurrentUser();
if (cachedUser != null) {
  return cachedUser;  // Fast return
}

// Cache miss - database'den çek
final user = await _client.from('users').select()...;
await SessionManager.saveSession(user: user, token: token);
```

### 2. Database Indexes

```sql
-- Email lookups için
CREATE INDEX idx_users_email ON users(email);

-- Auth user ID lookups için
CREATE INDEX idx_users_auth_user_id ON users(auth_user_id);

-- Role filtering için
CREATE INDEX idx_users_role_id ON users(role_id);
```

### 3. Connection Pooling

Supabase otomatik olarak connection pooling yapar:
- Max connections: 100 (Free tier)
- Timeout: 30 seconds

---

## 🧪 Testing

### 1. Unit Tests

```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthService', () {
    test('register creates user successfully', () async {
      // Mock Supabase client
      // Test registration flow
    });

    test('login returns valid session', () async {
      // Mock authentication
      // Verify session saved
    });
  });
}
```

### 2. Integration Tests

```bash
flutter test integration_test/auth_flow_test.dart
```

---

## 📚 Additional Resources

### Official Documentation
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart)
- [RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)

### Code Examples
- [Supabase Flutter Auth Example](https://github.com/supabase/supabase-flutter/tree/main/examples)
- [Flutter Auth Flow](https://docs.flutter.dev/cookbook/networking/authenticated-requests)

---

## 📝 Changelog

### v1.0.0 (2025-10-10)
- ✅ Native Supabase Auth implementation
- ✅ Role-based access control
- ✅ Session management with SharedPreferences
- ✅ Local development support
- ✅ RLS policies implemented
- ❌ Removed custom Edge Functions
- ❌ Removed database triggers
- ❌ Removed bcrypt manual hashing

---

## 👥 Contributors

- **Developer:** [Your Name]
- **Documentation:** AI Assistant
- **Date:** October 10, 2025

---

## 📄 License

This implementation follows best practices from Supabase official documentation and Flutter community standards.

---

## 🎯 Next Steps

### Short Term
- [ ] Add password reset functionality
- [ ] Implement email verification
- [ ] Add social login (Google, Apple)
- [ ] Add biometric authentication

### Long Term
- [ ] Multi-factor authentication (MFA)
- [ ] Session management dashboard
- [ ] Audit logging
- [ ] Advanced role permissions

---

**End of Documentation**
