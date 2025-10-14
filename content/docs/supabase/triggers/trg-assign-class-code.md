---
title: "Sınıf Kodu Oluşturma Trigger"
weight: 5
---

# 🏫 classes_generate_code_trigger

Yeni sınıf oluşturulduğunda otomatik olarak benzersiz sınıf kodu atayan trigger.

---

## Trigger Tanımı

```sql
CREATE OR REPLACE TRIGGER "classes_generate_code_trigger" 
BEFORE INSERT ON "public"."classes" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."generate_class_code"();
```

---

## Amaç

Yeni bir sınıf oluşturulduğunda ve kod alanı boş bırakıldığında otomatik olarak 8 karakterlik benzersiz bir sınıf kodu üretir ve atar.

---

## Tetiklenme Koşulu

- **Event**: INSERT
- **Timing**: BEFORE
- **Level**: ROW
- **Table**: public.classes

---

## Çalıştırdığı Fonksiyon

- [generate_class_code()](/docs/supabase/functions/generate-unique-class-code/)

---

## SQL Kodu

```sql
CREATE OR REPLACE TRIGGER "classes_generate_code_trigger" 
BEFORE INSERT ON "public"."classes" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."generate_class_code"();
```

---

## Kullanım Senaryosu

1. Öğretmen yeni sınıf oluşturur
2. Code alanı boş bırakılır
3. Trigger tetiklenir
4. Benzersiz kod üretilir (ör: "A2X9K7B1")
5. Kod sınıfa atanır
6. Sınıf veritabanına kaydedilir

---

## Örnek

```sql
-- Manuel kod ile
INSERT INTO classes (name, teacher_id, school_id, code)
VALUES ('10-A Matematik', 5, 1, 'CUSTOM01');
-- Trigger çalışmaz, verilen kod kullanılır

-- Otomatik kod ile
INSERT INTO classes (name, teacher_id, school_id)
VALUES ('10-B Fizik', 5, 1);
-- Trigger çalışır, otomatik kod üretilir
```

---

## İlgili Tablolar

- `public.classes`

---

## Notlar

- ✅ Benzersizlik garantili
- ✅ 8 karakter alfanumerik
- ✅ Sadece code NULL olduğunda çalışır
- ✅ Duplicate kod engelleme mekanizması
- ⚠️ Maksimum 100 deneme (collision prevention)
