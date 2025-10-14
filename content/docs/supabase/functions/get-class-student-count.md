---
title: "Sınıf Öğrenci Sayısı"
weight: 4
---

# 📊 get_class_student_count()

Bir sınıftaki aktif öğrenci sayısını döndüren fonksiyon.

---

## Fonksiyon İmzası

```sql
CREATE OR REPLACE FUNCTION get_class_student_count(p_class_id INTEGER)
RETURNS INTEGER
```

---

## Amaç

Belirtilen sınıftaki aktif (deleted_at IS NULL) öğrenci sayısını hesaplar. RLS politikalarını bypass etmek için SECURITY DEFINER kullanır.

---

## Parametreler

| Parametre | Tip | Açıklama |
|-----------|-----|----------|
| `p_class_id` | INTEGER | Öğrenci sayısı sorgulanacak sınıfın ID'si |

---

## Dönüş Değeri

- **Type**: INTEGER
- **Açıklama**: Sınıftaki aktif öğrenci sayısı
- **Example**: `25`

---

## SQL Kodu

```sql
CREATE OR REPLACE FUNCTION "public"."get_class_student_count"("p_class_id" integer) RETURNS integer
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  student_count int;
BEGIN
  SELECT COUNT(*)
  INTO student_count
  FROM class_members
  WHERE class_id = p_class_id
    AND deleted_at IS NULL;
  
  RETURN student_count;
END;
$$;

ALTER FUNCTION "public"."get_class_student_count"("p_class_id" integer) OWNER TO "postgres";

COMMENT ON FUNCTION "public"."get_class_student_count"("p_class_id" integer) IS 'Bir sınıftaki aktif öğrenci sayısını döndürür. RLS bypass için SECURITY DEFINER kullanılır.';
```

---

## Kullanım Örneği

```sql
-- Sınıf ID 10'daki öğrenci sayısını öğren
SELECT get_class_student_count(10);
-- Örnek sonuç: 25

-- Flutter/Dart'tan RPC çağrısı
final count = await supabase.rpc('get_class_student_count', params: {'p_class_id': 10});
```

---

## Özellikler

- ✅ **SECURITY DEFINER**: RLS politikalarını bypass eder
- ✅ **STABLE**: Aynı işlem içinde aynı sonucu garanti eder
- ✅ **Sadece Aktif Öğrenciler**: `deleted_at IS NULL` kontrolü yapar
- ✅ **search_path Güvenliği**: Güvenlik için `search_path` 'public' olarak ayarlanmıştır

---

## İlgili Tablolar

- `class_members` - Öğrenci sayısı bu tablodan hesaplanır

---

## Notlar

Bu fonksiyon SECURITY DEFINER olarak tanımlandığı için, çağıran kullanıcının yetkilerinden bağımsız olarak çalışır. Bu, öğrenci sayısını herkesin görebilmesi için gereklidir.
