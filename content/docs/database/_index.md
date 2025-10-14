---
title: "Veritabanı Tasarımı"
weight: 10
bookCollapseSection: true
---

# 🧠 AI Sınav Değerlendirme Sistemi - Veritabanı Tasarımı

**Author:** Mehmet Ali GÜMÜŞLER  
**Version:** 3.3 (Final Extended - Soft Delete, Performance Indexes, Auto Triggers)  
**Tarih:** 10 Ekim 2025

---

## 📘 Proje Hakkında

Bu proje, AI destekli sınav değerlendirme sistemi için geliştirilmiş kapsamlı ilişkisel veritabanı yapısını içerir.  
Sistem, öğretmenlerin sınav oluşturması, cevap anahtarlarını yüklemesi ve yapay zekâ ile öğrenci sınav kâğıtlarını otomatik olarak değerlendirmesine olanak tanır.  
Öğrenciler ise notlarını, sınav kağıtlarını, detaylı geri bildirimleri ve gelişim analizlerini görüntüleyebilir.

---

## 🧩 Veritabanı Şeması

### 🏫 Okul ve Kurum Yönetimi

| Tablo | Açıklama |
|-------|-----------|
| **schools** | Multi-tenant yapı için okul/kurum bilgileri |

### 👥 Kullanıcı ve Yetki Yönetimi

| Tablo | Açıklama |
|-------|-----------|
| **users** | Öğretmen ve öğrencilerin temel bilgileri (okul bazlı) |
| **roles** | Sistem rolleri (Admin, Öğretmen, Öğrenci, Editör) |
| **permissions** | Detaylı sistem izinleri (46 farklı yetki) |
| **role_permissions** | Roller ve izinler arasındaki ilişki |

### 🏫 Sınıf ve Müfredat Yönetimi

| Tablo | Açıklama |
|-------|-----------|
| **classes** | Öğretmen tarafından oluşturulan sınıflar (okul bazlı) |
| **class_members** | Öğrencilerin sınıflara katılım kayıtları (soft delete destekli) |
| **syllabi** | Sınıf müfredatları (PDF/Word dosyaları) |
| **syllabus_topics** | Müfredat konu başlıkları (hiyerarşik yapı) |

### 📝 Sınav ve Değerlendirme Yönetimi

| Tablo | Açıklama |
|-------|-----------|
| **exams** | Sınav bilgileri, içerik ve cevap anahtarları |
| **exam_questions** | Sınav soruları ve müfredat konularına bağlantı |
| **student_papers** | Öğrenci sınav kağıtları, AI puanları, geri bildirim |
| **student_paper_files** | Sınav kağıdı sayfa görüntüleri ve OCR çıktıları (benzersiz sayfa numarası) |

---

## 🖼️ Diyagram Görünümü

Veritabanı diyagramı, dbdiagram.io üzerinden tasarlanmıştır.

![Database Diagram](/images/schema.png)

---

## 🧠 Sistem Özellikleri

### 🏫 Multi-Tenant Okul Yapısı:
- **Okul Bazlı İzolasyon**: Her okul kendi verilerini görür, diğer okullardan izole
- **Okul Numarası Benzersizliği**: Öğrenci numaraları okul içinde benzersiz
- **Kurumsal Güvenlik**: Veriler okul bazlı ayrılmış, güvenlik sağlanmış

### 👩‍🏫 Öğretmen:
- **Sınıf Yönetimi**: Kendi okulunda sınıf oluşturur, öğrencileri davet kodu ile ekler
- **Müfredat Yönetimi**: Syllabus dosyalarını yükler, konu başlıklarını organize eder
- **Sınav Oluşturma**: AI destekli sınav editörü ile soru hazırlar
- **Değerlendirme**: AI puanlarını inceler, manuel düzenlemeler yapar
- **Raporlama**: Sınıf ve öğrenci bazında analiz görüntüler

### 🧑‍🎓 Öğrenci:
- **Sınıfa Katılım**: Davet kodu ile sınıfa katılır
- **Sonuç Görüntüleme**: Sadece kendi sınav sonuçlarını, geri bildirimleri inceler
- **Gelişim Takibi**: Kişisel gelişim grafiği ve konu bazlı analiz görür

### 👨‍💼 Editör/Gözetmen:
- **Kurumsal Görüntüleme**: Okuldaki tüm sınıfları, sınavları ve sonuçları görüntüler
- **Sadece Okuma Yetkisi**: Veri değiştirme yetkisi yok, sadece analiz ve raporlama

### 👑 Admin:
- **Tam Yetki**: Sistemdeki tüm işlemleri yapabilir
- **Kullanıcı Yönetimi**: Tüm kullanıcıları yönetebilir

---

## 🧾 AI ve Veri Yapısı

### **AI Entegrasyonu:**
- **OCR Modülü**: El yazısı sınav kağıtlarını dijital metne çevirir
- **LLM Modülü**: Açık uçlu soruları değerlendirir, geri bildirim üretir
- **JSONB Veri Yapısı**: AI çıktıları ve model parametreleri esnek formatta saklanır

### **Veri Durumları:**
- **exam_status**: draft, published, archived
- **paper_status**: pending, identifying, needs_identification, evaluated, published

### **Özel Özellikler:**
- **Multi-Tenant Yapı**: Okul bazlı veri izolasyonu ve güvenlik
- **Supabase Auth Entegrasyonu**: `auth_user_id` ile Supabase kimlik doğrulama sistemi
- **Detaylı Yetki Sistemi**: 46 farklı izin ile granüler yetki kontrolü
- **Soft Delete**: Sınıf üyeliklerinde yumuşak silme (`deleted_at` kolonu)
- **Performans İndeksleri**: Sık sorgulanan alanlar için optimize edilmiş indeksler
- **Otomatik Timestamp**: `updated_at` alanları otomatik güncelleme triggerları ile
- **Hiyerarşik Konu Yapısı**: Müfredat konuları parent-child ilişkisi ile organize edilir
- **Çoklu Sayfa Desteği**: Sınav kağıtları sayfa sayfa saklanır ve işlenir
- **Esnek Cevap Anahtarı**: JSONB formatında farklı soru tiplerini destekler
- **Sınıf Kodu Üreticisi**: Otomatik benzersiz 8 karakterlik sınıf kodları
- **API Endpoint'leri**: Hazır HTTP çağrıları (auth, sınıf oluşturma)
- **RLS Politikaları**: Row Level Security ile veri güvenliği

---

## 🚀 Performans ve Optimizasyon Özellikleri

### 📊 Performans İndeksleri:
- **`idx_exams_status`**: Sınav durumuna göre hızlı filtreleme
- **`idx_student_papers_status`**: Kağıt durumuna göre hızlı filtreleme  
- **`idx_exam_questions_topic_id`**: Konu bazlı soru sorguları
- **`idx_unique_active_class_member`**: Soft delete destekli benzersiz üyelik kontrolü

### 🔄 Otomatik Güncelleme Sistemi:
- **`set_updated_at()` Fonksiyonu**: Tüm `updated_at` alanlarını otomatik günceller
- **Trigger Sistemi**: `users`, `classes`, `exams`, `student_papers` tablolarında otomatik çalışır
- **Idempotent Yapı**: Birden fazla çalıştırmada güvenli

### 🗑️ Soft Delete Desteği:
- **`class_members.deleted_at`**: Sınıf üyeliklerinde yumuşak silme
- **Partial Index**: Sadece aktif üyeler için benzersizlik kontrolü
- **Veri Korunması**: Silinen kayıtlar fiziksel olarak korunur

---

## 🧱 Kullanılan Teknolojiler

| Bileşen | Açıklama |
|----------|-----------|
| **Supabase** | PostgreSQL tabanlı veritabanı ve auth sistemi |
| **PostgreSQL** | Veritabanı yönetim sistemi |
| **DBML** | Modelleme dili (dbdiagram.io) |
| **SQL Migrations** | Sürüm kontrollü veritabanı güncellemeleri |
| **JSONB** | AI çıktıları, cevap anahtarları ve esnek veri saklama |
| **ENUM Types** | Veri bütünlüğü için durum kontrolleri |
| **Multi-Tenant** | Okul bazlı veri izolasyonu |
| **Soft Delete** | Yumuşak silme ile veri korunması |
| **Performance Indexes** | Sorgu performansı için optimize edilmiş indeksler |
| **Auto Triggers** | Otomatik timestamp güncellemeleri |
| **Class Code Generator** | Otomatik sınıf kodu üretimi |
| **API Endpoints** | Hazır HTTP çağrıları |
| **RLS Policies** | Row Level Security politikaları |

---

## ⚙️ Kurulum (Supabase/PostgreSQL)

### Supabase Kurulumu:
1. Supabase projesi oluştur
2. SQL Editor'da migration dosyalarını sırayla çalıştır:
    ```sql
    -- 1. Temel veritabanı yapısını oluştur
    -- database/supabase/sql_editorde_calistirilicaklar/1-create_database.sql
    
    -- 2. Roller ve izinleri ayarla  
    -- database/supabase/sql_editorde_calistirilicaklar/2-roller_ve_izinler_olustur.sql
    
    -- 3. Auth UUID kolonu ekle
    -- database/supabase/sql_editorde_calistirilicaklar/3-usera_uuid_sutunu_ekle.sql
    
    -- 4. Auth trigger sistemi
    -- database/supabase/sql_editorde_calistirilicaklar/4-auth_ile_user_bağlama.sql
    
    -- 5. Sınıf kodu üreticisi
    -- database/supabase/sql_editorde_calistirilicaklar/5-class_code_generator.sql
    ```

### PostgreSQL Kurulumu:
1. Yeni bir veritabanı oluştur:
    ```bash
    createdb ai_exam_system
    ```

2. Migration dosyalarını sırayla çalıştır:
    ```bash
    psql -U postgres -d ai_exam_system -f sql/1-create_database.sql
    psql -U postgres -d ai_exam_system -f sql/2-roller_ve_izinler_olustur.sql
    psql -U postgres -d ai_exam_system -f sql/3-usera_uuid_sutunu_ekle.sql
    psql -U postgres -d ai_exam_system -f sql/4-auth_ile_user_bağlama.sql
    psql -U postgres -d ai_exam_system -f sql/5-class_code_generator.sql
    ```

3. Kurulumdan sonra tabloları doğrula:
    ```bash
    psql -U postgres -d ai_exam_system
    \dt
    \d+ users
    \d+ schools
    \d+ class_members
    ```
    
4. Performans indekslerini ve triggerları kontrol et:
    ```sql
    -- İndeksleri listele
    \di+ idx_*
    
    -- Triggerları listele
    SELECT trigger_name, event_object_table 
    FROM information_schema.triggers 
    WHERE trigger_name LIKE '%updated_at%';
    ```

---

## 🔄 Versiyon Geçmişi

- **v1.0**: MVP versiyonu - Temel tablolar
- **v2.4**: JSONB varsayılan değerleri, hiyerarşik konu yapısı, çoklu sayfa desteği
- **v3.1**: Multi-tenant okul yönetimi, detaylı yetki sistemi (46 izin), Supabase auth entegrasyonu
- **v3.3**: Soft delete desteği, performans indeksleri, otomatik timestamp triggerları, final optimizasyonlar
- **v3.3+**: Supabase entegrasyonu, API endpoint'leri, RLS politikaları, sınıf kodu üreticisi

---

## 📂 SQL Dosyaları

Veritabanı SQL dosyalarına [Database SQL](/docs/database/sql) bölümünden ulaşabilirsiniz.

---

## 📜 Lisans

Bu proje Mehmet Ali GÜMÜŞLER tarafından hazırlanmıştır.  
Kişisel ve eğitimsel kullanım içindir.  
© 2025 Mehmet Ali GÜMÜŞLER
