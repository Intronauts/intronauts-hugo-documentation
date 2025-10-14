---
title: "Kurulum"
weight: 2
bookFlatSection: false
---

# Kurulum Rehberi

Bu sayfada projenin nasıl kurulacağını öğrenebilirsiniz.

## Gereksinimler

- Hugo Extended (v0.150.0 veya üzeri)
- Git

## Adım 1: Hugo Kurulumu

### Linux

```bash
sudo snap install hugo
```

### MacOS

```bash
brew install hugo
```

### Windows

```bash
choco install hugo-extended
```

## Adım 2: Projeyi Klonlama

```bash
git clone https://github.com/Intronauts/intronauts-hugo-documentation.git
cd intronauts-hugo-documentation
```

## Adım 3: Tema Kurulumu

```bash
git submodule update --init --recursive
```

## Adım 4: Geliştirme Sunucusunu Başlatma

```bash
hugo server -D
```

Tarayıcınızda `http://localhost:1313` adresine giderek sitenizi görüntüleyebilirsiniz.

## Adım 5: Üretim Build'i

```bash
hugo
```

Bu komut `public/` klasöründe statik dosyalarınızı oluşturacaktır.
