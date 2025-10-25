---
title: "Implementation Rehberi"
weight: 35
---

# 📘 Implementasyon Rehberi 

> Bu dokümanda ornek bir sınıfa katılma özelliğinin baştan sona implementasyonu adım adım anlatılmaktadır.

---

## 📋 İçindekiler

1. [Özellik Gereksinimleri](#özellik-gereksinimleri)
2. [Mimari Tasarım](#mimari-tasarım)
3. [Veritabanı Yapısı](#veritabanı-yapısı)
4. [Backend Implementasyon](#backend-implementasyon)
5. [Frontend Implementasyon](#frontend-implementasyon)
6. [Test Stratejisi](#test-stratejisi)

---

## 🎯 Özellik Gereksinimleri

### Kullanıcı Hikayesi

**Öğrenci Olarak:**
```
Öğretmenimin bana verdiği 8 karakterlik sınıf kodunu 
girerek sınıfa otomatik katılabilmeliyim.
```

### Fonksiyonel Gereksinimler

| ID | Gereksinim | Öncelik |
|----|-----------|---------|
| FR-001 | Öğrenci sınıf kodu ile sınıfa katılabilir | 🔴 High |
| FR-002 | Bir öğrenci birden fazla sınıfa katılabilir | 🟡 Medium |
| FR-003 | Öğrenci sınıftan ayrılabilir (soft delete) | 🟡 Medium |
| FR-004 | Sadece kendi okulundaki sınıflara katılabilir | 🔴 High |
| FR-005 | Sadece öğrenciler (role_id=1) katılabilir | 🔴 High |
| FR-006 | Tekrar aynı sınıfa katılamaz | 🟡 Medium |

### Non-Fonksiyonel Gereksinimler

| ID | Gereksinim | Hedef |
|----|-----------|-------|
| NFR-001 | Yanıt süresi | < 2 saniye |
| NFR-002 | Güvenlik | 3 katmanlı (UI/Service/DB) |
| NFR-003 | Kullanılabilirlik | 1 dakikada tamamlanabilir |
| NFR-004 | Hata yönetimi | Kullanıcı dostu mesajlar |

---

## 🏗️ Mimari Tasarım

### Katman Mimarisi

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  ┌───────────────────────────────────┐  │
│  │  JoinClassDialog                  │  │
│  │  StudentClassListScreen           │  │
│  │  ClassListScreen (Updated)        │  │
│  └───────────────────────────────────┘  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│           Service Layer                 │
│  ┌───────────────────────────────────┐  │
│  │  ClassMemberService               │  │
│  │  - joinClassByCode()              │  │
│  │  - getStudentClasses()            │  │
│  │  - leaveClass()                   │  │
│  │  - isStudentInClass()             │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  PermissionService                │  │
│  │  - isStudent()                    │  │
│  │  - canJoinClass()                 │  │
│  └───────────────────────────────────┘  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Data Layer                     │
│  ┌───────────────────────────────────┐  │
│  │  ClassMemberModel                 │  │
│  │  - fromJson()                     │  │
│  │  - toJson()                       │  │
│  │  - isActive getter                │  │
│  └───────────────────────────────────┘  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│       Supabase Backend                  │
│  ┌───────────────────────────────────┐  │
│  │  RLS Policies                     │  │
│  │  Database Functions               │  │
│  │  Triggers                         │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Veri Akışı

```
[Öğrenci] 
    ↓ (Kod Girer: "A2X9K7B1")
[JoinClassDialog]
    ↓ (joinClassByCode çağrısı)
[ClassMemberService]
    ↓ (Permission kontrolü)
[PermissionService]
    ↓ (isStudent() → true)
[ClassMemberService]
    ↓ (RPC call: join_class_by_code)
[Supabase RPC Function]
    ↓ (Validasyonlar)
    1. User authenticated?
    2. Student role?
    3. Class exists?
    4. Same school?
    5. Not already member?
    ↓ (INSERT)
[class_members table]
    ↓ (RLS Policy check)
    ✅ (Success)
    ↓
[ClassMemberService]
    ↓ (Success response)
[JoinClassDialog]
    ↓ (Navigator.pop + refresh)
[StudentClassListScreen]
    ✅ (Yeni sınıf görünür)
```

---

## 💾 Veritabanı Yapısı

### İlgili Tablolar

#### 1. `users` Tablosu
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users(id),
    school_id INTEGER REFERENCES schools(id),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    school_number VARCHAR(50),
    phone_number VARCHAR(20),
    birth_date DATE,
    role_id INTEGER REFERENCES roles(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(school_id, school_number)
);
```

#### 2. `classes` Tablosu
```sql
CREATE TABLE classes (
    id SERIAL PRIMARY KEY,
    school_id INTEGER REFERENCES schools(id),
    teacher_id INTEGER REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL, -- Sınıf kodu
    academic_year VARCHAR(20),
    term VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 3. `class_members` Tablosu (Ana Tablo)
```sql
CREATE TABLE class_members (
    id SERIAL PRIMARY KEY,
    class_id INTEGER REFERENCES classes(id),
    student_id INTEGER REFERENCES users(id),
    joined_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP, -- Soft delete
    
    -- Unique constraint (aktif üyelikler için)
    CONSTRAINT unique_active_membership 
    UNIQUE(class_id, student_id) 
    WHERE deleted_at IS NULL
);

-- Index'ler
CREATE INDEX idx_class_members_student 
ON class_members(student_id, deleted_at);

CREATE INDEX idx_class_members_class 
ON class_members(class_id, deleted_at);
```

#### 4. `roles` Tablosu
```sql
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO roles (id, name) VALUES
(1, 'student'),
(2, 'teacher'),
(3, 'admin'),
(4, 'editor');
```

### Veritabanı Diyagramı

```
┌─────────────┐         ┌─────────────┐
│   schools   │         │    roles    │
├─────────────┤         ├─────────────┤
│ id (PK)     │         │ id (PK)     │
│ name        │         │ name        │
└──────┬──────┘         └──────┬──────┘
       │                       │
       │ ┌─────────────────────┘
       │ │
┌──────▼─▼──────┐
│     users      │
├────────────────┤
│ id (PK)        │◄───────────┐
│ school_id (FK) │            │
│ role_id (FK)   │            │
│ auth_user_id   │            │
│ name           │            │
│ email          │            │
└──────┬─────────┘            │
       │                      │
       │ teacher_id           │
       │                      │
┌──────▼─────────┐            │
│    classes     │            │
├────────────────┤            │
│ id (PK)        │◄───────┐   │
│ school_id (FK) │        │   │
│ teacher_id (FK)│        │   │
│ code (UNIQUE)  │        │   │
│ name           │        │   │
└──────┬─────────┘        │   │
       │            class_id  student_id
       │                  │   │
┌──────▼──────────────────▼───▼──┐
│       class_members             │
├─────────────────────────────────┤
│ id (PK)                         │
│ class_id (FK → classes)         │
│ student_id (FK → users)         │
│ joined_at                       │
│ deleted_at (soft delete)        │
└─────────────────────────────────┘
```

---

## 🔧 Backend Implementasyon

### Step 1: RLS Policies Oluşturma

#### A. `class_members` Tablosu Policies

```sql
-- ============================================
-- class_members RLS Policies
-- ÖNEMLİ: classes tablosuna REFERANS YOK
-- (circular dependency önlenir)
-- ============================================

-- 1. SELECT Policy
CREATE POLICY "users_can_view_memberships"
ON class_members FOR SELECT TO authenticated
USING (
  -- Öğrenciler kendi üyeliklerini görebilir
  student_id IN (
    SELECT id FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id = 1
  )
  OR
  -- Admin/editor tüm üyelikleri görebilir
  EXISTS (
    SELECT 1 FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id IN (3, 4)
  )
);

-- 2. INSERT Policy
CREATE POLICY "authenticated_can_insert_memberships"
ON class_members FOR INSERT TO authenticated
WITH CHECK (
  -- Herkes kendi adına üyelik ekleyebilir
  student_id IN (
    SELECT id FROM users 
    WHERE auth_user_id = auth.uid()
  )
  OR
  -- Admin/editor herkes adına ekleyebilir
  EXISTS (
    SELECT 1 FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id IN (3, 4)
  )
);

-- 3. UPDATE Policy (soft delete için)
CREATE POLICY "students_can_update_own_memberships"
ON class_members FOR UPDATE TO authenticated
USING (
  student_id IN (
    SELECT id FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id = 1
  )
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id IN (3, 4)
  )
)
WITH CHECK (
  student_id IN (
    SELECT id FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id = 1
  )
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE auth_user_id = auth.uid() 
    AND role_id IN (3, 4)
  )
);

-- RLS'yi etkinleştir
ALTER TABLE class_members ENABLE ROW LEVEL SECURITY;
```

#### B. `classes` Tablosu Policies

```sql
-- ============================================
-- classes RLS Policy
-- class_members'a referans VAR ama 
-- o da classes'a DÖNMEZ → döngü yok
-- ============================================

CREATE POLICY "users_can_view_relevant_classes"
ON classes FOR SELECT TO authenticated
USING (
  -- Öğrenciler: Katıldıkları sınıflar
  EXISTS (
    SELECT 1 FROM class_members cm
    INNER JOIN users u ON cm.student_id = u.id
    WHERE cm.class_id = classes.id
      AND u.auth_user_id = auth.uid()
      AND u.role_id = 1
      AND cm.deleted_at IS NULL
  )
  OR
  -- Öğretmenler: Kendi sınıfları
  EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = classes.teacher_id
      AND u.auth_user_id = auth.uid()
      AND u.role_id = 2
  )
  OR
  -- Admin/Editor: Tüm sınıflar
  EXISTS (
    SELECT 1 FROM users u
    WHERE u.auth_user_id = auth.uid()
      AND u.role_id IN (3, 4)
  )
);
```

**⚠️ Circular Dependency Analizi:**
```
class_members SELECT policy:
  → Sadece users tablosuna bakar ✅

classes SELECT policy:
  → class_members + users JOIN yapar
  → AMA class_members policy classes'a dönmez ✅
  
SONUÇ: Döngü yok! ✅
```

### Step 2: Database Function

```sql
-- ============================================
-- join_class_by_code Function
-- Tüm business logic burada
-- ============================================

CREATE OR REPLACE FUNCTION join_class_by_code(
  p_class_code text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id int;
  v_user_role_id int;
  v_user_school_id int;
  v_class_id int;
  v_class_school_id int;
  v_class_name text;
  v_existing_member_id int;
  v_result json;
BEGIN
  -- 1. Mevcut kullanıcıyı al
  SELECT id, role_id, school_id
  INTO v_user_id, v_user_role_id, v_user_school_id
  FROM users
  WHERE auth_user_id = auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Oturum açmanız gerekiyor.'
      USING HINT = 'USER_NOT_FOUND';
  END IF;

  -- 2. Role kontrolü
  IF v_user_role_id != 1 THEN
    RAISE EXCEPTION 'Sadece öğrenciler sınıfa katılabilir.'
      USING HINT = 'INVALID_ROLE';
  END IF;

  -- 3. Sınıfı kod ile bul
  SELECT id, school_id, name
  INTO v_class_id, v_class_school_id, v_class_name
  FROM classes
  WHERE code = UPPER(TRIM(p_class_code));

  IF v_class_id IS NULL THEN
    RAISE EXCEPTION 'Geçersiz sınıf kodu: %', p_class_code
      USING HINT = 'CLASS_NOT_FOUND';
  END IF;

  -- 4. Okul kontrolü (NULL-safe)
  IF COALESCE(v_class_school_id, -1) != COALESCE(v_user_school_id, -2) THEN
    RAISE EXCEPTION 'Bu sınıf farklı bir okula ait.'
      USING HINT = 'SCHOOL_MISMATCH';
  END IF;

  -- 5. Duplicate kontrolü
  SELECT id INTO v_existing_member_id
  FROM class_members
  WHERE class_id = v_class_id
    AND student_id = v_user_id
    AND deleted_at IS NULL;

  IF v_existing_member_id IS NOT NULL THEN
    RAISE EXCEPTION 'Zaten bu sınıftasınız.'
      USING HINT = 'ALREADY_MEMBER';
  END IF;

  -- 6. Sınıfa katıl (INSERT)
  INSERT INTO class_members (class_id, student_id, joined_at)
  VALUES (v_class_id, v_user_id, NOW())
  RETURNING id INTO v_existing_member_id;

  -- 7. Başarı mesajı
  v_result := json_build_object(
    'success', true,
    'message', 'Sınıfa başarıyla katıldınız',
    'class_member_id', v_existing_member_id,
    'class_id', v_class_id,
    'class_name', v_class_name
  );

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM
      USING HINT = SQLSTATE;
END;
$$;

-- Public erişim
GRANT EXECUTE ON FUNCTION join_class_by_code(text) TO authenticated;
```

### Step 3: Auto-Generate Class Code (Trigger)

```sql
-- ============================================
-- Sınıf kodu otomatik üretimi
-- ============================================

CREATE OR REPLACE FUNCTION generate_class_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_code text;
  v_exists boolean;
BEGIN
  -- Kod zaten verilmişse atla
  IF NEW.code IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Benzersiz 8 karakterlik kod üret
  LOOP
    v_code := upper(
      substring(
        md5(random()::text || clock_timestamp()::text) 
        from 1 for 8
      )
    );
    
    -- Kod kullanılıyor mu?
    SELECT EXISTS(
      SELECT 1 FROM classes WHERE code = v_code
    ) INTO v_exists;
    
    EXIT WHEN NOT v_exists;
  END LOOP;

  NEW.code := v_code;
  RETURN NEW;
END;
$$;

-- Trigger'ı ekle
CREATE TRIGGER set_class_code
  BEFORE INSERT ON classes
  FOR EACH ROW
  EXECUTE FUNCTION generate_class_code();
```

---

## 📱 Frontend Implementasyon

### Step 1: Data Model

```dart
// lib/data/models/class_member_model.dart

class ClassMemberModel {
  final int? id;
  final int classId;
  final int studentId;
  final DateTime joinedAt;
  final DateTime? deletedAt;
  
  // İlişkili veriler
  final Map<String, dynamic>? classData;
  final Map<String, dynamic>? studentData;

  ClassMemberModel({
    this.id,
    required this.classId,
    required this.studentId,
    required this.joinedAt,
    this.deletedAt,
    this.classData,
    this.studentData,
  });

  // Soft delete kontrolü
  bool get isActive => deletedAt == null;

  // JSON serialization
  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      id: json['id'] as int?,
      classId: json['class_id'] as int,
      studentId: json['student_id'] as int,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
      classData: json['classes'] as Map<String, dynamic>?,
      studentData: json['students'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'student_id': studentId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonFull() {
    return {
      'id': id,
      ...toJson(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  ClassMemberModel copyWith({
    int? id,
    int? classId,
    int? studentId,
    DateTime? joinedAt,
    DateTime? deletedAt,
    Map<String, dynamic>? classData,
    Map<String, dynamic>? studentData,
  }) {
    return ClassMemberModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      joinedAt: joinedAt ?? this.joinedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      classData: classData ?? this.classData,
      studentData: studentData ?? this.studentData,
    );
  }
}
```

### Step 2: Service Layer

```dart
// lib/services/class_member_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ClassMemberService {
  final _client = Supabase.instance.client;

  /// Sınıf kodunu kullanarak sınıfa katıl
  /// 
  /// Returns: Success mesajı
  /// Throws: Exception on error
  Future<Map<String, dynamic>> joinClassByCode(String classCode) async {
    try {
      // RPC function çağrısı
      final response = await _client.rpc(
        'join_class_by_code',
        params: {'p_class_code': classCode.toUpperCase().trim()},
      );

      if (response == null) {
        throw Exception('Sunucudan yanıt alınamadı');
      }

      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      // Supabase hatası
      throw _handlePostgrestException(e);
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  /// Öğrencinin tüm sınıflarını getir
  Future<List<ClassModel>> getStudentClasses() async {
    try {
      final user = await SessionManager.getCurrentUser();
      final userId = user['id'] as int;

      final response = await _client
          .from('class_members')
          .select('*, classes(*)')
          .eq('student_id', userId)
          .isFilter('deleted_at', null)
          .order('joined_at', ascending: false);

      return (response as List)
          .map((item) => ClassModel.fromJson(item['classes']))
          .toList();
    } catch (e) {
      throw Exception('Sınıflar getirilemedi: $e');
    }
  }

  /// Sınıftan ayrıl (soft delete)
  Future<void> leaveClass(int classId) async {
    try {
      final user = await SessionManager.getCurrentUser();
      final userId = user['id'] as int;

      await _client
          .from('class_members')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('class_id', classId)
          .eq('student_id', userId)
          .isFilter('deleted_at', null);
    } catch (e) {
      throw Exception('Sınıftan ayrılınamadı: $e');
    }
  }

  /// Öğrenci belirli bir sınıfta mı?
  Future<bool> isStudentInClass(int classId, [int? studentId]) async {
    try {
      final user = await SessionManager.getCurrentUser();
      final userId = studentId ?? (user['id'] as int);

      final response = await _client
          .from('class_members')
          .select('id')
          .eq('class_id', classId)
          .eq('student_id', userId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Öğrencinin toplam sınıf sayısı
  Future<int> getStudentClassCount() async {
    try {
      final classes = await getStudentClasses();
      return classes.length;
    } catch (e) {
      return 0;
    }
  }

  /// PostgrestException hatalarını handle et
  Exception _handlePostgrestException(PostgrestException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('user_not_found')) {
      return Exception('Oturum açmanız gerekiyor');
    }
    if (message.contains('invalid_role')) {
      return Exception('Sadece öğrenciler sınıfa katılabilir');
    }
    if (message.contains('class_not_found')) {
      return Exception('Geçersiz sınıf kodu');
    }
    if (message.contains('school_mismatch')) {
      return Exception('Bu sınıf farklı bir okula ait');
    }
    if (message.contains('already_member')) {
      return Exception('Zaten bu sınıftasınız');
    }
    
    return Exception('Bir hata oluştu: ${e.message}');
  }
}
```

### Step 3: UI Implementation

#### A. Join Class Dialog

```dart
// lib/presentation/screens/join_class_dialog.dart

class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({Key? key}) : super(key: key);

  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _service = ClassMemberService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.class_, color: Colors.blue),
          SizedBox(width: 8),
          Text('Sınıfa Katıl'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Öğretmeninizin size verdiği 8 karakterlik sınıf kodunu girin:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Sınıf Kodu',
                hintText: 'A2X9K7B1',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sınıf kodu boş olamaz';
                }
                if (value.length != 8) {
                  return 'Sınıf kodu 8 karakter olmalıdır';
                }
                if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
                  return 'Sadece harf ve rakam kullanılabilir';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinClass,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Katıl'),
        ),
      ],
    );
  }

  Future<void> _joinClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.toUpperCase().trim();
      final result = await _service.joinClassByCode(code);

      if (mounted) {
        Navigator.pop(context, true); // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sınıfa katıldınız'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
```

#### B. Student Class List Screen

```dart
// lib/presentation/screens/student_class_list_screen.dart

class StudentClassListScreen extends StatefulWidget {
  const StudentClassListScreen({Key? key}) : super(key: key);

  @override
  State<StudentClassListScreen> createState() => _StudentClassListScreenState();
}

class _StudentClassListScreenState extends State<StudentClassListScreen> {
  final _service = ClassMemberService();
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classes = await _service.getStudentClasses();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _classes.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showJoinDialog,
              icon: const Icon(Icons.add),
              label: const Text('Sınıfa Katıl'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClasses,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView.builder(
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final classItem = _classes[index];
          return Dismissible(
            key: Key('class_${classItem.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) => _confirmLeave(classItem),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ClassCard(
              classModel: classItem,
              onTap: () => _navigateToDetail(classItem),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Henüz Sınıfınız Yok',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Öğretmeninizden sınıf kodu alarak\nkatılabilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.add),
            label: const Text('Sınıfa Katıl'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const JoinClassDialog(),
    );

    if (result == true) {
      _loadClasses(); // Refresh list
    }
  }

  Future<bool> _confirmLeave(ClassModel classItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıftan Ayrıl'),
        content: Text(
          '${classItem.name} sınıfından ayrılmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.leaveClass(classItem.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sınıftan ayrıldınız'),
              backgroundColor: Colors.green,
            ),
          ),
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    return false;
  }

  void _navigateToDetail(ClassModel classItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(classId: classItem.id),
      ),
    );
  }
}
```

### Step 4: Role-Based Routing

```dart
// lib/presentation/screens/class_list_screen.dart

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({Key? key}) : super(key: key);

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserRoleAndRedirect();
  }

  Future<void> _checkUserRoleAndRedirect() async {
    try {
      final user = await SessionManager.getCurrentUser();
      final roleId = user['role_id'] as int;

      if (roleId == 1) {
        // Öğrenci → StudentClassListScreen'e yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentClassListScreen(),
            ),
          );
        }
      }
      // Öğretmen/admin/editor normal akışta devam
    } catch (e) {
      // Hata durumunda login'e yönlendir
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Öğretmen/admin/editor için normal ekran
    return Scaffold(
      appBar: AppBar(title: const Text('Sınıflar')),
      body: const TeacherClassList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-class');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 🧪 Test Stratejisi

### Unit Tests

```dart
// test/services/class_member_service_test.dart

void main() {
  group('ClassMemberService', () {
    test('joinClassByCode should return success', () async {
      // Arrange
      final service = ClassMemberService();
      
      // Act
      final result = await service.joinClassByCode('A2X9K7B1');
      
      // Assert
      expect(result['success'], true);
      expect(result['message'], isNotNull);
    });

    test('joinClassByCode should throw on invalid code', () async {
      // Arrange
      final service = ClassMemberService();
      
      // Act & Assert
      expect(
        () => service.joinClassByCode('INVALID'),
        throwsException,
      );
    });

    test('getStudentClasses should return list', () async {
      // Arrange
      final service = ClassMemberService();
      
      // Act
      final classes = await service.getStudentClasses();
      
      // Assert
      expect(classes, isList);
    });
  });
}
```

### Integration Tests

```dart
// integration_test/join_class_flow_test.dart

void main() {
  testWidgets('Complete join class flow', (tester) async {
    // 1. Login as student
    await tester.pumpWidget(MyApp());
    await tester.enterText(find.byKey(Key('email')), 'student@test.com');
    await tester.enterText(find.byKey(Key('password')), 'password');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 2. Open join dialog
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 3. Enter class code
    await tester.enterText(find.byKey(Key('class_code')), 'A2X9K7B1');
    await tester.tap(find.text('Katıl'));
    await tester.pumpAndSettle();

    // 4. Verify success
    expect(find.text('Sınıfa katıldınız'), findsOneWidget);
    expect(find.byType(ClassCard), findsWidgets);
  });
}
```

---

## 📝 Checklist

### Backend
- [ ] RLS policies oluşturuldu
- [ ] `join_class_by_code` function oluşturuldu
- [ ] Auto-generate trigger eklendi
- [ ] Circular dependency çözüldü
- [ ] RLS etkinleştirildi

### Frontend
- [ ] ClassMemberModel oluşturuldu
- [ ] ClassMemberService oluşturuldu
- [ ] JoinClassDialog oluşturuldu
- [ ] StudentClassListScreen oluşturuldu
- [ ] Role-based routing eklendi

### Testing
- [ ] Unit tests yazıldı
- [ ] Integration tests yazıldı
- [ ] Manual test senaryoları tamamlandı
- [ ] Edge cases test edildi

---

## 🚀 Deployment

### Production Checklist
1. [ ] Environment variables ayarlandı
2. [ ] RLS policies production'da aktif
3. [ ] Debug logları kapatıldı
4. [ ] Error tracking (Sentry) entegre edildi
5. [ ] Performance monitoring aktif

---

**Sonraki Adım:** [Supabase Teknik Detaylar](../technical/01_supabase_setup.md)
