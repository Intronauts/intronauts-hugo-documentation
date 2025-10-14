---
title: "Student Papers Politikaları"
weight: 4
---

# 📄 Student Papers Tablosu RLS Politikaları

Student Papers tablosu için Row Level Security politikalarının detaylı açıklamaları.

---

## Planlanan Politikalar

### 1. Students can view own papers

Öğrenciler sadece kendi sınav kağıtlarını görüntüleyebilir.

```sql
-- İçeriği buraya ekleyiniz
```

**Amaç**: Öğrencinin sadece kendi sınav sonuçlarını görmesini sağlar.

**Koşul**:
- Kullanıcı giriş yapmış olmalı
- Kullanıcının rolü student olmalı
- Kağıdın student_id'si kullanıcının id'si ile eşleşmeli
- Kağıt durumu 'published' olmalı (öğretmen tarafından yayınlanmış)

---

### 2. Teachers can view class papers

Öğretmenler kendi sınıflarındaki sınav kağıtlarını görüntüleyebilir.

```sql
-- İçeriği buraya ekleyiniz
```

**Amaç**: Öğretmenin kendi sınıflarındaki tüm öğrenci kağıtlarını görmesini sağlar.

**Koşul**:
- Kullanıcı giriş yapmış olmalı
- Kullanıcının rolü teacher olmalı
- Kağıdın bağlı olduğu sınav, öğretmenin sınıflarından birine ait olmalı

---

### 3. Teachers can evaluate papers

Öğretmenler sınav kağıtlarını değerlendirebilir ve puanlayabilir.

```sql
-- İçeriği buraya ekleyiniz
```

**Amaç**: Öğretmenin sınav kağıtlarına puan vermesi ve geri bildirim eklemesini sağlar.

**Koşul**:
- Kullanıcı giriş yapmış olmalı
- Kullanıcının rolü teacher olmalı
- Sadece teacher_score ve feedback alanları güncellenebilir

---

## Özel Durumlar

### Yayınlanmamış Kağıtlar
Öğrenciler sadece 'published' durumundaki kağıtları görmelidir.

```sql
AND paper_status = 'published'
```

### AI Puanı vs Öğretmen Puanı
- Öğrenciler: Sadece teacher_score'u görür
- Öğretmenler: Hem ai_score hem de teacher_score'u görür

---

## Test Senaryoları

### Başarılı Senaryo - Öğrenci Kendi Kağıdını Görür
```sql
-- Öğrenci kendi kağıdını sorgular
SELECT * FROM student_papers 
WHERE student_id = current_student_id 
AND paper_status = 'published';
-- ✅ Başarılı
```

### Başarısız Senaryo - Öğrenci Başkasının Kağıdını Görmeye Çalışır
```sql
-- Öğrenci başka öğrencinin kağıdını görmeye çalışır
SELECT * FROM student_papers WHERE student_id = other_student_id;
-- ❌ Boş sonuç (RLS filtreler)
```

---

## İlgili Tablolar

- `public.student_papers`
- `public.exams`
- `public.classes`
- `public.users`
- `public.roles`

---

## Notlar

- ✅ Öğrenci sadece yayınlanmış kağıtları görür
- ✅ Öğretmen tüm kağıtları yönetir
- ✅ AI puanı ile öğretmen puanı ayrı tutulur
- ⚠️ Multi-tenant okul kontrolü eklenmeli
- ⚠️ Politikalar henüz oluşturulmadı (planlanan)
