---
title: "Veritabanı Dokümantasyonu"
weight: 10
bookCollapseSection: true
---

# Veritabanı Yapısı

Okula Bukula sistemi, **PostgreSQL** veritabanı üzerinde multi-tenant (okul bazlı) mimari ile çalışır. Her okul kendi verilerine izole şekilde erişir.

---

## 📊 Genel Bakış

Veritabanı **12 ana tablo** içerir ve 4 kategoriye ayrılır:

1. **Okul Yönetimi** - Kurumsal yapı
2. **Kullanıcı ve Yetki Yönetimi** - Kimlik doğrulama ve roller
3. **Sınıf ve Müfredat** - Eğitim organizasyonu
4. **Sınav ve Değerlendirme** - AI destekli değerlendirme sistemi

---

## 🏫 1. Okul Yönetimi

### `schools` Tablosu
Multi-tenant yapının temeli. Her kayıt bir okulu/kurumu temsil eder.

**Amaç:** Farklı okulların verilerini birbirinden izole etmek.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Okul ID (Primary Key) |
| `name` | varchar(255) | Okul adı (benzersiz) |
| `address` | text | Okul adresi |
| `created_at` | timestamptz | Kayıt tarihi |

---

## 👥 2. Kullanıcı ve Yetki Yönetimi

### `users` Tablosu
Sistemdeki tüm kullanıcılar (öğrenci, öğretmen, admin).

**Amaç:** Kullanıcı bilgilerini saklamak ve Supabase Auth ile entegre etmek.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Kullanıcı ID |
| `school_id` | int | Bağlı olduğu okul |
| `name` | varchar(100) | Ad Soyad |
| `email` | varchar(150) | E-posta (benzersiz) |
| `school_number` | varchar(50) | Öğrenci numarası |
| `phone_number` | varchar(20) | Telefon |
| `birth_date` | date | Doğum tarihi |
| `role_id` | int | Kullanıcı rolü |
| `auth_user_id` | uuid | Supabase Auth UUID |

**Önemli:** `(school_id, school_number)` birlikte benzersizdir - aynı numara farklı okullarda kullanılabilir.

### `roles` Tablosu
Sistem rolleri.

**Varsayılan Roller:**
1. **Student (1)** - Öğrenci
2. **Teacher (2)** - Öğretmen  
3. **Admin (3)** - Sistem yöneticisi
4. **Editor (4)** - İçerik editörü

### `permissions` Tablosu
Detaylı izinler (46 farklı yetki).

**Örnek İzinler:**
- `create_class` - Sınıf oluşturma
- `view_all_exams` - Tüm sınavları görüntüleme
- `grade_papers` - Kağıt değerlendirme

### `role_permissions` Tablosu
Roller ve izinler arasındaki ilişki (Many-to-Many).

---

## 🎓 3. Sınıf ve Müfredat Yönetimi

### `classes` Tablosu
Öğretmenlerin oluşturduğu sınıflar.

**Amaç:** Öğrencileri gruplamak ve sınav organizasyonu sağlamak.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Sınıf ID |
| `school_id` | int | Sınıfın bağlı olduğu okul |
| `teacher_id` | int | Sınıf öğretmeni |
| `name` | varchar(100) | Sınıf adı (örn: "10-A Matematik") |
| `code` | varchar(20) | **Otomatik oluşturulan** 8 haneli kod (örn: "A8K9X2M1") |
| `academic_year` | varchar(50) | Akademik yıl (örn: "2024-2025") |
| `term` | varchar(50) | Dönem (örn: "Güz", "Bahar") |

**Özellik:** `code` kolonu trigger ile otomatik oluşturulur (benzersiz, 8 karakter).

### `class_members` Tablosu
Öğrencilerin sınıflara katılım kayıtları.

**Amaç:** Öğrenci-sınıf ilişkisini yönetmek (soft delete destekli).

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Üyelik ID |
| `class_id` | int | Sınıf referansı |
| `student_id` | int | Öğrenci referansı |
| `joined_at` | timestamptz | Katılım tarihi |
| `deleted_at` | timestamptz | Silinme tarihi (soft delete) |

**Önemli:** `deleted_at = NULL` olan kayıtlar aktif üyeliklerdir. Aynı öğrenci aynı sınıfa birden fazla kez eklenemez (aktif kayıtlar için).

### `syllabi` Tablosu
Sınıf müfredatları (PDF/Word dosyaları).

**Amaç:** Müfredat dosyalarını saklamak.

### `syllabus_topics` Tablosu
Müfredat konu başlıkları (hiyerarşik yapı).

**Amaç:** Konuları organize etmek ve sınav sorularını konulara bağlamak.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `parent_topic_id` | int | Üst konu (NULL ise ana konu) |
| `topic_name` | varchar(255) | Konu adı |
| `expected_week` | int | Planlandığı hafta |

**Örnek Hiyerarşi:**
```
Matematik (parent_topic_id = NULL)
  ├── Cebir (parent_topic_id = 1)
  │   ├── Denklemler (parent_topic_id = 2)
  │   └── Eşitsizlikler (parent_topic_id = 2)
  └── Geometri (parent_topic_id = 1)
```

---

## 📝 4. Sınav ve Değerlendirme Yönetimi

### `exams` Tablosu
Öğretmenlerin oluşturduğu sınavlar.

**Amaç:** Sınav içeriğini ve cevap anahtarını saklamak.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Sınav ID |
| `class_id` | int | Hangi sınıf için |
| `title` | varchar(150) | Sınav başlığı |
| `exam_content` | text | Sınav metni/soruları |
| `answer_key` | jsonb | Cevap anahtarı (JSON formatında) |
| `status` | enum | `draft`, `published`, `archived` |

**Durum Akışı:**
- `draft` → Sınav hazırlanıyor
- `published` → Öğrencilere açıldı
- `archived` → Arşivlendi

### `exam_questions` Tablosu
Sınav sorularının detayları.

**Amaç:** Her soruyu müfredat konusuna bağlamak ve puanlandırmak.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `exam_id` | int | Sınav referansı |
| `topic_id` | int | Müfredat konusu |
| `question_number` | int | Soru numarası (1, 2, 3...) |
| `question_text` | text | Soru metni |
| `points` | float | Puan değeri |

### `student_papers` Tablosu
Öğrencilerin yüklediği sınav kağıtları ve değerlendirmeler.

**Amaç:** AI puanlaması ve öğretmen geri bildirimini saklamak.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | int | Kağıt ID |
| `exam_id` | int | Hangi sınav |
| `student_id` | int | Hangi öğrenci |
| `ai_score` | float | AI'ın verdiği puan |
| `teacher_score` | float | Öğretmenin verdiği final puan |
| `feedback` | text | Geri bildirim metni |
| `evaluation_summary` | jsonb | Değerlendirme detayları (JSON) |
| `ocr_student_info` | jsonb | OCR ile tespit edilen öğrenci bilgisi |
| `status` | enum | Kağıt durumu |

**Durum Akışı:**
- `pending` → Yüklendi, işlem bekliyor
- `identifying` → OCR çalışıyor
- `needs_identification` → Öğrenci tespiti manuel onay gerekiyor
- `evaluated` → AI değerlendirmesi tamamlandı
- `published` → Öğrenciye gösterildi

### `student_paper_files` Tablosu
Sınav kağıdı sayfa görüntüleri.

**Amaç:** Her kağıdın sayfalarını ayrı ayrı saklamak ve OCR yapmak.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `paper_id` | int | Hangi kağıt |
| `page_image_path` | varchar(255) | Dosya yolu |
| `page_number` | int | Sayfa numarası (1, 2, 3...) |
| `ocr_text` | jsonb | OCR çıktısı (JSON) |

**Önemli:** `(paper_id, page_number)` benzersizdir - aynı kağıtta aynı sayfa numarası tekrar edemez.

---

## 🗺️ Veritabanı Şeması

Tüm tabloların görsel ilişki diyagramı:

{{< figure src="/images/schema.png" alt="Database Schema" >}}


## 🔧 Önemli Özellikler

### 1. Otomatik Trigger'lar

**Sınıf Kodu Üretimi:**
```sql
-- classes tablosuna INSERT edildiğinde otomatik kod oluşturur
TRIGGER: classes_generate_code_trigger
FUNCTION: generate_class_code()
```
- 8 karakterli benzersiz kod (örn: "K7M2X9P1")
- Sadece code NULL ise çalışır
- Çakışma kontrolü ile benzersizlik garantisi

**Otomatik Timestamp Güncelleme:**
```sql
-- Her UPDATE'te updated_at otomatik güncellenir
TRIGGER: set_updated_at_trigger
TABLES: users, classes, exams, student_papers
```

**Cascade Delete:**
```sql
-- Sınıf silindiğinde üyelikleri de siler
TRIGGER: trigger_delete_class_members_when_a_class_deleted
```

### 2. Fonksiyonlar

**Kullanıcı Kaydı (Supabase Auth):**
```sql
handle_new_auth_user()
```
**Amaç:** Supabase Auth'da yeni kullanıcı oluştuğunda otomatik olarak `users` tablosuna ekler.

**İşleyişi:**
1. Kullanıcı Supabase'de kayıt olur
2. Trigger otomatik çalışır
3. `auth_user_id` ile users tablosuna kaydedilir
4. Role ve school bilgileri metadata'dan alınır

**Sınıfa Katılma:**
```sql
join_class_by_code(p_class_code text) → json
```
**Amaç:** Öğrencinin kod ile sınıfa katılmasını sağlar.

**Kontroller:**
- Kullanıcı öğrenci mi?
- Sınıf kodu geçerli mi?
- Öğrenci ve sınıf aynı okulda mı?
- Öğrenci zaten üye mi?

**Sınıf Öğrencilerini Listeleme:**
```sql
get_class_students(p_class_id int) → TABLE
```
**Amaç:** RLS politikalarını bypass ederek sınıftaki öğrencileri döndürür (SECURITY DEFINER).

**Öğrenci Sayısı:**
```sql
get_class_student_count(p_class_id int) → int
```
**Amaç:** Bir sınıftaki aktif öğrenci sayısını döndürür.

**Öğrencinin Sınıfları:**
```sql
get_student_classes() → TABLE
```
**Amaç:** Giriş yapan öğrencinin kayıtlı olduğu tüm sınıfları döndürür.

### 3. Row Level Security (RLS) Politikaları

**Classes Tablosu:**
- ✅ Öğretmenler sadece kendi sınıflarını görebilir
- ✅ Öğretmenler sadece kendi sınıflarını silebilir/güncelleyebilir
- ✅ Sadece öğretmen, admin ve editörler sınıf oluşturabilir

**Class Members Tablosu:**
- ✅ Öğretmenler kendi sınıflarının üyelerini görebilir
- ✅ Öğrenciler kendi üyeliklerini görebilir
- ✅ Öğretmenler öğrencileri sınıftan çıkarabilir
- ✅ Öğrenciler kendi üyeliklerini silebilir (sınıftan ayrılma)

**Schools Tablosu:**
- ✅ Herkes okul listesini görebilir (public read)



## 📋 Veri Durumları (ENUM)

### exam_status
- `draft` - Taslak (henüz yayınlanmadı)
- `published` - Yayında (öğrenciler görebilir)
- `archived` - Arşivlendi (pasif)

### paper_status
- `pending` - Yüklendi, işlem bekliyor
- `identifying` - OCR ile öğrenci tespiti yapılıyor
- `needs_identification` - Manuel öğrenci eşleştirmesi gerekli
- `evaluated` - AI değerlendirmesi tamamlandı
- `published` - Öğrenciye gösterildi

---

## 📚 İlgili Dokümantasyon

### Veritabanı Detayları
- **[Trigger'lar](/docs/database/triggers/)** - Otomatik işlemler ve trigger fonksiyonları
- **[Fonksiyonlar](/docs/database/functions/)** - PostgreSQL fonksiyonları ve kullanım örnekleri
- **[RLS Politikaları](/docs/database/policies/)** - Row Level Security ve güvenlik kuralları

### Geliştirme Rehberleri
- **[Supabase Kurulum](/docs/supabase/)** - Adım adım kurulum rehberi
- **[REST API Rehberi](/docs/guides/rest_api_guide_1/)** - API kullanım örnekleri
- **[RBAC Güvenlik](/docs/reference/01_rbac_security/)** - Rol bazlı erişim kontrolü

---

