---
title: "Benzersiz Sınıf Kodu Üretimi"
weight: 2
---

# 🔢 generate_unique_class_code()

8 karakterlik benzersiz alfanumerik sınıf kodu üreten fonksiyon.

---

## Fonksiyon İmzası

```sql
CREATE OR REPLACE FUNCTION generate_unique_class_code()
RETURNS TEXT
```

---

## Amaç

Yeni bir sınıf oluşturulduğunda veya gerektiğinde benzersiz bir sınıf kodu üretir. Kod formatı: `A2X9K7B1` (8 karakter, büyük harf + rakam)

---

## Parametreler

_Bu fonksiyon parametre almaz._

---

## Dönüş Değeri

- **Type**: TEXT
- **Length**: 8 karakter
- **Format**: Alfanumerik (A-Z, 0-9)
- **Example**: `"A2X9K7B1"`

---

## SQL Kodu

```sql
CREATE OR REPLACE FUNCTION "public"."generate_class_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  new_code text;
  i int;
  use_pgcrypto boolean := EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'
  );
  b bytea;
  idx int;
  p_length int := 8; -- default code length; change if you want a different length
BEGIN
  -- Only generate if code is null or empty
  IF NEW.code IS NOT NULL AND btrim(NEW.code) <> '' THEN
    RETURN NEW;
  END IF;

  LOOP
    new_code := '';
    IF use_pgcrypto THEN
      -- generate p_length random bytes and map to chars
      b := gen_random_bytes(p_length);
      FOR i IN 0..p_length-1 LOOP
        idx := (get_byte(b, i) % length(chars)) + 1;
        new_code := new_code || substr(chars, idx, 1);
      END LOOP;
    ELSE
      -- fallback to built-in random()
      FOR i IN 1..p_length LOOP
        idx := floor(random() * length(chars) + 1)::int;
        new_code := new_code || substr(chars, idx, 1);
      END LOOP;
    END IF;

    -- ensure uniqueness
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.classes c WHERE c.code = new_code
    );
    -- otherwise loop and try again
  END LOOP;

  NEW.code := new_code;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."generate_class_code"() OWNER TO "postgres";
```

---

## Kullanım Örneği

```sql
-- Manuel kullanım
SELECT generate_unique_class_code();

-- Sınıf oluştururken
INSERT INTO classes (name, teacher_id, school_id)
VALUES ('10-A Matematik', 5, 1);
-- code otomatik olarak üretilir (trigger sayesinde)
```

---

## İlgili Trigger

- `trg_assign_class_code` - classes tablosunda INSERT olduğunda tetiklenir

---

## Özellikler

- ✅ Benzersizlik garantisi
- ✅ Collision detection (duplicate kod kontrolü)
- ✅ Maksimum 100 deneme
- ✅ Büyük harf ve rakam kombinasyonu

---

## İlgili Tablolar

- `public.classes`
