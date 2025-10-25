---
title: "Güncelleme Zamanı Ayarlama"
weight: 10
---

# ⏰ set_updated_at()

Tablolarda `updated_at` alanını otomatik olarak güncelleyen yardımcı fonksiyon.

---

## Fonksiyon İmzası

```sql
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
```

---

## Amaç

Bir tablo satırı güncellendiğinde (UPDATE) otomatik olarak `updated_at` alanını şu anki zamana ayarlar.

---

## Parametreler

_Bu fonksiyon trigger fonksiyonu olduğu için parametre almaz._

---

## Dönüş Değeri

- **Type**: TRIGGER
- **Returns**: NEW record

---

## SQL Kodu

```sql
CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";
```

---

## Kullanım Örneği

```sql
-- Trigger oluşturma
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
```

---

## Kullanıldığı Tablolar

- `users`
- `classes`
- `exams`
- `student_papers`
- _ve diğer tablolar_

---

## İlgili Trigger'lar

- `update_users_updated_at`
- `update_classes_updated_at`
- `update_exams_updated_at`
- `update_student_papers_updated_at`
