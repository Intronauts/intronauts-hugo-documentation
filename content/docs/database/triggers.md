---
title: "Trigger'lar"
weight: 20
---

# Veritabanı Trigger'ları

Sistemde otomatik işlemleri gerçekleştiren trigger'lar.

---

## 📋 Tüm Trigger'lar

| Tablo | Trigger Adı | Olay | Fonksiyon | Açıklama |
|-------|-------------|------|-----------|----------|
| `classes` | `classes_generate_code_trigger` | BEFORE INSERT | `generate_class_code()` | Otomatik sınıf kodu oluşturur |
| `classes` | `set_updated_at_trigger` | BEFORE UPDATE | `set_updated_at()` | Güncelleme zamanını ayarlar |
| `classes` | `trigger_delete_class_members_when_a_class_deleted` | AFTER DELETE | `delete_class_members_when_a_class_deleted()` | Sınıf silindiğinde üyeleri temizler |
| `users` | `set_updated_at_trigger` | BEFORE UPDATE | `set_updated_at()` | Güncelleme zamanını ayarlar |
| `exams` | `set_updated_at_trigger` | BEFORE UPDATE | `set_updated_at()` | Güncelleme zamanını ayarlar |
| `student_papers` | `set_updated_at_trigger` | BEFORE UPDATE | `set_updated_at()` | Güncelleme zamanını ayarlar |

---

## 1️⃣ Sınıf Kodu Üretimi

**Trigger:** `classes_generate_code_trigger`  
**Tablo:** `classes`  
**Olay:** BEFORE INSERT  
**Fonksiyon:** `generate_class_code()`

### Ne İşe Yarar?
Yeni sınıf oluşturulduğunda otomatik olarak 8 karakterlik benzersiz kod oluşturur.

### Örnek:
```sql
INSERT INTO classes (school_id, teacher_id, name, academic_year, term)
VALUES (1, 5, '10-A Matematik', '2024-2025', 'Güz');

-- code kolonu otomatik doldurulur: "K7M2X9P1"
```

### Özellikler:
- ✅ Sadece `code IS NULL` ise çalışır
- ✅ Benzersizlik garantisi (çakışma kontrolü ile)
- ✅ 8 karakter uzunluğunda
- ✅ Büyük harf ve rakamlardan oluşur (A-Z, 0-9)

---

## 2️⃣ Otomatik Timestamp Güncelleme

**Trigger:** `set_updated_at_trigger`  
**Tablolar:** `users`, `classes`, `exams`, `student_papers`  
**Olay:** BEFORE UPDATE  
**Fonksiyon:** `set_updated_at()`

### Ne İşe Yarar?
Her güncelleme işleminde `updated_at` kolonunu otomatik olarak `NOW()` ile günceller.

### Örnek:
```sql
UPDATE classes 
SET name = '10-B Matematik' 
WHERE id = 1;

-- updated_at otomatik olarak güncel zamana ayarlanır
```

### Avantajları:
- ✅ Manuel timestamp yönetimi gerektirmez
- ✅ Tutarlılık sağlar
- ✅ Audit trail için önemli

---

## 3️⃣ Cascade Delete (Sınıf Üyelikleri)

**Trigger:** `trigger_delete_class_members_when_a_class_deleted`  
**Tablo:** `classes`  
**Olay:** AFTER DELETE  
**Fonksiyon:** `delete_class_members_when_a_class_deleted()`

### Ne İşe Yarar?
Sınıf silindiğinde, o sınıfa ait tüm `class_members` kayıtlarını otomatik siler.

### Örnek:
```sql
-- Sınıfta 25 öğrenci var
SELECT COUNT(*) FROM class_members WHERE class_id = 10;
-- Sonuç: 25

-- Sınıfı sil
DELETE FROM classes WHERE id = 10;

-- Üyelikler otomatik silindi
SELECT COUNT(*) FROM class_members WHERE class_id = 10;
-- Sonuç: 0
```

### Neden Gerekli?
- ✅ Veri bütünlüğünü korur
- ✅ Orphan (sahipsiz) kayıtları önler
- ✅ Manuel temizlik gerekmez

---

## 🔧 Trigger Yönetimi

### Trigger'ları Listeleme

```sql
-- Tüm trigger'ları listele
SELECT 
    trigger_name,
    event_object_table AS table_name,
    action_timing,
    event_manipulation AS event,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

### Trigger'ı Devre Dışı Bırakma

```sql
-- Trigger'ı geçici olarak devre dışı bırak
ALTER TABLE classes DISABLE TRIGGER classes_generate_code_trigger;

-- Tüm trigger'ları devre dışı bırak
ALTER TABLE classes DISABLE TRIGGER ALL;
```

### Trigger'ı Tekrar Etkinleştirme

```sql
-- Trigger'ı etkinleştir
ALTER TABLE classes ENABLE TRIGGER classes_generate_code_trigger;

-- Tüm trigger'ları etkinleştir
ALTER TABLE classes ENABLE TRIGGER ALL;
```

---

## ⚠️ Önemli Notlar

1. **Performans:** Trigger'lar her işlemde otomatik çalışır, büyük toplu işlemlerde yavaşlamaya neden olabilir.

2. **Hata Ayıklama:** Trigger içinde hata olursa tüm işlem geri alınır (ROLLBACK).

3. **Test:** Yeni trigger eklerken mutlaka test ortamında deneyin.

4. **Loglama:** Trigger içinde `RAISE NOTICE` kullanarak debug yapabilirsiniz:
```sql
RAISE NOTICE 'Generated code: %', new_code;
```

---

## 📚 İlgili Dokümantasyon

- [Fonksiyonlar](/docs/database/functions/)
- [RLS Politikaları](/docs/database/policies/)
