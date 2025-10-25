---
title: "RLS Politikaları"
weight: 22
---

# Row Level Security (RLS) Politikaları

Veritabanı seviyesinde güvenlik kontrolü sağlayan politikalar.

---

## 🔐 RLS Nedir?

**Row Level Security (RLS)**, PostgreSQL'in satır seviyesinde erişim kontrolü özelliğidir.

### Nasıl Çalışır?

Her kullanıcı için otomatik olarak WHERE koşulları eklenir:

```sql
-- Öğretmen şunu çalıştırır:
SELECT * FROM classes;

-- PostgreSQL bunu çalıştırır:
SELECT * FROM classes 
WHERE teacher_id IN (
  SELECT id FROM users WHERE auth_user_id = auth.uid()
);
```

### Avantajları:
- ✅ Uygulama katmanından bağımsız güvenlik
- ✅ SQL injection'a karşı koruma
- ✅ Centralized (merkezi) güvenlik kuralları
- ✅ Supabase otomatik uygulaması

---

## 📋 Tüm Politikalar

### Classes Tablosu

| Politika | Operasyon | Kural |
|----------|-----------|-------|
| `Ogretmen Kendi Siniflarini Goruntuleyebilir` | SELECT | Sadece kendi sınıfları |
| `teachers_admins_editors_can_create_classes` | INSERT | Öğretmen/Admin/Editör |
| `owners_can_update_classes` | UPDATE | Sınıf sahibi |
| `owners_can_delete_classes` | DELETE | Sınıf sahibi |

### Class Members Tablosu

| Politika | Operasyon | Kural |
|----------|-----------|-------|
| `users_can_view_memberships` | SELECT | Kendi üyelikleri veya admin |
| `Teachers can view their own students` | SELECT | Öğretmen kendi sınıflarını |
| `authenticated_can_insert_memberships` | INSERT | Kendini ekleyebilir |
| `students_can_update_own_memberships` | UPDATE | Kendi üyeliğini |
| `Teachers can remove students from their own classes` | DELETE | Öğretmen kendi sınıfından |
| `simple_delete_policy` | DELETE | Öğretmen/Admin/Editör |

### Schools Tablosu

| Politika | Operasyon | Kural |
|----------|-----------|-------|
| `anyone_can_view_schools` | SELECT | Herkes görüntüleyebilir (public) |

---

## 🎓 Classes Tablosu Politikaları

### 1. SELECT - Sınıfları Görüntüleme

```sql
CREATE POLICY "Ogretmen Kendi Siniflarini Goruntuleyebilir"
ON classes FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users u
    WHERE u.auth_user_id = auth.uid()
      AND u.id = classes.teacher_id
  )
);
```

**Kural:** Sadece sınıfın öğretmeni görüntüleyebilir.

**Flutter Örneği:**
```dart
// Öğretmen sadece kendi sınıflarını görecek
final classes = await supabase
    .from('classes')
    .select();
```

---

### 2. INSERT - Sınıf Oluşturma

```sql
CREATE POLICY "teachers_admins_editors_can_create_classes"
ON classes FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid()
      AND id = classes.teacher_id
      AND role_id IN (2, 3, 4)  -- Teacher, Admin, Editor
  )
);
```

**Kural:** Sadece öğretmen, admin ve editörler sınıf oluşturabilir.

**Flutter Örneği:**
```dart
// Öğretmen sınıf oluşturur
final teacherId = 5; // Giriş yapan öğretmenin ID'si

await supabase.from('classes').insert({
  'school_id': 1,
  'teacher_id': teacherId,
  'name': '10-A Matematik',
  'academic_year': '2024-2025',
  'term': 'Güz',
});
```

---

### 3. UPDATE - Sınıf Güncelleme

```sql
CREATE POLICY "owners_can_update_classes"
ON classes FOR UPDATE
TO authenticated
USING (
  teacher_id IN (
    SELECT id FROM users 
    WHERE auth_user_id = auth.uid() AND role_id = 2
  )
  OR EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid() 
      AND role_id IN (3, 4)  -- Admin, Editor
  )
);
```

**Kural:** Sınıf sahibi veya admin/editör güncelleyebilir.

---

### 4. DELETE - Sınıf Silme

```sql
CREATE POLICY "owners_can_delete_classes"
ON classes FOR DELETE
TO authenticated
USING (
  teacher_id IN (
    SELECT id FROM users 
    WHERE auth_user_id = auth.uid() AND role_id = 2
  )
  OR EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid() 
      AND role_id IN (3, 4)
  )
);
```

**Kural:** Sınıf sahibi veya admin/editör silebilir.

---

## 👥 Class Members Tablosu Politikaları

### 1. SELECT - Üyelikleri Görüntüleme

**İki politika var:**

#### a) Öğrenci Kendi Üyeliklerini Görür
```sql
CREATE POLICY "users_can_view_memberships"
ON class_members FOR SELECT
TO authenticated
USING (
  student_id IN (
    SELECT id FROM users
    WHERE auth_user_id = auth.uid() AND role_id = 1
  )
  OR EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid() 
      AND role_id IN (3, 4)  -- Admin, Editor
  )
);
```

#### b) Öğretmen Kendi Sınıflarını Görür
```sql
CREATE POLICY "Teachers can view their own students"
ON class_members FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM classes c
    JOIN users u ON u.id = c.teacher_id
    WHERE c.id = class_members.class_id
      AND u.auth_user_id = auth.uid()
      AND u.role_id = 2
  )
  OR EXISTS (
    SELECT 1 FROM users u
    WHERE u.auth_user_id = auth.uid()
      AND u.role_id IN (3, 4)
  )
  OR EXISTS (
    SELECT 1 FROM users u
    WHERE u.auth_user_id = auth.uid()
      AND u.id = class_members.student_id
      AND u.role_id = 1
  )
);
```

**Flutter Örneği:**
```dart
// Öğretmen kendi sınıflarının üyelerini görecek
final members = await supabase
    .from('class_members')
    .select('*, users(*)')
    .eq('class_id', 10);

// Öğrenci sadece kendi üyeliklerini görecek
final myMemberships = await supabase
    .from('class_members')
    .select('*, classes(*)');
```

---

### 2. INSERT - Üyelik Ekleme

```sql
CREATE POLICY "authenticated_can_insert_memberships"
ON class_members FOR INSERT
TO authenticated
WITH CHECK (
  student_id IN (
    SELECT id FROM users WHERE auth_user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid() 
      AND role_id IN (3, 4)
  )
);
```

**Kural:** Kullanıcı sadece kendini ekleyebilir veya admin/editör herhangi birini ekleyebilir.

**Not:** Öğrenciler genellikle `join_class_by_code()` fonksiyonunu kullanır.

---

### 3. DELETE - Üyelik Silme

**İki politika var:**

#### a) Öğretmen Kendi Sınıfından Çıkarır
```sql
CREATE POLICY "Teachers can remove students from their own classes"
ON class_members FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM classes c
    JOIN users u ON u.id = c.teacher_id
    WHERE c.id = class_members.class_id
      AND u.auth_user_id = auth.uid()
      AND u.role_id = 2
  )
  OR EXISTS (
    SELECT 1 FROM users u
    WHERE u.auth_user_id = auth.uid()
      AND u.role_id IN (3, 4)
  )
  OR EXISTS (
    SELECT 1 FROM users u
    WHERE u.auth_user_id = auth.uid()
      AND u.id = class_members.student_id
      AND u.role_id = 1
  )
);
```

#### b) Basit Silme (Öğretmen/Admin/Editör)
```sql
CREATE POLICY "simple_delete_policy"
ON class_members FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid() 
      AND role_id IN (2, 3, 4)
  )
);
```

**Flutter Örneği:**
```dart
// Öğretmen öğrenciyi sınıftan çıkarır
await supabase
    .from('class_members')
    .delete()
    .eq('id', membershipId);

// Öğrenci sınıftan ayrılır (soft delete)
await supabase
    .from('class_members')
    .update({'deleted_at': DateTime.now().toIso8601String()})
    .eq('id', myMembershipId);
```

---

## 🏫 Schools Tablosu Politikası

### Public Read Access

```sql
CREATE POLICY "anyone_can_view_schools"
ON schools FOR SELECT
TO public
USING (true);
```

**Kural:** Herkes okul listesini görüntüleyebilir (kayıt olmadan bile).

**Neden?** Kayıt sırasında öğrencilerin okullarını seçebilmeleri için.

**Flutter Örneği:**
```dart
// Giriş yapmadan okul listesi
final schools = await supabase
    .from('schools')
    .select();

// Kayıt ekranında kullan
DropdownButton<int>(
  items: schools.map((school) => 
    DropdownMenuItem(
      value: school['id'],
      child: Text(school['name']),
    )
  ).toList(),
);
```

---

## 🔧 RLS Yönetimi

### RLS'i Etkinleştirme

```sql
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
```

### RLS'i Devre Dışı Bırakma

```sql
ALTER TABLE classes DISABLE ROW LEVEL SECURITY;
```

⚠️ **Dikkat:** Production'da asla devre dışı bırakmayın!

### Tüm Politikaları Listeleme

```sql
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### Politika Silme

```sql
DROP POLICY "Ogretmen Kendi Siniflarini Goruntuleyebilir" ON classes;
```

---



## ⚠️ Önemli Notlar

### 1. SECURITY DEFINER Fonksiyonlar

RLS politikalarını bypass etmek için kullanılır:

```sql
CREATE FUNCTION get_class_students(p_class_id int)
RETURNS TABLE(...)
LANGUAGE plpgsql
SECURITY DEFINER  -- ← RLS bypass
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT ...
  FROM class_members cm
  WHERE cm.class_id = p_class_id;
END;
$$;
```

**Neden Gerekli?**  
Öğretmen, öğrenci bilgilerini görmeli ama öğrenci başka öğrencileri görmemeli.




## 📚 İlgili Dokümantasyon

- [Fonksiyonlar](/docs/database/functions/)
- [Trigger'lar](/docs/database/triggers/)
- [RBAC Güvenlik Sistemi](/docs/reference/01_rbac_security/)
