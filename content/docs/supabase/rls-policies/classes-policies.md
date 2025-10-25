---
title: "Classes Tablosu Politikaları"
weight: 2
---

# 🏫 Classes Tablosu RLS Politikaları

Classes tablosu için Row Level Security politikalarının detaylı açıklamaları.

---

## RLS Durumu

```sql
ALTER TABLE "public"."classes" ENABLE ROW LEVEL SECURITY;
```

---

## Aktif Politikalar

### 1. users_can_view_relevant_classes

Kullanıcılar ilgili oldukları sınıfları görüntüleyebilir (öğrenciler katıldıkları, öğretmenler oluşturdukları, admin/editor tüm sınıfları).

```sql
CREATE POLICY "users_can_view_relevant_classes" 
ON "public"."classes" 
FOR SELECT 
TO "authenticated" 
USING (
  -- Öğrenciler: Katıldıkları sınıflar
  (EXISTS ( 
    SELECT 1
    FROM ("public"."class_members" "cm"
      JOIN "public"."users" "u" ON (("cm"."student_id" = "u"."id")))
    WHERE (("cm"."class_id" = "classes"."id") 
      AND ("u"."auth_user_id" = "auth"."uid"()) 
      AND ("u"."role_id" = 1) 
      AND ("cm"."deleted_at" IS NULL))
  )) 
  OR 
  -- Öğretmenler: Oluşturdukları sınıflar
  (EXISTS ( 
    SELECT 1
    FROM "public"."users" "u"
    WHERE (("u"."id" = "classes"."teacher_id") 
      AND ("u"."auth_user_id" = "auth"."uid"()) 
      AND ("u"."role_id" = 2))
  )) 
  OR 
  -- Admin/Editor: Tüm sınıflar
  (EXISTS ( 
    SELECT 1
    FROM "public"."users" "u"
    WHERE (("u"."auth_user_id" = "auth"."uid"()) 
      AND ("u"."role_id" = ANY (ARRAY[3, 4])))
  ))
);
```

**Amaç**: Rol tabanlı sınıf görüntüleme yetkisi sağlar.

**Koşullar**: 
- **Öğrenciler (role_id=1)**: Sadece katıldıkları aktif sınıfları görür
- **Öğretmenler (role_id=2)**: Sadece kendi oluşturdukları sınıfları görür
- **Admin (role_id=3) ve Editor (role_id=4)**: Tüm sınıfları görür

---

### 2. teachers_admins_editors_can_create_classes

Öğretmenler, adminler ve editorler yeni sınıf oluşturabilir.

```sql
CREATE POLICY "teachers_admins_editors_can_create_classes" 
ON "public"."classes" 
FOR INSERT 
TO "authenticated" 
WITH CHECK (
  EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."id" = "classes"."teacher_id") 
      AND ("users"."role_id" = ANY (ARRAY[2, 3, 4])))
  )
);
```

**Amaç**: Sadece yetkili rollerin sınıf oluşturmasını sağlar.

**Koşullar**:
- Kullanıcı giriş yapmış olmalı (authenticated)
- Kullanıcının rolü teacher (2), admin (3) veya editor (4) olmalı
- Oluşturulan sınıfın teacher_id'si kullanıcının kendi id'si olmalı

---

### 3. owners_can_update_classes

Sınıf sahibi öğretmenler veya admin/editor'ler sınıfları güncelleyebilir.

```sql
CREATE POLICY "owners_can_update_classes" 
ON "public"."classes" 
FOR UPDATE 
TO "authenticated" 
USING (
  -- Öğretmen: Kendi sınıfı
  (("teacher_id" IN ( 
    SELECT "users"."id"
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = 2))
  ))) 
  OR 
  -- Admin/Editor: Tüm sınıflar
  (EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = ANY (ARRAY[3, 4])))
  ))
);
```

**Amaç**: Sınıf sahibi veya admin/editor'lerin sınıf bilgilerini güncellemesini sağlar.

**Koşullar**:
- Öğretmen ise sadece kendi sınıflarını güncelleyebilir
- Admin/Editor tüm sınıfları güncelleyebilir

---

### 4. owners_can_delete_classes

Sınıf sahibi öğretmenler veya admin/editor'ler sınıfları silebilir.

```sql
CREATE POLICY "owners_can_delete_classes" 
ON "public"."classes" 
FOR DELETE 
TO "authenticated" 
USING (
  -- Öğretmen: Kendi sınıfı
  (("teacher_id" IN ( 
    SELECT "users"."id"
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = 2))
  ))) 
  OR 
  -- Admin/Editor: Tüm sınıflar
  (EXISTS ( 
    SELECT 1
    FROM "public"."users"
    WHERE (("users"."auth_user_id" = "auth"."uid"()) 
      AND ("users"."role_id" = ANY (ARRAY[3, 4])))
  ))
);
```

**Amaç**: Sınıf sahibi veya admin/editor'lerin sınıfları silmesini sağlar.

**Koşullar**:
- Öğretmen ise sadece kendi sınıflarını silebilir
- Admin/Editor tüm sınıfları silebilir

### Admins can view all classes

```sql
-- İçeriği buraya ekleyiniz
```

---

## Test Senaryoları

### Başarılı Senaryo - Sınıf Oluşturma
```sql
-- Öğretmen kendi sınıfını oluşturur
INSERT INTO classes (name, teacher_id, school_id)
VALUES ('10-A Matematik', current_teacher_id, current_school_id);
-- ✅ Başarılı
```

### Başarısız Senaryo - Öğrenci Sınıf Oluşturamaz
```sql
-- Öğrenci sınıf oluşturmaya çalışır
INSERT INTO classes (name, teacher_id, school_id)
VALUES ('10-A Matematik', some_teacher_id, current_school_id);
-- ❌ RLS politikası tarafından reddedilir
```

---

## Multi-Tenant Kontrol

RLS politikaları okul bazlı (multi-tenant) veri izolasyonu da sağlamalıdır:

```sql
-- school_id kontrolü eklenmeli
AND school_id = (
  SELECT school_id FROM users WHERE auth_user_id = auth.uid()
)
```

---

## İlgili Tablolar

- `public.classes`
- `public.users`
- `public.roles`
- `public.schools`
- `public.class_members`

---

## Notlar

- ✅ Öğretmen kendi sınıflarını yönetir
- ✅ Multi-tenant okul yapısı desteklenir
- ✅ Rol bazlı erişim kontrolü
- ⚠️ Öğrenci görüntüleme politikası eklenmeli
