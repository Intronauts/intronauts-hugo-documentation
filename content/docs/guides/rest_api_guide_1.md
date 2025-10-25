---
title: "REST API Rehberi"
weight: 45
---

# Supabase ile Özellik Geliştirme ve REST API Entegrasyonu — Genel Rehber

## 1. **Veritabanı Modelleme**

1. Özelliğin ihtiyacını belirle (ör: sınıf ekleme için hangi alanlar gerekli?).
2. Gerekirse tabloyu oluştur:
3. İlişkili tablo/alanlar varsa (örn: foreign key), ona göre modellemeyi yap.

---

## 2. **Otomasyon ve İş Kuralları — Trigger/Fonksiyon Ekleme**

Özellik gerektiriyorsa (ör: benzersiz bir kod otomatik üretilsin):

```sql
CREATE OR REPLACE FUNCTION generate_class_code()
RETURNS trigger AS $$
DECLARE
  new_code text;
BEGIN
  LOOP
    new_code := lpad((trunc(random()*1000000)::int)::text, 6, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM classes WHERE code = new_code);
  END LOOP;
  NEW.code := new_code;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_class_code
BEFORE INSERT ON classes
FOR EACH ROW
WHEN (NEW.code IS NULL)
EXECUTE FUNCTION generate_class_code();
````

* **Her zaman trigger/fonksiyonlar DB tarafında tanımlanır; client sadece gerekli alanları gönderir.**

---

## 3. **Row Level Security (RLS) ve Policy Tanımlama**

1. Tabloya RLS aç:

   ```sql
   ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
   ```

2. Güvenli erişim için policy oluştur (ör: sadece kendi adına kayıt ekleyebilsin):

   ```sql
   CREATE POLICY "insert_own_class" ON public.classes
     FOR INSERT TO authenticated
     WITH CHECK (
       teacher_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
     );
   ```

3. Gerekiyorsa SELECT/UPDATE/DELETE policy’leri de benzer şekilde yazılır.

---

## 4. **Supabase REST API Endpoint’i Kullanıma Açma**

* Supabase, her tabloyu otomatik olarak REST endpoint’e açar:

  ```
  POST https://<project>.supabase.co/rest/v1/classes
  ```
* Endpoint üzerinden yapılabilecek işlemler:

  * POST (ekleme), GET (listeleme), PATCH (güncelleme), DELETE (silme)

---

## 5. **Flutter (veya Başka Bir Client) ile Entegrasyon**

1. **Kullanıcı Login Olur:**

   * Auth ile login → JWT token ve user uuid alınır.
   * Gerekirse, users tablosundan kendi INT id’sini bulur:

     ```dart
     final userId = Supabase.instance.client.auth.currentUser?.id;
     final userRow = await Supabase.instance.client
         .from('users')
         .select('id')
         .eq('auth_user_id', userId)
         .single();
     final teacherId = userRow['id'];
     ```

2. **Formdan Bilgiler Toplanır:**

   * Gerekli alanlar alınır (örn: name, academic_year, term, school_id, teacher_id).

3. **REST API’ye POST Atılır:**

   * JWT ve anon-key mutlaka header’da olmalı.

     ```dart
     final classData = {
       'name': name,
       'academic_year': academicYear,
       'term': term,
       'school_id': schoolId,
       'teacher_id': teacherId,
     };
     final res = await Supabase.instance.client
         .from('classes')
         .insert(classData)
         .execute();
     ```

---

## 6. **Test ve Kontrol**

* POST sonucunda dönen response’da otomasyonlar (ör: code alanı) doğru çalıştı mı kontrol edilir.
* Hata alınırsa (401/403, policy hatası), policy ve istek alanları tekrar gözden geçirilir.
* Kullanıcı sadece kendi hakkıyla işlem yapabiliyor mu? (güvenlik testi)

---

## 7. **Bakım ve Geliştirme İpuçları**

* Policy ve trigger’ları projeye özel, *her tablo ve özellik için ayrı* yaz.
* Production’da RLS olmadan **asla** çalıştırma!
* REST endpointleri dokümante et (endpoint, method, gerekli alanlar, örnek request/response).
* Ekip içi her yeni özellikte yukarıdaki adımları tekrar et:
  → Model, trigger, policy, endpoint, client kodu, test.

---

## 8. **Ek: API ve Policy Hatası Çözüm Adımları**

* 401/403 → JWT, policy ya da RLS’de problem olabilir; policy’yi incele.
* Alan uyuşmazlığı → Gönderdiğin alan ve tablo şeması eşleşiyor mu bak.
* Trigger çalışmıyor → Trigger/fonksiyon scriptini ve BEFORE/AFTER tanımını kontrol et.
* Response’da hata varsa **hata mesajını logla** ve ona göre düzenleme yap.

---

## 9. **Özet Akış**

1. Tablo ve alanlar tanımlanır.
2. Gerekirse trigger/fonksiyon eklenir.
3. RLS açılır, güvenli policy yazılır.
4. Endpoint belirlenir.
5. Client (Flutter, Postman, vs.) ile JWT/anon-key ile test edilir.
6. Sonuç ve otomasyonlar kontrol edilir.
7. Ekibe uygun şekilde dokümante edilir.

---

**Not:**
Bu rehber, sadece “sınıf ekleme” değil, tüm benzer veri işlemlerinde (sınav, öğrenci, not, belge vb.)
Supabase REST API + policy + trigger + Flutter entegrasyonu için “standart yol haritası” olarak kullanılmalıdır.