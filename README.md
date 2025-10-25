# Okula Bukula - Hugo Dokümantasyon

**Yapay Zekâ Destekli Sınav Değerlendirme Platformu - Teknik Dokümantasyon**

Bu proje, Okula Bukula sisteminin tüm teknik dokümantasyonunu içeren Hugo tabanlı bir dokümantasyon sitesidir.

---

## İçerik

Bu dokümantasyon şunları kapsar:

- **Veritabanı Tasarımı**: Multi-tenant PostgreSQL şeması (12 tablo)
- **Supabase Kurulumu**: Adım adım kurulum rehberi
- **Authentication Sistemi**: Supabase Auth entegrasyonu
- **Implementation Rehberleri**: Özellik geliştirme kılavuzları
- **RBAC Güvenlik**: Rol bazlı erişim kontrolü (46 izin)
- **API Dokümantasyonu**: REST API endpoint'leri
- **Figma Tasarımları**: Mobil uygulama UI/UX ekranları
- **Changelog**: Versiyon geçmişi ve güncellemeler

---

## Hızlı Başlangıç

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

## GitHub Pages Deployment

Bu proje GitHub Actions ile otomatik olarak GitHub Pages'e deploy edilir.

### Canlı Site
**URL:** https://intronauts.github.io/intronauts-hugo-documentation/

### Otomatik Deployment
- Her `main` branch'e push edildiğinde otomatik olarak build ve deploy edilir
- GitHub Actions workflow: `.github/workflows/deploy.yml`



## Yeni İçerik Ekleme

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
│   │   ├── supabase/                    # Supabase kurulum ve konfigürasyon
│   │   │   └── _index.md               # Supabase ana sayfa
│   │   │
│   │   ├── technical/                   # Teknik dokümantasyon
│   │   │   └── 02_supabase_auth_integration.md
│   │   │
│   │   ├── guides/                      # Geliştirme Rehberleri
│   │   │   ├── _index.md               # Rehberler ana sayfa
│   │   │   ├── Dosya-Rehberi.md        # Dosya yapısı rehberi
│   │   │   ├── implementation_guide.md  # Implementation rehberi
│   │   │   └── rest_api_guide_1.md     # REST API rehberi
│   │   │
│   │   ├── reference/                   # Referans dokümantasyonu
│   │   │   └── 01_rbac_security.md     # RBAC güvenlik sistemi
│   │   │
│   │   └── changelog/                   # Değişiklik kayıtları
│   │       ├── _index.md               # Changelog ana sayfa
│   │       ├── ozet.md                 # Değişiklik özeti
│   │       ├── gecmis.md               # Geçmiş değişiklikler
│   │       ├── 12-10-2025.md           # 12 Ekim 2025 güncellemeleri
│   │       ├── 14-10-2025.md           # 14 Ekim 2025 güncellemeleri
│   │       ├── 17-10-2025.md           # 17 Ekim 2025 güncellemeleri
│   │       └── 19-10-2025.md           # 19 Ekim 2025 güncellemeleri
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

## Yapılandırma

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

## Kullanılan Tema

Bu proje [Hugo Book](https://github.com/alex-shpak/hugo-book) temasını kullanmaktadır.

### Tema Özellikleri:
- Açık/Koyu tema desteği
- Yerleşik arama fonksiyonu
- Mobil uyumlu responsive tasarım
- Hızlı sayfa yükleme
- Markdown ve shortcode desteği
- Kolay navigasyon menüsü

---

## İçerik Kategorileri

### Proje Dokümantasyonu
- Proje tanıtımı ve özellikleri
- Sistem mimarisi
- Roller ve yetkiler

### Veritabanı
- Multi-tenant PostgreSQL şeması
- 12 tablo ve ilişkiler
- SQL migration dosyaları
- Performans optimizasyonları

### Kurulum ve Yapılandırma
- Supabase kurulum rehberi
- Auth entegrasyonu
- Storage yapılandırması
- API endpoint'leri

### Teknik Dokümantasyon
- Authentication sistemi
- Flutter implementasyonu
- Row Level Security (RLS) politikaları

### Geliştirme Rehberleri
- Feature implementasyon adımları
- Best practices
- Troubleshooting

### Güvenlik ve Referans
- RBAC güvenlik sistemi
- 46 detaylı izin yapısı
- Changelog ve versiyon geçmişi

### API Dokümantasyonu
- REST API kullanım rehberi
- Endpoint örnekleri
- Request/Response formatları

### Tasarım
- Figma mobil uygulama tasarımları
- UI/UX ekranları (33 ekran)
- Tasarım güncellemeleri

---

