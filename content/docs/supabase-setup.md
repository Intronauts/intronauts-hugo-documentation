---
title: "Supabase Kurulum Rehberi"
weight: 15
---

# 🧠 AI Exam Evaluation System - Supabase Kurulum Rehberi

**Yazar:** Mehmet Ali GÜMÜŞLER  
**Versiyon:** v3.3 (Final Extended)  
**Tarih:** 10 Ekim 2025  

---

## 🎯 Amaç

Bu dokümantasyon, sistemin ilk ve en temel bileşeni olan **Supabase altyapısının** adım adım nasıl kurulduğunu belgelemektedir. Amaç: Gerektiğinde Supabase'i sıfırdan yeniden kurabilmek.

---

## 🪜 1️⃣ Proje Oluşturma

1. [https://supabase.com](https://supabase.com) adresinden giriş yapın
2. **New Project** oluşturun → isim: `ai-exam-system`
3. Veritabanı parolası belirleyin → güvenli bir şifre seçin ve not edin
4. Bölge (Region): `eu-north-1` veya size yakın bir bölge seçin
5. Oluşturma sonrası şunları kaydedin:
   - Project URL
   - Database Şifresi
   - anon public key
   - service_role key

📁 Bu bilgiler `.env` dosyasında veya Flutter / Web client konfigürasyonlarında kullanılacak.

---

## 🧱 2️⃣ Veritabanı Şemasının Yüklenmesi

### SQL Editor'da Sırayla Çalıştırılacak Dosyalar:

#### 1️⃣ Temel Veritabanı Yapısı
- **Dosya:** [1-create_database.sql](/docs/database/sql/)
- **İçerik:** v3.3 Final Extended şema
- **Özellikler:**
  - Multi-tenant okul yönetimi (`schools` tablosu)
  - Soft delete desteği (`class_members.deleted_at`)
  - Performans indeksleri
  - Otomatik `updated_at` triggerları

✔️ Oluşan tablolar:
```
schools (yeni - multi-tenant için)
users  
roles
permissions  
role_permissions
classes  
class_members (soft delete destekli)
syllabi
syllabus_topics
exams  
exam_questions
student_papers  
student_paper_files
```

#### 2️⃣ Roller ve İzinler
- **Dosya:** [2-roller_ve_izinler_olustur.sql](/docs/database/sql/)
- **İçerik:** 4 rol + 46 detaylı izin
- **Roller:** student, teacher, admin, editor
- **İzinler:** Granüler yetki kontrolü (class:create, exam:upload_papers, vb.)

#### 3️⃣ Auth Entegrasyonu
- **Dosya:** [3-usera_uuid_sutunu_ekle.sql](/docs/database/sql/)
- **İçerik:** `users` tablosuna `auth_user_id` kolonu ekleme
- **Amaç:** Supabase Auth ile kendi users tablosunu eşleştirme

#### 4️⃣ Auth Otomatik Kullanıcı Oluşturma Sistemi
- **Dosya:** [4-auth_ile_user_bağlama.sql](/docs/database/sql/)
- **İçerik:** Auth trigger sistemi ile otomatik kullanıcı oluşturma
- **Özellikler:**
  - `handle_new_auth_user()` fonksiyonu
  - Auth.users → public.users otomatik eşleştirme
  - Meta data'dan rol, okul, öğrenci numarası çıkarma
  - Duplicate email kontrolü
  - Trigger: `on_auth_user_created`

#### 5️⃣ Sınıf Kodu Üretici Sistemi
- **Dosya:** [5-class_code_generator.sql](/docs/database/sql/)
- **İçerik:** Otomatik benzersiz sınıf kodu üretimi
- **Özellikler:**
  - `generate_unique_class_code()` fonksiyonu (8 karakter alfanumerik)
  - `assign_class_code()` trigger fonksiyonu
  - Otomatik kod atama: `trg_assign_class_code` trigger
  - Benzersizlik kontrolü (duplicate kod engelleme)
  - Sınıf oluştururken otomatik kod atama

---

## 🔐 3️⃣ Auth (Kimlik Doğrulama) Ayarları

- **Email/Password Auth**: Aktif (varsayılan)
- **Auth URL**: `https://<project-id>.supabase.co/auth/v1/`
- **JWT Secret**: `.env` dosyasında saklanıyor

### Auth Entegrasyonu:
- `users` tablosuna `auth_user_id` kolonu eklendi
- `handle_new_auth_user()` fonksiyonu ile otomatik kullanıcı oluşturma
- Auth.users → public.users otomatik eşleştirme aktif

---

## 📦 4️⃣ Storage (Dosya Depolama)

**Amaç:** Öğrencilerin sınav kağıtlarını (PDF/JPEG) depolamak.

### Kurulum Adımları:

1. Sol menü → **Storage** → **Create new bucket**
2. Bucket adı: `papers`
3. Public erişimi **devre dışı** bırakın (private bucket)
4. Bucket başarıyla oluşturuldu

📁 **Kullanım planı:**
- `papers/student_papers/` klasörü altına dosyalar yüklenecek
- `student_papers.file_path` alanı bu yolu referans alacak

### Storage Policies

```sql
-- Öğrenciler sadece kendi dosyalarını görebilir
CREATE POLICY "Students can view own papers"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'papers' AND auth.uid() = owner);

-- Öğretmenler sınıflarındaki dosyaları görebilir
CREATE POLICY "Teachers can view class papers"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'papers' AND auth.role() = 'teacher');
```

---

## 🌐 5️⃣ API Endpoint'leri

### 📁 Hazır API Endpoint'leri

Projede Flutter/Web client için hazır API çağrıları bulunmaktadır:

#### 1. Kullanıcı Girişi (Login)

```http
POST https://YOUR_PROJECT.supabase.co/auth/v1/token?grant_type=password

Headers:
  apikey: YOUR_SUPABASE_ANON_KEY
  Content-Type: application/json

Body:
{
  "email": "user@example.com",
  "password": "12345678"
}
```

#### 2. Öğretmen Kaydı (Teacher Register)

```http
POST https://YOUR_PROJECT.supabase.co/auth/v1/signup

Headers:
  apikey: YOUR_SUPABASE_ANON_KEY
  Authorization: Bearer YOUR_SUPABASE_ANON_KEY
  Content-Type: application/json
  Prefer: return=representation

Body:
{
  "email": "teacher@example.com",
  "password": "12345678",
  "data": {
    "name": "Test Teacher",
    "phone_number": "+905555555555",
    "birth_date": "1999-04-12",
    "role": "teacher",
    "school_id": 1
  }
}
```

#### 3. Öğrenci Kaydı (Student Register)

```http
POST https://YOUR_PROJECT.supabase.co/auth/v1/signup

Headers:
  apikey: YOUR_SUPABASE_ANON_KEY
  Authorization: Bearer YOUR_SUPABASE_ANON_KEY
  Content-Type: application/json
  Prefer: return=representation

Body:
{
  "email": "student@example.com",
  "password": "12345678",
  "data": {
    "name": "Test Student",
    "school_number": "12345",
    "phone_number": "+905555555555",
    "birth_date": "2005-01-15",
    "role": "student",
    "school_id": 1
  }
}
```

#### 4. Sınıf Oluşturma (Teacher Create Class)

```http
POST https://YOUR_PROJECT.supabase.co/rest/v1/classes

Headers:
  apikey: YOUR_SUPABASE_ANON_KEY
  Authorization: Bearer USER_JWT_TOKEN
  Content-Type: application/json
  Prefer: return=representation

Body:
{
  "school_id": 1,
  "teacher_id": 2,
  "name": "10-A Matematik",
  "academic_year": "2024-2025",
  "term": "Güz Dönemi"
}
```

**Not:** `code` alanı otomatik olarak üretilir (8 karakterlik benzersiz kod).

---

## 🔒 6️⃣ Row Level Security (RLS) Politikaları

### ✅ Aktif Edilen Politikalar:

#### Classes Tablosu Politikası

```sql
-- Öğretmenler kendi sınıflarını görebilir
CREATE POLICY "Teachers can view own classes"
ON public.classes FOR SELECT
TO authenticated
USING (auth.uid() = teacher_id);

-- Öğretmenler sınıf oluşturabilir
CREATE POLICY "Teachers can create classes"
ON public.classes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = teacher_id);
```

Detaylı bilgiler için: [RLS Policies](/docs/security/rls-policies)

---

## 📋 7️⃣ Kurulum Kontrol Listesi

| Adım | Durum | Açıklama |
|------|--------|-----------|
| Supabase projesi oluşturuldu | ✅ | `ai-exam-system` aktif |
| v3.3 SQL şema yüklendi | ✅ | 12 tablo + ENUM + indeks + trigger |
| Multi-tenant okul yönetimi | ✅ | `schools` tablosu ve ilişkiler |
| Roller ve izinler sistemi | ✅ | 4 rol + 46 detaylı izin |
| Auth entegrasyonu | ✅ | `auth_user_id` ilişkisi + otomatik kullanıcı oluşturma trigger'ı |
| Soft delete desteği | ✅ | `class_members.deleted_at` |
| Performans indeksleri | ✅ | 4 adet optimize edilmiş indeks |
| Otomatik timestamp triggerları | ✅ | `updated_at` otomatik güncelleme |
| Storage (papers bucket) | ✅ | private erişim aktif |
| RLS politikaları | 🔄 | 1 politika aktif (öğretmen sınıf oluşturma) |
| API endpoint'leri | ✅ | 4 endpoint dokümante edildi |
| Sınıf kodu üreticisi | ✅ | otomatik benzersiz kod üretimi |

---

## 🔜 Gelecek Adımlar

1. **RLS Politikalarını Genişletme**
   - Tüm tablolar için detaylı güvenlik politikaları
   - Öğrenci, öğretmen, admin, editör politikaları

2. **Flutter Uygulaması Entegrasyonu**
   - Supabase client konfigürasyonu
   - Auth flow implementasyonu
   - Storage dosya yükleme testleri

3. **API Endpoint'lerini Genişletme**
   - Tüm CRUD işlemleri için endpoint'ler
   - Özel RPC fonksiyonları

4. **Test ve Validasyon**
   - Sınıf davet sistemi testleri
   - Multi-tenant veri izolasyonu kontrolü
   - Performans testleri

---

## 📚 İlgili Dökümanlar

- [Database Şeması](/docs/database/)
- [SQL Dosyaları](/docs/database/sql/)
- [API Dokümantasyonu](/docs/api/)
- [Authentication Guide](/docs/technical/authentication/)
- [Security Policies](/docs/security/rls-policies/)

---

## 📜 Lisans

Bu proje Mehmet Ali GÜMÜŞLER tarafından hazırlanmıştır.  
Kişisel ve eğitimsel kullanım içindir.  
© 2025 Mehmet Ali GÜMÜŞLER
