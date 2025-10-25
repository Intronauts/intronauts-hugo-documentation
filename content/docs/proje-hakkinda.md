---
title: "Proje Hakkında"
weight: 5
bookFlatSection: false
---

# Intronauts: Yapay Zekâ Destekli Sınav Değerlendirme Platformu


## Proje Hakkında

Intronauts, öğretmenlerin sınav kağıtlarını otomatik olarak **oluşturup değerlendirmesini** sağlayan yapay zekâ destekli bir eğitim platformudur.

Sistem, OCR (Optik Karakter Tanıma) ve LLM (Büyük Dil Modelleri) teknolojilerini bir araya getirerek:
- **Multi-Tenant Okul Yönetimi**: Her okul kendi verilerini güvenle yönetir
- **46 Detaylı İzin Sistemi**: Granüler yetki kontrolü ile güvenli erişim
- **AI Destekli Sınav Oluşturma**: Öğretmenler müfredata göre otomatik soru üretimi yapabilir
- **Otomatik Sınıf Kodları**: 8 karakterlik benzersiz kodlar ile kolay sınıf yönetimi
- **El Yazısı Okuma**: Sınav kağıtlarını dijital metne çevirir
- **Otomatik Değerlendirme**: Açık uçlu sorular dahil tüm cevapları anlam analizine dayalı puanlar
- **Gelişim Takibi**: Öğrencilerin konu bazlı gelişimini analiz eder

Amaç, hem sınav oluşturma hem değerlendirme süreçlerini dijitalleştirerek eğitimde hız, doğruluk ve objektiflik sağlamaktır.

---

## Amaç

Projenin temel amacı, hem sınav oluşturma hem değerlendirme süreçlerini dijitalleştirerek öğretmenlerin zamanını verimli kullanmasını sağlamak ve öğrencilere daha hızlı, adil ve tutarlı bir değerlendirme sunmaktır.

Sistem, sınav sonuçlarını yalnızca bir not olarak değil, öğrencinin konu bazlı gelişimini gösteren anlamlı bir öğrenme verisine dönüştürür.

---

## Sistem Bileşenleri

| Katman | Teknoloji | Açıklama |
|--------|------------|----------|
| **Veritabanı** | PostgreSQL (Supabase v3.3) | Multi-tenant okul yönetimi, 12 tablo, 46 detaylı izin, soft delete, performans indeksleri |
| **Kimlik Doğrulama** | Supabase Auth | Otomatik kullanıcı oluşturma, 4 rol (Admin, Öğretmen, Öğrenci, Editör) |
| **Depolama (Storage)** | Supabase Storage | Private papers bucket, sınav kağıtları, AI çıktıları |
| **Mobil Uygulama** | Flutter | Çoklu platform (Android + iOS) - öğretmen ve öğrenci arayüzü |
| **Web Uygulaması** | React/Next.js | AI Sınav Editörü, yönetim paneli, raporlama |
| **AI Sınav Oluşturma** | LLM (Gemini API) | Müfredata göre soru üretimi, zorluk seviyesi ayarlama |
| **AI Değerlendirme** | n8n + OCR + LLM | El yazısı okuma, otomatik puanlama, geri bildirim üretimi |
| **İş Akışı** | n8n | AI pipeline otomasyonu ve webhook yönetimi |
| **Sınıf Yönetimi** | Otomatik Kod Üreticisi | 8 karakterlik benzersiz sınıf kodları, trigger sistemi |
| **Güvenlik** | RLS Politikaları | Row Level Security ile tablo bazlı erişim kontrolü |
| **API Endpoint'leri** | Hazır HTTP Çağrıları | Auth, sınıf oluşturma, kayıt işlemleri (4 endpoint) |
| **Backend (Gelecek)** | FastAPI / Node.js | Özel AI modelleri ve gelişmiş analitik (yatırım sonrası) |

---

## Sistem Özellikleri ve Roller

Platform dört ana rolden oluşur: **Admin**, **Öğretmen**, **Öğrenci** ve **Editör/Gözetmen**. Her rol, farklı yetkilere sahip paneller üzerinden işlem yapar. Sistem **multi-tenant** yapıda çalışır, her okul kendi verilerini görür ve **46 detaylı izin** ile granüler yetki kontrolü sağlanır.

### Öğretmen Paneli

#### Sınıf ve Müfredat Yönetimi

- Kendi okulunda yeni sınıflar oluşturabilir, **otomatik benzersiz 8 karakterlik sınıf kodları** ile öğrencileri davet edebilir
- Ders müfredatını (syllabus) PDF veya Word formatında sisteme yükleyebilir
- **Row Level Security (RLS)** ile sadece kendi okulundaki sınıfları yönetebilir

#### AI Destekli Sınav Oluşturma

- Öğretmen, "AI Sınav Editörü" üzerinden ders müfredatına veya konu başlıklarına göre sınav oluşturabilir
- Sistem, LLM tabanlı önerilerle soru üretimi, zorluk seviyesi ayarlama, cevap anahtarı oluşturma gibi işlemleri destekler
- Word benzeri düzenleyici ile sorular biçimsel olarak düzenlenebilir; sınav çıktısı PDF veya dijital formatta alınabilir

#### Sınav ve Kağıt Yönetimi

- Cevap anahtarlarını yükleyebilir, sınav kağıtlarını topluca sisteme aktarabilir

#### Yapay Zekâ Destekli Eşleştirme

- Sistem, kağıtlardaki öğrenci bilgilerini (isim, numara) otomatik olarak tanır ve doğru öğrenciyle eşleştirir
- Eşleşmeyen kağıtlar için manuel doğrulama imkânı sunar

### Öğrenci Paneli

#### Sınıfa Katılım

- Öğretmenden aldığı **8 karakterlik benzersiz sınıf kodu** ile sınıfa kolayca katılır

#### Sonuçları Görüntüleme

- Sadece kendi sınavlarının orijinal halini, öğretmen onaylı puanını ve yapay zekânın oluşturduğu geri bildirimleri inceleyebilir
- **Multi-tenant okul bazlı** veri güvenliği ile sadece kendi verilerine erişim

### Editör/Gözetmen Paneli

#### Kurumsal Analiz ve Raporlama

- Okuldaki tüm sınıfları, sınavları ve öğrenci sonuçlarını görüntüleyebilir
- Okul geneli başarı analizleri ve performans raporları oluşturabilir
- **46 detaylı izin** sistemi ile sadece okuma yetkisi ve veri güvenliği sağlanır

### Admin Paneli

#### Sistem Yönetimi

- Tüm kullanıcıları yönetebilir, rollerini değiştirebilir
- Okul bilgilerini güncelleyebilir
- Sistem ayarlarını yapılandırabilir

---
