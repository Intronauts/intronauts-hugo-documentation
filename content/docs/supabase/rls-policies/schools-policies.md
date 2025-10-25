---
title: "Schools Tablosu Politikaları"
weight: 4
---

# 🏫 Schools Tablosu RLS Politikaları

Schools (Okullar) tablosu için Row Level Security politikalarının detaylı açıklamaları.

---

## RLS Durumu

```sql
ALTER TABLE "public"."schools" ENABLE ROW LEVEL SECURITY;
```

---

## Aktif Politikalar

### 1. anyone_can_view_schools

Herkes okul listesini görüntüleyebilir (public okul bilgileri).

```sql
CREATE POLICY "anyone_can_view_schools" 
ON "public"."schools" 
FOR SELECT 
USING (true);
```

**Amaç**: Okul listesinin herkese açık olmasını sağlar.

**Koşullar**: 
- **Herkes**: Giriş yapmış veya yapmamış tüm kullanıcılar okul listesini görebilir
- **Güvenlik**: Sadece SELECT (okuma) yetkisi vardır, INSERT/UPDATE/DELETE yoktur

---

## Kullanım Senaryoları

### Kayıt Sırasında Okul Seçimi

```sql
-- Tüm okulları listele (kayıt ekranında)
SELECT id, name, city FROM schools ORDER BY name;
```

### Flutter/Dart'tan Kullanım

```dart
// Okul listesini çek (authentication gerekmez)
final schools = await supabase
  .from('schools')
  .select('id, name, city, district')
  .order('name');

// Dropdown/Picker için kullan
```

---

## Güvenlik Notları

- **Public Read**: Bu tablo herkese açık okunabilirdir
- **Write Protection**: INSERT/UPDATE/DELETE işlemleri için ek politikalar tanımlanmalıdır
- **Admin-Only Writes**: Okul eklemek/düzenlemek sadece admin/superuser'a açıktır (henüz politika tanımlanmamış, database seviyesinde korunur)

---

## Planlanan Politikalar

Gelecekte eklenebilecek politikalar:

```sql
-- Adminler okul ekleyebilir
CREATE POLICY "admins_can_insert_schools" 
ON "public"."schools" 
FOR INSERT 
TO "authenticated"
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid()
    AND role_id IN (3, 4)  -- Admin veya Editor
  )
);

-- Adminler okul güncelleyebilir
CREATE POLICY "admins_can_update_schools" 
ON "public"."schools" 
FOR UPDATE 
TO "authenticated"
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid()
    AND role_id IN (3, 4)
  )
);
```

---

## Multi-Tenant Mimari

Schools tablosu, multi-tenant mimarinin temelini oluşturur:

- Her kullanıcı bir okula bağlıdır (`users.school_id`)
- Her sınıf bir okula bağlıdır (`classes.school_id`)
- Öğrenciler sadece kendi okullarındaki sınıflara katılabilir (`join_class_by_code()` fonksiyonunda kontrol edilir)

---

## İlgili Tablolar

- **users**: Her kullanıcı bir okula bağlı
- **classes**: Her sınıf bir okula bağlı
- **class_members**: Öğrenci-sınıf ilişkisi, okul kontrolü ile sınırlandırılmış

---

## Roller (role_id)

- **1**: Student (Öğrenci) - Okulları görüntüleyebilir
- **2**: Teacher (Öğretmen) - Okulları görüntüleyebilir
- **3**: Admin (Yönetici) - Okul ekleyebilir/düzenleyebilir (gelecek)
- **4**: Editor (Editör) - Okul ekleyebilir/düzenleyebilir (gelecek)
