---
title: "Class Members Tablosu Politikaları"
weight: 3
---

# 👥 Class Members Tablosu RLS Politikaları

Class Members (Sınıf Üyelikleri) tablosu için Row Level Security politikalarının detaylı açıklamaları.

---

## RLS Durumu

```sql
ALTER TABLE "public"."class_members" ENABLE ROW LEVEL SECURITY;
```

---

## Aktif Politikalar

### 1. users_can_view_memberships

Kullanıcılar ilgili oldukları üyelikleri görüntüleyebilir (öğrenciler kendi üyeliklerini, admin/editor tüm üyelikleri).

```sql
CREATE POLICY "users_can_view_memberships" 
ON "public"."class_members" 
FOR SELECT 
TO "authenticated" 
USING (
  -- Öğrenciler: Kendi üyelikleri
  (("student_id" IN ( 
    SELECT "users"."id"
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = 1))
  ))) 
  OR 
  -- Admin/Editor: Tüm üyelikler
  (EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = ANY (ARRAY[3, 4])))
  ))
);
```

**Amaç**: Rol tabanlı üyelik görüntüleme yetkisi sağlar.

**Koşullar**: 
- **Öğrenciler (role_id=1)**: Sadece kendi sınıf üyeliklerini görür
- **Admin (role_id=3) ve Editor (role_id=4)**: Tüm üyelikleri görür
- **Not**: Öğretmenler bu politika ile doğrudan göremez, kendi sınıflarındaki öğrencileri `get_class_students()` fonksiyonu ile görür

---

### 2. authenticated_can_insert_memberships

Giriş yapmış kullanıcılar üyelik ekleyebilir (öğrenciler kendi üyeliklerini, admin/editor tüm üyelikleri).

```sql
CREATE POLICY "authenticated_can_insert_memberships" 
ON "public"."class_members" 
FOR INSERT 
TO "authenticated" 
WITH CHECK (
  -- Öğrenci: Kendi üyeliği
  (("student_id" IN ( 
    SELECT "users"."id"
    FROM "public"."users"
    WHERE ("users"."auth_user_id" = "auth"."uid"())
  ))) 
  OR 
  -- Admin/Editor: Herhangi bir üyelik
  (EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = ANY (ARRAY[3, 4])))
  ))
);
```

**Amaç**: Öğrencilerin sınıfa katılmasını ve admin/editor'lerin üyelik oluşturmasını sağlar.

**Koşullar**:
- **Öğrenciler**: Sadece kendi student_id'si ile üyelik oluşturabilir
- **Admin/Editor**: Herhangi bir öğrenci için üyelik oluşturabilir
- **Not**: Öğrenciler genellikle `join_class_by_code()` fonksiyonu ile sınıfa katılır (SECURITY DEFINER ile RLS bypass)

---

### 3. students_can_update_own_memberships

Öğrenciler kendi üyeliklerini güncelleyebilir, admin/editor tüm üyelikleri güncelleyebilir.

```sql
CREATE POLICY "students_can_update_own_memberships" 
ON "public"."class_members" 
FOR UPDATE 
TO "authenticated" 
USING (
  -- Öğrenci: Kendi üyeliği
  (("student_id" IN ( 
    SELECT "users"."id"
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = 1))
  ))) 
  OR 
  -- Admin/Editor: Tüm üyelikler
  (EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = ANY (ARRAY[3, 4])))
  ))
) 
WITH CHECK (
  -- Öğrenci: Kendi üyeliği
  (("student_id" IN ( 
    SELECT "users"."id"
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = 1))
  ))) 
  OR 
  -- Admin/Editor: Tüm üyelikler
  (EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = ANY (ARRAY[3, 4])))
  ))
);
```

**Amaç**: Öğrencilerin üyelik bilgilerini güncellemesini sağlar (örn: sınıftan ayrılma - soft delete).

**Koşullar**:
- **Öğrenciler**: Sadece kendi üyeliklerini güncelleyebilir
- **Admin/Editor**: Tüm üyelikleri güncelleyebilir
- **USING**: Hangi kayıtları güncelleyebilir
- **WITH CHECK**: Güncellenmiş kayıt hangi koşulları sağlamalı

---

## Kullanım Senaryoları

### Öğrenci Sınıfa Katılır

```sql
-- RPC fonksiyonu kullanımı (önerilen)
SELECT join_class_by_code('A2X9K7B1');

-- Alternatif: Direkt INSERT (RLS geçerli)
INSERT INTO class_members (class_id, student_id, joined_at)
VALUES (10, current_user_id, NOW());
```

### Öğrenci Sınıftan Ayrılır (Soft Delete)

```sql
UPDATE class_members
SET deleted_at = NOW()
WHERE id = 123 AND student_id = current_user_id;
```

### Admin Öğrenci Ekler

```sql
INSERT INTO class_members (class_id, student_id, joined_at)
VALUES (10, 42, NOW());
-- Admin olduğu için herhangi bir student_id kullanabilir
```

---

## Güvenlik Notları

- **Öğretmen Erişimi**: Öğretmenler bu tabloya doğrudan erişemez, bunun yerine `get_class_students()` fonksiyonu kullanır
- **Soft Delete**: deleted_at alanı ile soft delete yapılır, kayıtlar fiziksel olarak silinmez
- **SECURITY DEFINER Fonksiyonlar**: `join_class_by_code()` gibi fonksiyonlar RLS'yi bypass eder ve ekstra güvenlik kontrolleri yapar
- **Rol Kontrolü**: Her politika kullanıcının role_id'sini kontrol eder

---

## İlgili Fonksiyonlar

- [join_class_by_code()](/docs/supabase/functions/join-class-by-code/) - Öğrencinin sınıfa katılması
- [get_class_students()](/docs/supabase/functions/get-class-students/) - Sınıftaki öğrencileri listeleme
- [get_class_student_count()](/docs/supabase/functions/get-class-student-count/) - Öğrenci sayısını öğrenme

---

## Roller (role_id)

- **1**: Student (Öğrenci)
- **2**: Teacher (Öğretmen)
- **3**: Admin (Yönetici)
- **4**: Editor (Editör)
