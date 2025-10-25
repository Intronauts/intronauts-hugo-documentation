---
title: "RLS Politikaları"
weight: 3
---

# 🔒 Row Level Security (RLS) Politikaları

Bu bölümde Supabase veritabanında kullanılan tüm RLS politikalarının detaylı açıklamaları bulunmaktadır.

---

## 📋 RLS Politikaları Listesi

### 🏫 Schools Tablosu
- [anyone_can_view_schools](/docs/supabase/rls-policies/schools-policies/) - Herkes okul listesini görüntüleyebilir

### 🏫 Classes Tablosu
- [users_can_view_relevant_classes](/docs/supabase/rls-policies/classes-policies/) - Kullanıcılar ilgili oldukları sınıfları görür
- [teachers_admins_editors_can_create_classes](/docs/supabase/rls-policies/classes-policies/) - Yetkili roller sınıf oluşturabilir
- [owners_can_update_classes](/docs/supabase/rls-policies/classes-policies/) - Sahipler sınıfları güncelleyebilir
- [owners_can_delete_classes](/docs/supabase/rls-policies/classes-policies/) - Sahipler sınıfları silebilir

### �️ Class Members Tablosu
- [users_can_view_memberships](/docs/supabase/rls-policies/class-members-policies/) - Kullanıcılar ilgili üyelikleri görür
- [authenticated_can_insert_memberships](/docs/supabase/rls-policies/class-members-policies/) - Giriş yapmış kullanıcılar üyelik ekleyebilir
- [students_can_update_own_memberships](/docs/supabase/rls-policies/class-members-policies/) - Öğrenciler kendi üyeliklerini güncelleyebilir

---

## 🎯 RLS Nedir?

Row Level Security (Satır Seviyesi Güvenlik), PostgreSQL'in güvenlik özelliğidir. Her kullanıcının sadece kendisine ait veya yetkili olduğu verileri görmesini ve değiştirmesini sağlar.

### Avantajları
- ✅ Tablo seviyesinde güvenlik
- ✅ Her sorgu için otomatik kontrol
- ✅ Backend kod gerektirmez
- ✅ SQL injection'a karşı koruma
- ✅ Multi-tenant mimaride veri izolasyonu

---

## 📖 Politika Türleri

### SELECT Politikaları
Kullanıcının hangi satırları görebileceğini belirler.

```sql
CREATE POLICY "policy_name"
ON table_name FOR SELECT
USING (condition);
```

### INSERT Politikaları
Kullanıcının hangi satırları ekleyebileceğini belirler.

```sql
CREATE POLICY "policy_name"
ON table_name FOR INSERT
WITH CHECK (condition);
```

### UPDATE Politikaları
Kullanıcının hangi satırları güncelleyebileceğini belirler.

```sql
CREATE POLICY "policy_name"
ON table_name FOR UPDATE
USING (condition)
WITH CHECK (condition);
```

### DELETE Politikaları
Kullanıcının hangi satırları silebileceğini belirler.

```sql
CREATE POLICY "policy_name"
ON table_name FOR DELETE
USING (condition);
```

---

## 🔧 RLS Nasıl Aktif Edilir?

```sql
-- RLS'yi aktif et
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- RLS'yi devre dışı bırak
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- Politika oluştur
CREATE POLICY "policy_name"
ON table_name
FOR operation
USING (condition);
```

---

## 📊 Mevcut Durum

| Tablo | RLS Aktif | Politika Sayısı |
|-------|-----------|-----------------|
| users | ✅ | 3 |
| classes | ✅ | 3 |
| exams | ✅ | 2 |
| student_papers | ✅ | 3 |
| class_members | ✅ | 2 |
| _diğerleri_ | 🔄 | Planlanan |

---

## 🔗 İlgili Bölümler

- [Database Şeması](/docs/database/)
- [RBAC Güvenlik](/docs/reference/01_rbac_security/)
- [Supabase Kurulumu](/docs/supabase-setup/)

---

_Not: Politika detaylarını ilgili sayfalarda bulabilirsiniz._
