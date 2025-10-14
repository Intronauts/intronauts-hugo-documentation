---
title: "Zaman Damgası Güncelleme Trigger'ları"
weight: 10
---

# ⏰ Timestamp Güncelleme Trigger'ları

Tablolarda UPDATE işlemi yapıldığında `updated_at` alanını otomatik güncelleyen trigger'lar.

---

## Trigger Listesi

Aşağıdaki tablolarda `set_updated_at_trigger` adı ile aynı trigger tanımlanmıştır:

### users tablosu
```sql
CREATE OR REPLACE TRIGGER "set_updated_at_trigger" 
BEFORE UPDATE ON "public"."users" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."set_updated_at"();
```

### classes tablosu
```sql
CREATE OR REPLACE TRIGGER "set_updated_at_trigger" 
BEFORE UPDATE ON "public"."classes" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."set_updated_at"();
```

### exams tablosu
```sql
CREATE OR REPLACE TRIGGER "set_updated_at_trigger" 
BEFORE UPDATE ON "public"."exams" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."set_updated_at"();
```

### student_papers tablosu
```sql
CREATE OR REPLACE TRIGGER "set_updated_at_trigger" 
BEFORE UPDATE ON "public"."student_papers" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."set_updated_at"();
```

---

## Amaç

Her tablo satırı güncellendiğinde otomatik olarak `updated_at` timestamp alanını günceller.

---

## Tetiklenme Koşulu

- **Event**: UPDATE
- **Timing**: BEFORE
- **Level**: ROW
- **Tables**: users, classes, exams, student_papers

---

## Çalıştırdığı Fonksiyon

[set_updated_at()](/docs/supabase/functions/set-updated-at/)

---

## SQL Kodu

```sql
-- İçeriği buraya ekleyiniz
```

---

## Kullanım Senaryosu

1. Bir tablo satırı güncellenir (UPDATE)
2. Trigger otomatik tetiklenir
3. `updated_at` alanı `NOW()` ile güncellenir
4. Değişiklik veritabanına kaydedilir

---

## Örnek

```sql
-- Kullanıcı adı güncelleme
UPDATE users 
SET name = 'Yeni İsim' 
WHERE id = 5;

-- updated_at otomatik olarak güncellenir
-- Manuel olarak updated_at yazmaya gerek yok
```

---

## İlgili Tablolar

- `public.users`
- `public.classes`
- `public.exams`
- `public.student_papers`

---

## Notlar

- ✅ Otomatik timestamp yönetimi
- ✅ Her UPDATE işleminde çalışır
- ✅ Idempotent (birden fazla çalıştırmada güvenli)
- ℹ️ INSERT işlemlerinde `created_at` DEFAULT NOW() ile otomatik atanır
