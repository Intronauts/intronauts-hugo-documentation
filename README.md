# 🎓 Okula Bukula - Hugo Dokümantasyon

**Yapay Zekâ Destekli Sınav Değerlendirme Platformu - Teknik Dokümantasyon**

Bu proje, Okula Bukula sisteminin tüm teknik dokümantasyonunu içeren Hugo tabanlı bir dokümantasyon sitesidir.

---

## 📚 İçerik

Bu dokümantasyon şunları kapsar:

- 🗄️ **Veritabanı Tasarımı**: Multi-tenant PostgreSQL şeması (12 tablo)
- 🔧 **Supabase Kurulumu**: Adım adım kurulum rehberi
- 💻 **Authentication Sistemi**: Supabase Auth entegrasyonu
- 📖 **Implementation Rehberleri**: Özellik geliştirme kılavuzları
- 🔒 **RBAC Güvenlik**: Rol bazlı erişim kontrolü (46 izin)
- 🌐 **API Dokümantasyonu**: REST API endpoint'leri
- 🎨 **Figma Tasarımları**: Mobil uygulama UI/UX ekranları
- 📋 **Changelog**: Versiyon geçmişi ve güncellemeler

---

## 🚀 Hızlı Başlangıç

### Gereksinimler

- Hugo Extended (v0.150.0+)
- Git

### Kurulum

1. **Repository'yi klonlayın:**
```bash
git clone https://github.com/Intronauts/intronauts-hugo-documentation.git
cd intronauts-hugo-documentation
```

2. **Tema bağımlılıklarını indirin:**
```bash
git submodule update --init --recursive
```

3. **Geliştirme sunucusunu başlatın:**
```bash
hugo server -D
```

4. **Tarayıcınızda açın:** http://localhost:1313

---

## 🌐 GitHub Pages Deployment

Bu proje GitHub Actions ile otomatik olarak GitHub Pages'e deploy edilir.

### 📦 Canlı Site
**URL:** https://intronauts.github.io/intronauts-hugo-documentation/

### 🚀 Otomatik Deployment
- Her `main` branch'e push edildiğinde otomatik olarak build ve deploy edilir
- GitHub Actions workflow: `.github/workflows/deploy.yml`
- Ortalama build süresi: 1-2 dakika

### 📋 Deployment Adımları

1. **GitHub Repository Ayarları:**
   - Settings > Pages > Source: **GitHub Actions** seçin

2. **Kod Push Edin:**
```bash
git add .
git commit -m "Your commit message"
git push
```

3. **Deployment İzleyin:**
   - GitHub repository'nizde **Actions** sekmesine gidin
   - "Deploy Hugo site to GitHub Pages" workflow'unu görüntüleyin

Detaylı talimatlar için: `.github/workflows/deploy-instructions.md`

---

## 📦 Üretim Build'i

```bash
hugo
```

Build dosyaları `public/` klasöründe oluşturulacaktır.

---

## 📝 Yeni İçerik Ekleme

Yeni bir dokümantasyon sayfası oluşturmak için:

```bash
hugo new content docs/kategori/sayfa-adi.md
```

**Front matter örneği:**
```yaml
---
title: "Sayfa Başlığı"
weight: 10
bookCollapseSection: false
---
```

---

## 📂 Klasör Yapısı

```
intronauts-hugo-documentation/
│
├── content/
│   ├── docs/
│   │   ├── _index.md                    # Ana dokümantasyon sayfası
│   │   ├── proje-hakkinda.md            # Proje tanıtımı
│   │   ├── kurulum.md                   # Kurulum rehberi
│   │   ├── icerik-olusturma.md          # İçerik oluşturma kılavuzu
│   │   ├── supabase-setup.md            # Supabase kurulum rehberi
│   │   ├── figma-tasarimlar.md          # Figma tasarım dokümantasyonu
│   │   │
│   │   ├── database/                    # Veritabanı dokümantasyonu
│   │   │   ├── _index.md               # Database ana sayfa
│   │   │   └── sql/                    # SQL migration dosyaları
│   │   │       ├── _index.md           # SQL dosyaları listesi
│   │   │       ├── 1-create_database.sql
│   │   │       ├── 2-roller_ve_izinler_olustur.sql
│   │   │       ├── 3-usera_uuid_sutunu_ekle.sql
│   │   │       ├── 4-auth_ile_user_bağlama.sql
│   │   │       ├── 5-class_code_generator.sql
│   │   │       └── Remote_DB_Schema.sql
│   │   │
│   │   ├── technical/                   # Teknik dokümantasyon
│   │   │   └── 02_supabase_auth_integration.md
│   │   │
│   │   ├── guides/                      # Rehberler
│   │   │   └── implementation_guide.md
│   │   │
│   │   ├── reference/                   # Referans dokümantasyonu
│   │   │   ├── 01_rbac_security.md
│   │   │   ├── 06_changelog.md
│   │   │   ├── CHANGELOG_2025-10-14.md
│   │   │   └── CHANGELOG_SUMMARY_2025-10-14.md
│   │   │
│   │   └── api/                         # API dokümantasyonu
│   │       └── rest_api_guide_1.md
│   │
│   └── _index.md                        # Site ana sayfası
│
├── static/
│   └── images/
│       ├── schema.png                   # Database diyagramı
│       └── teacher_mobile_figma_design/ # Figma tasarım görselleri
│           ├── new/                     # Yeni ekranlar
│           ├── fix/                     # Düzeltilen ekranlar
│           └── end/                     # Tamamlanan ekranlar
│
├── themes/
│   └── hugo-book/                       # Hugo Book teması
│
├── hugo.toml                            # Hugo konfigürasyonu
├── .gitignore
└── README.md                            # Bu dosya
```

---

## ⚙️ Yapılandırma

`hugo.toml` dosyasını düzenleyerek site ayarlarını özelleştirebilirsiniz:

### Temel Ayarlar
- `title`: Site başlığı
- `baseURL`: Production URL
- `languageCode`: Dil kodu (tr)
- `theme`: Kullanılan tema (hugo-book)

### Tema Ayarları
- `BookTheme`: Renk teması (auto/light/dark)
- `BookToC`: İçindekiler tablosu
- `BookSearch`: Arama fonksiyonu
- `BookRepo`: GitHub repository linki
- `BookEditPath`: Düzenleme linki

---

## 🎨 Kullanılan Tema

Bu proje [Hugo Book](https://github.com/alex-shpak/hugo-book) temasını kullanmaktadır.

### Tema Özellikleri:
- 🌓 Açık/Koyu tema desteği
- 🔍 Yerleşik arama fonksiyonu
- 📱 Mobil uyumlu responsive tasarım
- ⚡ Hızlı sayfa yükleme
- 📝 Markdown ve shortcode desteği
- 🔗 Kolay navigasyon menüsü

---

## 📋 İçerik Kategorileri

### 🎯 Proje Dokümantasyonu
- Proje tanıtımı ve özellikleri
- Sistem mimarisi
- Roller ve yetkiler

### 🗄️ Veritabanı
- Multi-tenant PostgreSQL şeması
- 12 tablo ve ilişkiler
- SQL migration dosyaları
- Performans optimizasyonları

### 🔧 Kurulum ve Yapılandırma
- Supabase kurulum rehberi
- Auth entegrasyonu
- Storage yapılandırması
- API endpoint'leri

### 💻 Teknik Dokümantasyon
- Authentication sistemi
- Flutter implementasyonu
- Row Level Security (RLS) politikaları

### 📖 Geliştirme Rehberleri
- Feature implementasyon adımları
- Best practices
- Troubleshooting

### 🔒 Güvenlik ve Referans
- RBAC güvenlik sistemi
- 46 detaylı izin yapısı
- Changelog ve versiyon geçmişi

### 🌐 API Dokümantasyonu
- REST API kullanım rehberi
- Endpoint örnekleri
- Request/Response formatları

### 🎨 Tasarım
- Figma mobil uygulama tasarımları
- UI/UX ekranları (33 ekran)
- Tasarım güncellemeleri

---

## 🧱 Proje Teknolojileri

| Teknoloji | Kullanım Alanı |
|-----------|----------------|
| **Hugo** | Static site generator |
| **Hugo Book Theme** | Dokümantasyon teması |
| **Markdown** | İçerik formatı |
| **Git** | Versiyon kontrolü |
| **PostgreSQL (Supabase)** | Proje veritabanı |
| **Flutter** | Proje mobil uygulaması |

---

## 🤝 Katkıda Bulunma

1. **Fork** edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. **Pull Request** açın

### Katkı Kuralları
- Markdown formatına uyun
- Her sayfaya uygun front matter ekleyin
- Görselleri `static/images/` klasörüne ekleyin
- Değişikliklerinizi test edin (`hugo server -D`)

---

## 📜 Lisans

Bu proje Mehmet Ali GÜMÜŞLER tarafından hazırlanmıştır.  
Kişisel ve eğitimsel kullanım içindir.  
© 2025 Mehmet Ali GÜMÜŞLER

---

## 📞 İletişim ve Destek

- **GitHub Repository**: [Intronauts/intronauts-hugo-documentation](https://github.com/Intronauts/intronauts-hugo-documentation)
- **Proje**: Okula Bukula - AI Exam Evaluation System
- **Yazar**: Mehmet Ali GÜMÜŞLER
- **Versiyon**: v3.3 (Final Extended)
- **Tarih**: 14 Ekim 2025

---

## 🔄 Güncelleme Geçmişi

### v1.0.0 (14 Ekim 2025)
- ✅ Hugo Book teması entegrasyonu
- ✅ Veritabanı dokümantasyonu eklendi
- ✅ Supabase kurulum rehberi eklendi
- ✅ Supabase detaylı dokümantasyonu (Functions, Triggers, RLS Policies)
- ✅ Authentication sistemi dokümante edildi
- ✅ Implementation rehberleri eklendi
- ✅ RBAC güvenlik dokümantasyonu
- ✅ API dokümantasyonu
- ✅ Figma tasarım dokümantasyonu (33 ekran)
- ✅ Changelog ve versiyon geçmişi (yeni klasör yapısı)
- ✅ SQL migration dosyaları
- ✅ GitHub Pages deployment (GitHub Actions)

---

## 🏗️ Build Status

[![Deploy Status](https://github.com/Intronauts/intronauts-hugo-documentation/actions/workflows/deploy.yml/badge.svg)](https://github.com/Intronauts/intronauts-hugo-documentation/actions/workflows/deploy.yml)

---

**Happy Documenting! 🚀**
