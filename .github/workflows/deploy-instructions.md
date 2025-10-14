# 🚀 GitHub Pages Deployment Talimatları

## 📋 Adım Adım Kurulum

### 1. GitHub Repository Ayarları

1. GitHub'da repository sayfanıza gidin: `https://github.com/Intronauts/intronauts-hugo-documentation`

2. **Settings** > **Pages** bölümüne gidin

3. **Source** kısmında:
   - **Deploy from a branch** yerine
   - ✅ **GitHub Actions** seçin

4. Kaydedin

### 2. Kodu GitHub'a Push Edin

```bash
# Eğer henüz git repository'si değilse:
cd /home/sirket-ajani/Desktop/Samet-Workspace/intronauts-hugo-documentation
git init
git add .
git commit -m "Initial commit with GitHub Actions deployment"
git branch -M main
git remote add origin https://github.com/Intronauts/intronauts-hugo-documentation.git
git push -u origin main

# Eğer zaten git repository'siyse:
cd /home/sirket-ajani/Desktop/Samet-Workspace/intronauts-hugo-documentation
git add .
git commit -m "Add GitHub Pages deployment workflow"
git push
```

### 3. Deployment'ı İzleyin

1. GitHub repository'nizde **Actions** sekmesine gidin
2. "Deploy Hugo site to GitHub Pages" workflow'unu göreceksiniz
3. İlk çalıştırma otomatik başlayacak
4. Başarılı olunca siteniz yayında olacak!

### 4. Site URL'nizi Bulun

Siteniz şu adreste yayınlanacak:
```
https://intronauts.github.io/intronauts-hugo-documentation/
```

veya custom domain ayarladıysanız:
```
https://your-custom-domain.com
```

---

## 🔧 Özel Domain Eklemek (Opsiyonel)

### 1. DNS Ayarları

Domain sağlayıcınızda (örn: GoDaddy, Namecheap) aşağıdaki kayıtları ekleyin:

```
Type: A
Host: @
Value: 185.199.108.153

Type: A
Host: @
Value: 185.199.109.153

Type: A
Host: @
Value: 185.199.110.153

Type: A
Host: @
Value: 185.199.111.153

Type: CNAME
Host: www
Value: intronauts.github.io
```

### 2. GitHub Ayarları

1. **Settings** > **Pages**
2. **Custom domain** alanına domain'inizi girin: `docs.intronauts.com`
3. ✅ **Enforce HTTPS** seçeneğini aktif edin
4. Kaydedin

### 3. Hugo Config Güncelleme

`hugo.toml` dosyasını güncelleyin:

```toml
baseURL = 'https://docs.intronauts.com/'
```

---

## 📝 Workflow Nasıl Çalışır?

### Tetikleyiciler:
- ✅ `main` branch'e her push olduğunda otomatik çalışır
- ✅ Manuel olarak **Actions** sekmesinden çalıştırılabilir

### Build Süreci:
1. **Hugo CLI Kurulumu** (v0.151.0 Extended)
2. **Dart Sass Kurulumu**
3. **Repository Checkout** (submodule'ler dahil)
4. **Hugo Build** (production mode, minify, gc)
5. **Artifact Upload**
6. **GitHub Pages'e Deploy**

### Build Komutları:
```bash
hugo --gc --minify --baseURL "https://intronauts.github.io/intronauts-hugo-documentation/"
```

---

## 🔍 Sorun Giderme

### Build Hatası Alıyorsanız:

1. **Actions** sekmesinde hatalı workflow'u açın
2. Log'ları inceleyin
3. Yaygın hatalar:
   - Theme eksik → `git submodule update --init --recursive`
   - Hugo versiyonu uyumsuz → `HUGO_VERSION` değişkenini kontrol edin
   - Broken link → Hugo config'de `refLinksErrorLevel = "WARNING"` ekleyin

### Submodule Güncellemesi:

```bash
git submodule update --remote --merge
git add themes/
git commit -m "Update theme submodule"
git push
```

### Cache Temizleme:

GitHub Actions cache'ini temizlemek için:
1. **Actions** > **Caches** > İlgili cache'i silin
2. Workflow'u tekrar çalıştırın

---

## ⚡ Hızlı Güncelleme Akışı

Dokümantasyonu güncellemek için:

```bash
# 1. Değişiklik yapın
cd /home/sirket-ajani/Desktop/Samet-Workspace/intronauts-hugo-documentation
# ... dosyaları düzenleyin ...

# 2. Local'de test edin
hugo server -D

# 3. Git'e commit edin
git add .
git commit -m "Update documentation: [açıklama]"
git push

# 4. GitHub Actions otomatik deploy edecek (1-2 dakika)
# 5. https://intronauts.github.io/intronauts-hugo-documentation/ adresinde görün
```

---

## 🎯 Deployment Durumu Badge'i (Opsiyonel)

README.md'ye ekleyin:

```markdown
[![Deploy Status](https://github.com/Intronauts/intronauts-hugo-documentation/actions/workflows/deploy.yml/badge.svg)](https://github.com/Intronauts/intronauts-hugo-documentation/actions/workflows/deploy.yml)
```

---

## 📊 Build Süreleri

Ortalama build süresi: **1-2 dakika**

- Hugo build: ~10-20 saniye
- Upload + Deploy: ~30-60 saniye

---

## 🔒 Güvenlik

- ✅ Sadece `main` branch'den deployment
- ✅ GitHub Actions secrets kullanılabilir
- ✅ HTTPS zorunlu (GitHub Pages otomatik)
- ✅ Environment protection rules ayarlanabilir

---

## 📞 Destek

Sorun yaşarsanız:
- GitHub Issues: https://github.com/Intronauts/intronauts-hugo-documentation/issues
- Hugo Docs: https://gohugo.io/hosting-and-deployment/hosting-on-github/

---

**Hazırladı:** GitHub Copilot  
**Tarih:** 14 Ekim 2025  
**Versiyon:** 1.0
