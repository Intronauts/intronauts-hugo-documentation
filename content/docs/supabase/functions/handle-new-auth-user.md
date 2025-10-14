---
title: "Yeni Kullanıcı Oluşturma (handle_new_auth_user)"
weight: 1
---

# Yeni Kullanıcı Oluşturma (handle_new_auth_user)

## Fonksiyon Tanımı

```sql
CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  user_role text;
  resolved_role_id int;
  resolved_school_id int;
  student_school_number text;
  user_birth_date date;
begin
  user_role := coalesce(
    new.raw_app_meta_data->>'role',
    new.raw_user_meta_data->>'role',
    'student'
  );
  resolved_school_id := coalesce(
    (new.raw_user_meta_data->>'school_id')::int,
    1
  );

  select id into resolved_role_id
  from public.roles
  where lower(name) = lower(user_role)
  limit 1;

  if resolved_role_id is null then
    select id into resolved_role_id from public.roles where name = 'student' limit 1;
  end if;

  if lower(user_role) = 'student' then
    student_school_number := new.raw_user_meta_data->>'school_number';
  else
    student_school_number := null;
  end if;

  if new.raw_user_meta_data ? 'birth_date' then
    user_birth_date := to_date(new.raw_user_meta_data->>'birth_date', 'YYYY-MM-DD');
  else
    user_birth_date := null;
  end if;

  if exists(select 1 from public.users where email = new.email) then
    return new;
  end if;

  insert into public.users (
    school_id,
    name,
    email,
    phone_number,
    school_number,
    birth_date,
    role_id,
    auth_user_id,
    created_at,
    updated_at
  )
  values (
    resolved_school_id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'phone_number',
    student_school_number,
    user_birth_date,
    resolved_role_id,
    new.id,
    now(),
    now()
  );

  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";
```

## Açıklama

Bu fonksiyon, Supabase Auth'da yeni bir kullanıcı oluşturulduğunda tetiklenir ve kullanıcıyı public.users tablosuna ekler. **SECURITY DEFINER** olarak tanımlandığı için, fonksiyon owner'ın (postgres) yetkileriyle çalışır ve RLS politikalarını bypass eder.

### Özellikler

- **Rol Belirleme**: Kullanıcının rolünü meta verilerden alır, yoksa varsayılan olarak "student" olarak atar
- **Okul Ataması**: Meta verilerden school_id alır, yoksa varsayılan olarak 1 atar
- **Okul Numarası**: Sadece öğrenciler için school_number ataması yapar
- **Doğum Tarihi**: YYYY-MM-DD formatında doğum tarihini parse eder
- **Çift Kayıt Kontrolü**: Aynı email ile zaten kayıt varsa, ekleme yapmaz

### Çalışma Mantığı

1. Kullanıcının rolünü belirler (raw_app_meta_data veya raw_user_meta_data'dan)
2. Okul ID'sini belirler (varsayılan: 1)
3. Rol ID'sini public.roles tablosundan çeker
4. Eğer öğrenci ise, okul numarasını atar
5. Doğum tarihini parse eder (varsa)
6. Email kontrolü yapar, zaten varsa işlem yapmaz
7. public.users tablosuna yeni kullanıcı kaydını ekler

## Parametreler

- **trigger**: NEW row (auth.users'dan gelen veri)
  - `raw_app_meta_data->>'role'`: Uygulama meta verisinden rol
  - `raw_user_meta_data->>'role'`: Kullanıcı meta verisinden rol
  - `raw_user_meta_data->>'school_id'`: Okul ID'si
  - `raw_user_meta_data->>'school_number'`: Okul numarası (öğrenciler için)
  - `raw_user_meta_data->>'birth_date'`: Doğum tarihi
  - `raw_user_meta_data->>'name'`: İsim
  - `raw_user_meta_data->>'phone_number'`: Telefon numarası

## Döndürdüğü Değer

NEW row (auth.users kaydı)

## Kullanım Örneği

Kayıt işlemi sırasında otomatik olarak çalışır. Supabase Auth'da yeni kullanıcı oluşturulduğunda, bu fonksiyon tetiklenir ve kullanıcı bilgilerini public.users tablosuna senkronize eder.
