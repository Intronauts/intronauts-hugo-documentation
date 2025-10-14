---
title: "Users Tablosu Politikaları"
weight: 1
---

# 👥 Users Tablosu RLS Politikaları

Users tablosu için Row Level Security politikalarının detaylı açıklamaları.

---

## Aktif Politikalar

### 1. Users can view own profile

Kullanıcılar sadece kendi profillerini görüntüleyebilir.

```sql
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = auth_user_id);
```

**Amaç**: Kullanıcının kendi profil bilgilerine erişmesini sağlar.

**Koşul**: Giriş yapmış kullanıcının UUID'si ile users tablosundaki auth_user_id eşleşmelidir.

---

### 2. Users can insert own profile

Kullanıcılar sadece kendi profillerini oluşturabilir.

```sql
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = auth_user_id);
```

**Amaç**: Kullanıcının kendi profil kaydını oluşturmasını sağlar.

**Koşul**: Eklenen kaydın auth_user_id'si, giriş yapmış kullanıcının UUID'si ile eşleşmelidir.

---

### 3. Users can update own profile

Kullanıcılar sadece kendi profillerini güncelleyebilir.

```sql
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = auth_user_id);
```

**Amaç**: Kullanıcının kendi profil bilgilerini güncellemesini sağlar.

**Koşul**: Güncellenecek kaydın auth_user_id'si, giriş yapmış kullanıcının UUID'si ile eşleşmelidir.

---

## İlave Politikalar (Planlanan)

### Admins can view all users

```sql
-- İçeriği buraya ekleyiniz
```

### Teachers can view same school students

```sql
-- İçeriği buraya ekleyiniz
```

---

## Test Senaryoları

### Başarılı Senaryo
```sql
-- Kullanıcı kendi profilini görüntüler
SELECT * FROM users WHERE id = current_user_id;
-- ✅ Başarılı
```

### Başarısız Senaryo
```sql
-- Kullanıcı başka birinin profilini görüntülemeye çalışır
SELECT * FROM users WHERE id = other_user_id;
-- ❌ Boş sonuç döner (RLS tarafından filtrelenir)
```

---

## İlgili Tablolar

- `auth.users`
- `public.users`
- `public.roles`

---

## Notlar

- ✅ Giriş yapmış kullanıcılar için geçerli
- ✅ Auth entegrasyonu gerekli
- ⚠️ Admin yetkisi için ayrı politika eklenmelidir
