---
title: "Sınıfa Kod ile Katılım"
weight: 6
---

# 🎓 join_class_by_code()

Öğrencinin sınıf kodunu kullanarak sınıfa katılmasını sağlayan fonksiyon.

---

## Fonksiyon İmzası

```sql
CREATE OR REPLACE FUNCTION join_class_by_code(p_class_code TEXT)
RETURNS JSON
```

---

## Amaç

Öğrencilerin sınıf kodunu girerek sınıfa katılmasını sağlar. Okul kontrolü, rol kontrolü ve duplicate üyelik kontrolü yapar. Hata durumlarında detaylı mesajlar döndürür.

---

## Parametreler

| Parametre | Tip | Açıklama |
|-----------|-----|----------|
| `p_class_code` | TEXT | Sınıfın 8 haneli benzersiz kodu (örn: "A2X9K7B1") |

---

## Dönüş Değeri

**JSON** formatında başarı/hata mesajı:

```json
{
  "success": true,
  "message": "Sınıfa başarıyla katıldınız",
  "class_member_id": 123,
  "class_id": 10,
  "class_name": "10-A Matematik",
  "user_school_id": 1,
  "class_school_id": 1
}
```

---

## SQL Kodu

```sql
CREATE OR REPLACE FUNCTION "public"."join_class_by_code"("p_class_code" "text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_user_id int;
  v_user_role_id int;
  v_user_school_id int;
  v_class_id int;
  v_class_school_id int;
  v_class_name text;
  v_existing_member_id int;
  v_result json;
BEGIN
  -- 1. Mevcut kullanıcıyı al
  SELECT id, role_id, school_id
  INTO v_user_id, v_user_role_id, v_user_school_id
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Debug log
  RAISE NOTICE 'User ID: %, Role: %, School ID: %', v_user_id, v_user_role_id, v_user_school_id;

  -- Kullanıcı bulunamadıysa
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Oturum açmanız gerekiyor.'
      USING HINT = 'USER_NOT_FOUND';
  END IF;

  -- 2. Role kontrolü - sadece öğrenciler (role_id = 1)
  IF v_user_role_id != 1 THEN
    RAISE EXCEPTION 'Sadece öğrenciler sınıfa katılabilir.'
      USING HINT = 'INVALID_ROLE';
  END IF;

  -- 3. Sınıfı kod ile bul
  SELECT id, school_id, name
  INTO v_class_id, v_class_school_id, v_class_name
  FROM classes
  WHERE code = UPPER(TRIM(p_class_code));

  -- Debug log
  RAISE NOTICE 'Class ID: %, Class School ID: %, Class Name: %', v_class_id, v_class_school_id, v_class_name;

  -- Sınıf bulunamadıysa
  IF v_class_id IS NULL THEN
    RAISE EXCEPTION 'Geçersiz sınıf kodu: %', p_class_code
      USING HINT = 'CLASS_NOT_FOUND';
  END IF;

  -- 4. OKUL KONTROLÜ - DÜZELTME
  -- NULL kontrolü ekledik ve COALESCE kullandık
  IF COALESCE(v_class_school_id, -1) != COALESCE(v_user_school_id, -2) THEN
    RAISE EXCEPTION 'Bu sınıf farklı bir okula ait. (Sınıf Okul ID: %, Öğrenci Okul ID: %)', 
      v_class_school_id, v_user_school_id
      USING HINT = 'SCHOOL_MISMATCH';
  END IF;

  -- 5. Öğrenci zaten bu sınıfta mı kontrol et (aktif üyelik)
  SELECT id
  INTO v_existing_member_id
  FROM class_members
  WHERE class_id = v_class_id
    AND student_id = v_user_id
    AND deleted_at IS NULL;

  -- Zaten üyeyse
  IF v_existing_member_id IS NOT NULL THEN
    RAISE EXCEPTION 'Zaten bu sınıftasınız.'
      USING HINT = 'ALREADY_MEMBER';
  END IF;

  -- 6. Sınıfa katıl (INSERT)
  INSERT INTO class_members (class_id, student_id, joined_at)
  VALUES (v_class_id, v_user_id, NOW())
  RETURNING id INTO v_existing_member_id;

  -- 7. Başarı mesajı döndür
  v_result := json_build_object(
    'success', true,
    'message', 'Sınıfa başarıyla katıldınız',
    'class_member_id', v_existing_member_id,
    'class_id', v_class_id,
    'class_name', v_class_name,
    'user_school_id', v_user_school_id,
    'class_school_id', v_class_school_id
  );

  RAISE NOTICE 'Success: %', v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    -- Hata mesajını logla ve yeniden fırlat
    RAISE EXCEPTION '%', SQLERRM
      USING HINT = SQLSTATE;
END;
$$;

ALTER FUNCTION "public"."join_class_by_code"("p_class_code" "text") OWNER TO "postgres";

COMMENT ON FUNCTION "public"."join_class_by_code"("p_class_code" "text") IS 'Öğrencinin sınıf kodunu kullanarak sınıfa katılmasını sağlar. Okul kontrolü eklenmiştir.';
```

---

## Kullanım Örneği

```sql
-- SQL'den kullanım
SELECT join_class_by_code('A2X9K7B1');

-- Flutter/Dart'tan RPC çağrısı
try {
  final result = await supabase.rpc('join_class_by_code', 
    params: {'p_class_code': 'A2X9K7B1'}
  );
  print('Başarılı: ${result['message']}');
} catch (e) {
  print('Hata: $e');
}
```

---

## Hata Mesajları

| Hata | HINT | Açıklama |
|------|------|----------|
| "Oturum açmanız gerekiyor" | USER_NOT_FOUND | Kullanıcı auth.uid() ile bulunamadı |
| "Sadece öğrenciler sınıfa katılabilir" | INVALID_ROLE | Öğrenci rolü (role_id=1) değil |
| "Geçersiz sınıf kodu: XXX" | CLASS_NOT_FOUND | Girilen kod ile sınıf bulunamadı |
| "Bu sınıf farklı bir okula ait" | SCHOOL_MISMATCH | Öğrenci ve sınıf farklı okullarda |
| "Zaten bu sınıftasınız" | ALREADY_MEMBER | Aktif üyelik zaten var |

---

## Özellikler

- ✅ **SECURITY DEFINER**: RLS politikalarını bypass eder
- ✅ **Okul Kontrolü**: Sadece aynı okuldaki sınıflara katılım
- ✅ **Rol Kontrolü**: Sadece öğrenciler (role_id=1) katılabilir
- ✅ **Duplicate Kontrolü**: Tekrar katılım engellenir
- ✅ **Debug Logging**: RAISE NOTICE ile detaylı loglar
- ✅ **Exception Handling**: Tüm hatalar yakalanır ve anlamlı mesajlar döner
- ✅ **Case-Insensitive**: Kod UPPER() ve TRIM() ile normalize edilir
- ✅ **NULL-Safe**: COALESCE ile NULL değerler güvenli şekilde karşılaştırılır

---

## İlgili Tablolar

- `users` - Kullanıcı bilgisi ve okul ID'si
- `classes` - Sınıf bilgisi ve okul ID'si
- `class_members` - Üyelik kaydı
- `auth.users` - Oturum bilgisi (auth.uid())

---

## İş Akışı

1. **Kullanıcı Kontrolü**: auth.uid() ile mevcut kullanıcıyı bul
2. **Rol Kontrolü**: Sadece öğrenciler (role_id=1) devam edebilir
3. **Sınıf Kontrolü**: Kod ile sınıf bulunur
4. **Okul Kontrolü**: Aynı okul kontrolü yapılır
5. **Duplicate Kontrolü**: Zaten üye mi kontrol edilir
6. **Katılım**: class_members tablosuna INSERT yapılır
7. **Başarı Mesajı**: JSON ile detaylı bilgi döndürülür

---

## Notlar

- Bu fonksiyon, öğrencilerin uygulamadan sınıf kodunu girerek sınıfa katılması için kullanılır
- Multi-tenant mimaride okul kontrolü kritik önem taşır
- SECURITY DEFINER kullanıldığı için, öğrenciler normal RLS politikaları olmadan da sınıfa katılabilir
