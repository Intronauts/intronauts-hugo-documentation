---
title: "Fonksiyonlar"
weight: 21
---

# Veritabanı Fonksiyonları

Sistemde kullanılan PostgreSQL fonksiyonları ve amaçları.

---

## 📋 Tüm Fonksiyonlar

| Fonksiyon | Dönüş Tipi | Amaç |
|-----------|------------|------|
| `handle_new_auth_user()` | trigger | Supabase Auth'dan users tablosuna otomatik kayıt |
| `generate_class_code()` | trigger | Otomatik benzersiz sınıf kodu üretimi |
| `set_updated_at()` | trigger | Otomatik timestamp güncelleme |
| `delete_class_members_when_a_class_deleted()` | trigger | Sınıf silindiğinde üyelikleri temizleme |
| `join_class_by_code(text)` | json | Öğrencinin kod ile sınıfa katılması |
| `get_student_classes()` | table | Öğrencinin kayıtlı olduğu sınıflar |
| `get_class_students(int)` | table | Sınıftaki öğrenci listesi |
| `get_class_student_count(int)` | int | Sınıftaki öğrenci sayısı |

---

## 🔐 1. Supabase Auth Entegrasyonu

### `handle_new_auth_user()`

**Tip:** Trigger Fonksiyonu  
**Güvenlik:** SECURITY DEFINER (yüksek yetki)

#### Ne İşe Yarar?
Supabase Auth'da yeni kullanıcı kaydı oluştuğunda otomatik olarak `users` tablosuna ekler.

#### Nasıl Çalışır?

1. Kullanıcı Supabase'de kayıt olur
2. Trigger otomatik çalışır
3. Metadata'dan bilgiler alınır:
   - `role` → Varsayılan: "student"
   - `school_id` → Varsayılan: 1
   - `school_number` → Öğrenciler için
   - `birth_date` → Opsiyonel

4. `users` tablosuna kayıt eklenir


#### Özellikler:
- ✅ Duplicate email kontrolü (aynı email tekrar eklenmez)
- ✅ Varsayılan role: "student"
- ✅ Metadata'dan otomatik veri çekme
- ✅ `auth_user_id` ile Supabase Auth'a bağlantı

---

## 🎯 2. Sınıf Yönetimi Fonksiyonları

### `join_class_by_code(p_class_code text)`

**Dönüş Tipi:** JSON  
**Güvenlik:** SECURITY DEFINER

#### Ne İşe Yarar?
Öğrencinin sınıf kodu ile sınıfa katılmasını sağlar.

#### Parametreler:
- `p_class_code` (text): Sınıf kodu (örn: "K7M2X9P1")

#### Kontroller:

1. ✅ **Kullanıcı kontrolü:** Oturum açmış mı?
2. ✅ **Role kontrolü:** Sadece öğrenciler (role_id = 1)
3. ✅ **Sınıf kontrolü:** Kod geçerli mi?
4. ✅ **Okul kontrolü:** Öğrenci ve sınıf aynı okulda mı?
5. ✅ **Üyelik kontrolü:** Öğrenci zaten üye mi?

#### Başarılı Dönüş:
```json
{
  "success": true,
  "message": "Sınıfa başarıyla katıldınız",
  "class_member_id": 123,
  "class_id": 10,
  "class_name": "10-A Matematik",
  "user_school_id": 1,
  "class_school_id": 1
}
```

#### Hata Mesajları:

| Hata | Açıklama |
|------|----------|
| `USER_NOT_FOUND` | Oturum açmanız gerekiyor |
| `INVALID_ROLE` | Sadece öğrenciler sınıfa katılabilir |
| `CLASS_NOT_FOUND` | Geçersiz sınıf kodu |
| `SCHOOL_MISMATCH` | Sınıf farklı bir okula ait |
| `ALREADY_MEMBER` | Zaten bu sınıftasınız |

#### Flutter Kullanımı:

```dart
try {
  final result = await supabase.rpc('join_class_by_code', 
    params: {'p_class_code': 'K7M2X9P1'}
  );
  
  print('Başarı: ${result['message']}');
  print('Sınıf: ${result['class_name']}');
} catch (e) {
  print('Hata: $e');
}
```

---

### `get_student_classes()`

**Dönüş Tipi:** TABLE  
**Güvenlik:** SECURITY DEFINER

#### Ne İşe Yarar?
Giriş yapan öğrencinin kayıtlı olduğu tüm sınıfları döndürür.

#### Dönen Kolonlar:

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Sınıf ID |
| `name` | varchar | Sınıf adı |
| `code` | varchar | Sınıf kodu |
| `academic_year` | varchar | Akademik yıl |
| `term` | varchar | Dönem |
| `school_id` | int | Okul ID |
| `teacher_id` | int | Öğretmen ID |
| `teacher_name` | varchar | Öğretmen adı |
| `teacher_email` | varchar | Öğretmen email |
| `created_at` | timestamptz | Oluşturma tarihi |
| `updated_at` | timestamptz | Güncelleme tarihi |

#### Flutter Kullanımı:

```dart
final classes = await supabase.rpc('get_student_classes');

for (var classItem in classes) {
  print('Sınıf: ${classItem['name']}');
  print('Öğretmen: ${classItem['teacher_name']}');
  print('Kod: ${classItem['code']}');
}
```

---

### `get_class_students(p_class_id int)`

**Dönüş Tipi:** TABLE  
**Güvenlik:** SECURITY DEFINER (RLS bypass)

#### Ne İşe Yarar?
Belirtilen sınıftaki tüm aktif öğrencileri döndürür.

#### Parametreler:
- `p_class_id` (int): Sınıf ID

#### Dönen Kolonlar:

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Öğrenci ID |
| `name` | varchar | Öğrenci adı |
| `email` | varchar | Öğrenci email |
| `school_number` | varchar | Öğrenci numarası |
| `joined_at` | timestamptz | Katılım tarihi |

#### Flutter Kullanımı:

```dart
final students = await supabase.rpc('get_class_students', 
  params: {'p_class_id': 10}
);

print('Toplam öğrenci: ${students.length}');

for (var student in students) {
  print('${student['name']} - ${student['school_number']}');
}
```

---

### `get_class_student_count(p_class_id int)`

**Dönüş Tipi:** INTEGER  
**Güvenlik:** SECURITY DEFINER

#### Ne İşe Yarar?
Sınıftaki aktif öğrenci sayısını döndürür.

#### Parametreler:
- `p_class_id` (int): Sınıf ID

#### Flutter Kullanımı:

```dart
final count = await supabase.rpc('get_class_student_count', 
  params: {'p_class_id': 10}
);

print('Öğrenci sayısı: $count');
```

---

## ⚙️ 3. Yardımcı Fonksiyonlar

### `generate_class_code()`

**Tip:** Trigger Fonksiyonu

#### Ne İşe Yarar?
Sınıf oluşturulurken otomatik benzersiz kod üretir.

#### Özellikler:
- 8 karakter uzunluğunda
- A-Z ve 0-9 karakterlerinden oluşur
- Benzersizlik garantisi
- pgcrypto extension varsa kriptografik random kullanır

**Detaylar:** [Trigger Dokümantasyonu](/docs/database/triggers/)

---

### `set_updated_at()`

**Tip:** Trigger Fonksiyonu

#### Ne İşe Yarar?
Her UPDATE işleminde `updated_at` kolonunu otomatik günceller.

```sql
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
```

---

### `delete_class_members_when_a_class_deleted()`

**Tip:** Trigger Fonksiyonu

#### Ne İşe Yarar?
Sınıf silindiğinde üyelikleri temizler.

```sql
BEGIN
  DELETE FROM class_members 
  WHERE class_id = OLD.id;
  
  RETURN OLD;
END;
```

---

## 🔍 Fonksiyon Sorgulama

### Tüm Fonksiyonları Listeleme

```sql
SELECT 
    routine_name AS function_name,
    data_type AS return_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;
```

### Fonksiyon Detaylarını Görme

```sql
\df+ join_class_by_code
```

### Fonksiyon Kodunu Görme

```sql
SELECT pg_get_functiondef('join_class_by_code'::regproc);
```

---

## ⚠️ Güvenlik Notları

### SECURITY DEFINER Nedir?

Fonksiyonun **sahibinin yetkilerixle** çalışmasını sağlar, çağıran kullanıcının değil.

**Kullanım Amacı:**
- RLS politikalarını bypass etmek
- Öğrencinin başka öğrencilerin bilgilerine erişmesini engellerken, fonksiyonun çalışmasını sağlamak

**Örnek:**
```sql
-- Öğrenci direkt sorgulayamaz (RLS engeller)
SELECT * FROM users WHERE role_id = 2;

-- Ama fonksiyon ile öğretmen bilgisi alabilir
SELECT teacher_name FROM get_student_classes();
```

### SET search_path TO 'public'

SQL injection saldırılarını önlemek için fonksiyonun sadece `public` schema'sını kullanmasını garantiler.

---

## 📚 İlgili Dokümantasyon

- [Trigger'lar](/docs/database/triggers/)
- [RLS Politikaları](/docs/database/policies/)
- [REST API Rehberi](/docs/guides/rest_api_guide_1/)
