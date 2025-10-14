# Intronauts Hugo Dokümantasyon

Bu proje Hugo kullanılarak oluşturulmuş bir dokümantasyon sitesidir.

## Gereksinimler

- Hugo Extended (v0.150.0+)
- Git

## Kurulum

1. Repository'yi klonlayın:
```bash
git clone https://github.com/Intronauts/intronauts-hugo-documentation.git
cd intronauts-hugo-documentation
```

2. Tema bağımlılıklarını indirin:
```bash
git submodule update --init --recursive
```

3. Geliştirme sunucusunu başlatın:
```bash
hugo server -D
```

4. Tarayıcınızda açın: http://localhost:1313

## Üretim Build'i

```bash
hugo
```

Build dosyaları `public/` klasöründe oluşturulacaktır.

## Yeni İçerik Ekleme

Yeni bir dokümantasyon sayfası oluşturmak için:

```bash
hugo new content docs/sayfa-adi.md
```

## Klasör Yapısı

```
.
├── archetypes/       # İçerik şablonları
├── content/          # Markdown içerik dosyaları
│   └── docs/         # Dokümantasyon sayfaları
├── static/           # Statik dosyalar (resimler, CSS, JS)
├── themes/           # Hugo temaları
│   └── hugo-book/    # Hugo Book teması
├── hugo.toml         # Ana konfigürasyon dosyası
└── README.md
```

## Yapılandırma

`hugo.toml` dosyasını düzenleyerek site ayarlarını özelleştirebilirsiniz:

- Site başlığı
- Base URL
- Tema renk şeması
- Arama fonksiyonu
- Git entegrasyonu
- Ve daha fazlası...

## Kullanılan Tema

Bu proje [Hugo Book](https://github.com/alex-shpak/hugo-book) temasını kullanmaktadır.

## Lisans

MIT

## Katkıda Bulunma

Pull request'ler memnuniyetle karşılanır. Büyük değişiklikler için lütfen önce bir issue açarak neyi değiştirmek istediğinizi tartışın.
