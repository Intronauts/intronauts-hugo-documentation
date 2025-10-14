---
title: "Sınıf Öğrenci Listesi"
weight: 5
---

# 👥 get_class_students()

Bir sınıftaki tüm aktif öğrencilerin listesini döndüren fonksiyon.

---

## Fonksiyon İmzası

```sql
CREATE OR REPLACE FUNCTION get_class_students(p_class_id INTEGER)
RETURNS TABLE (
  id INTEGER,
  name VARCHAR,
  email VARCHAR,
  school_number VARCHAR,
  joined_at TIMESTAMPTZ
)
```

---

## Amaç

Belirtilen sınıftaki aktif öğrencilerin detaylı listesini döndürür. RLS politikalarını bypass etmek için SECURITY DEFINER kullanır.

---

## Parametreler

| Parametre | Tip | Açıklama |
|-----------|-----|----------|
| `p_class_id` | INTEGER | Öğrenci listesi sorgulanacak sınıfın ID'si |

---

## Dönüş Değeri

**TABLE** yapısında döner:

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | INTEGER | Öğrencinin ID'si |
| `name` | VARCHAR | Öğrencinin adı |
| `email` | VARCHAR | Öğrencinin email adresi |
| `school_number` | VARCHAR | Öğrencinin okul numarası |
| `joined_at` | TIMESTAMPTZ | Sınıfa katılma zamanı |

---

## SQL Kodu

```sql
CREATE OR REPLACE FUNCTION "public"."get_class_students"("p_class_id" integer) RETURNS TABLE("id" integer, "name" character varying, "email" character varying, "school_number" character varying, "joined_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.name,
    u.email,
    u.school_number,
    cm.joined_at
  FROM class_members cm
  INNER JOIN users u ON cm.student_id = u.id
  WHERE cm.class_id = p_class_id
    AND cm.deleted_at IS NULL
  ORDER BY cm.joined_at ASC;
END;
$$;

ALTER FUNCTION "public"."get_class_students"("p_class_id" integer) OWNER TO "postgres";

COMMENT ON FUNCTION "public"."get_class_students"("p_class_id" integer) IS 'Bir sınıftaki aktif öğrenci listesini döndürür. RLS bypass için SECURITY DEFINER kullanılır.';
```

---

## Kullanım Örneği

```sql
-- Sınıf ID 10'daki öğrencileri listele
SELECT * FROM get_class_students(10);

-- Flutter/Dart'tan RPC çağrısı
final students = await supabase.rpc('get_class_students', params: {'p_class_id': 10});

// Sonuç örneği:
// [
//   {
//     "id": 42,
//     "name": "Ahmet Yılmaz",
//     "email": "ahmet@okul.edu.tr",
//     "school_number": "2024001",
//     "joined_at": "2025-01-15T10:30:00Z"
//   },
//   ...
// ]
```

---

## Özellikler

- ✅ **SECURITY DEFINER**: RLS politikalarını bypass eder
- ✅ **STABLE**: Aynı işlem içinde aynı sonucu garanti eder
- ✅ **Sadece Aktif Öğrenciler**: `deleted_at IS NULL` kontrolü yapar
- ✅ **Sıralama**: Katılma tarihine göre sıralı döner (ASC)
- ✅ **JOIN Optimizasyonu**: INNER JOIN ile sadece ilişkili kayıtları getirir
- ✅ **search_path Güvenliği**: Güvenlik için `search_path` 'public' olarak ayarlanmıştır

---

## İlgili Tablolar

- `class_members` - Sınıf üyelik bilgisi
- `users` - Öğrenci detay bilgisi

---

## Notlar

Bu fonksiyon SECURITY DEFINER olarak tanımlandığı için, öğretmenlerin ve adminlerin kendi sınıflarındaki öğrencileri görmesi için gerekli yetkileri sağlar. RLS politikaları bu fonksiyon içinde bypass edilir.
