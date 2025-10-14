---
title: "Trigger'lar"
weight: 2
---

# ⚡ PostgreSQL Trigger'ları

Bu bölümde Supabase veritabanında kullanılan tüm trigger'ların detaylı açıklamaları bulunmaktadır.

---

## 📋 Trigger Listesi

### 🔑 Auth ve Kullanıcı Yönetimi
- [on_auth_user_created](/docs/supabase/triggers/on-auth-user-created/) - Yeni auth kullanıcısı oluşturulduğunda

### ⏰ Timestamp Güncelleme
- [update_users_updated_at](/docs/supabase/triggers/update-users-updated-at/) - Users tablosu timestamp
- [update_classes_updated_at](/docs/supabase/triggers/update-classes-updated-at/) - Classes tablosu timestamp
- [update_exams_updated_at](/docs/supabase/triggers/update-exams-updated-at/) - Exams tablosu timestamp
- [update_student_papers_updated_at](/docs/supabase/triggers/update-student-papers-updated-at/) - Student Papers timestamp

### 🏫 Sınıf Yönetimi
- [trg_assign_class_code](/docs/supabase/triggers/trg-assign-class-code/) - Sınıf kodu otomatik atama

### ✅ Validasyon Trigger'ları
- [validate_class_member](/docs/supabase/triggers/validate-class-member/) - Sınıf üyeliği validasyonu
- [validate_student_role](/docs/supabase/triggers/validate-student-role/) - Öğrenci rol kontrolü

---

## 🎯 Trigger Türleri

### BEFORE Triggers
Veri değiştirilmeden önce çalışır. Veriyi değiştirmek veya reddetmek için kullanılır.

### AFTER Triggers
Veri değiştirildikten sonra çalışır. Log tutmak veya başka işlemler tetiklemek için kullanılır.

### INSTEAD OF Triggers
View'lar üzerinde çalışır. Normal tablo işlemleri yerine özel işlemler yapar.

---

## 📖 Nasıl Kullanılır

Her trigger için:
- Trigger tanımı ve amacı
- Tetiklenme koşulu (INSERT/UPDATE/DELETE)
- Bağlı olduğu tablo
- Çalıştırdığı fonksiyon
- Örnek senaryolar

---

_Not: Trigger detaylarını ilgili sayfalarda bulabilirsiniz._
