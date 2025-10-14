---
title: "SQL Dosyaları"
weight: 11
---

# SQL Migration Dosyaları

Bu bölümde veritabanı kurulumu için gerekli SQL dosyalarını bulabilirsiniz.

## Kurulum Sırası

SQL dosyalarını aşağıdaki sırada çalıştırmalısınız:

### 1. Temel Veritabanı Yapısı
**Dosya:** `1-create_database.sql`

Bu dosya şunları içerir:
- 12 ana tablo (schools, users, roles, permissions, vb.)
- ENUM tipleri (exam_status, paper_status)
- Foreign key ilişkileri
- Temel constraint'ler

### 2. Roller ve İzinler
**Dosya:** `2-roller_ve_izinler_olustur.sql`

Bu dosya şunları içerir:
- 4 ana rol (student, teacher, admin, editor)
- 46 detaylı izin sistemi
- Rol-izin eşleştirmeleri

### 3. Auth UUID Kolonu
**Dosya:** `3-usera_uuid_sutunu_ekle.sql`

Bu dosya şunları içerir:
- Users tablosuna `auth_user_id` kolonu ekleme
- Supabase Auth entegrasyonu için gerekli alan

### 4. Auth Trigger Sistemi
**Dosya:** `4-auth_ile_user_bağlama.sql`

Bu dosya şunları içerir:
- `handle_new_auth_user()` fonksiyonu
- Otomatik kullanıcı oluşturma trigger'ı
- Meta data'dan rol ve okul bilgisi çıkarma

### 5. Sınıf Kodu Üretici
**Dosya:** `5-class_code_generator.sql`

Bu dosya şunları içerir:
- `generate_unique_class_code()` fonksiyonu
- Otomatik 8 karakterlik benzersiz kod üretimi
- Sınıf oluşturma trigger'ı

## Dosya İçerikleri

### 1-create_database.sql

```sql
-- Temel veritabanı yapısı
-- Schools, Users, Roles, Permissions, Classes, Exams, vb.
-- Multi-tenant okul yönetimi
-- Soft delete desteği
-- Performans indeksleri
```

[Dosyayı görüntüle](./1-create_database.sql)

### 2-roller_ve_izinler_olustur.sql

```sql
-- 4 Ana Rol:
-- 1. student (Öğrenci)
-- 2. teacher (Öğretmen)  
-- 3. admin (Yönetici)
-- 4. editor (Editör/Gözetmen)

-- 46 Detaylı İzin:
-- class:create, class:view, class:update, class:delete
-- exam:create, exam:upload_papers, exam:evaluate
-- student:view_own_results, student:join_class
-- vb.
```

[Dosyayı görüntüle](./2-roller_ve_izinler_olustur.sql)

### 3-usera_uuid_sutunu_ekle.sql

```sql
-- Users tablosuna auth_user_id kolonu ekleme
ALTER TABLE users ADD COLUMN auth_user_id UUID;
ALTER TABLE users ADD CONSTRAINT fk_auth_user 
  FOREIGN KEY (auth_user_id) REFERENCES auth.users(id);
```

[Dosyayı görüntüle](./3-usera_uuid_sutunu_ekle.sql)

### 4-auth_ile_user_bağlama.sql

```sql
-- Otomatik kullanıcı oluşturma sistemi
CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Auth.users'dan public.users'a otomatik kullanıcı oluşturma
  -- Meta data'dan rol, okul, öğrenci numarası çıkarma
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

[Dosyayı görüntüle](./4-auth_ile_user_bağlama.sql)

### 5-class_code_generator.sql

```sql
-- Otomatik sınıf kodu üretici
CREATE OR REPLACE FUNCTION generate_unique_class_code()
RETURNS TEXT AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  -- 8 karakterlik alfanumerik benzersiz kod üretimi
  -- Duplicate kod kontrolü
END;
$$ LANGUAGE plpgsql;
```

[Dosyayı görüntüle](./5-class_code_generator.sql)

## Remote Database Schema

Tam veritabanı şemasını içeren dosya:

[Remote_DB_Schema.sql](./Remote_DB_Schema.sql)

## Kurulum Komutu

### Supabase'de Kurulum

1. Supabase Dashboard > SQL Editor
2. Dosyaları sırayla kopyala-yapıştır ve çalıştır

### PostgreSQL'de Kurulum

```bash
# Veritabanı oluştur
createdb ai_exam_system

# SQL dosyalarını sırayla çalıştır
psql -U postgres -d ai_exam_system -f 1-create_database.sql
psql -U postgres -d ai_exam_system -f 2-roller_ve_izinler_olustur.sql
psql -U postgres -d ai_exam_system -f 3-usera_uuid_sutunu_ekle.sql
psql -U postgres -d ai_exam_system -f 4-auth_ile_user_bağlama.sql
psql -U postgres -d ai_exam_system -f 5-class_code_generator.sql
```

## Doğrulama

Kurulumdan sonra aşağıdaki komutlarla kontrol edin:

```sql
-- Tabloları listele
\dt

-- Rolleri kontrol et
SELECT * FROM roles;

-- İzinleri kontrol et
SELECT COUNT(*) FROM permissions; -- 46 olmalı

-- Triggerları kontrol et
SELECT trigger_name, event_object_table 
FROM information_schema.triggers;

-- İndeksleri kontrol et
\di+ idx_*
```
