---
title: "Yeni Auth Kullanıcısı Trigger"
weight: 1
---

# 🔑 on_auth_user_created

Yeni bir Supabase Auth kullanıcısı oluşturulduğunda tetiklenen trigger.

---

## Trigger Tanımı

```sql
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_auth_user();
```

---

## Amaç

Auth sisteminde yeni kullanıcı kaydı oluşturulduğunda otomatik olarak public.users tablosuna kullanıcı bilgilerini kopyalar.

---

## Tetiklenme Koşulu

- **Event**: INSERT
- **Timing**: AFTER
- **Level**: ROW
- **Table**: auth.users

---

## Çalıştırdığı Fonksiyon

[handle_new_auth_user()](/docs/supabase/functions/handle-new-auth-user/)

---

## SQL Kodu

```sql
CREATE TRIGGER on_auth_user_created 
AFTER INSERT ON auth.users 
FOR EACH ROW 
EXECUTE FUNCTION handle_new_auth_user();
```

---

## Kullanım Senaryosu

1. Kullanıcı Flutter app'te kayıt olur
2. Supabase Auth yeni kullanıcı oluşturur (auth.users)
3. Trigger otomatik tetiklenir
4. `handle_new_auth_user()` fonksiyonu çalışır
5. public.users tablosuna kullanıcı eklenir

---

## İlgili Tablolar

- `auth.users` (source)
- `public.users` (target)
- `public.roles`
- `public.schools`

---

## Notlar

- ✅ Otomatik kullanıcı profili oluşturma
- ✅ Meta data'dan rol ve okul bilgisi çıkarma
- ✅ Duplicate email kontrolü
- ⚠️ Bu trigger devre dışı bırakılırsa manuel kullanıcı oluşturma gerekir
