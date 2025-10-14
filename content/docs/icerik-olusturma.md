---
title: "İçerik Oluşturma"
weight: 3
---

# İçerik Oluşturma

Hugo'da içerik oluşturmak oldukça kolaydır. İşte bilmeniz gerekenler:

## Yeni Sayfa Oluşturma

Yeni bir dokümantasyon sayfası oluşturmak için:

```bash
hugo new content docs/sayfa-adi.md
```

## Front Matter

Her markdown dosyasının başında front matter bulunmalıdır:

```yaml
---
title: "Sayfa Başlığı"
weight: 10
bookFlatSection: false
bookCollapseSection: false
bookToc: true
---
```

### Front Matter Parametreleri

- `title`: Sayfanın başlığı
- `weight`: Menüdeki sıralama (düşük sayılar önce gelir)
- `bookFlatSection`: Alt bölümleri düz liste olarak gösterir
- `bookCollapseSection`: Bölümü varsayılan olarak kapalı gösterir
- `bookToc`: Sağ tarafta içindekiler tablosunu gösterir/gizler

## Markdown Kullanımı

### Başlıklar

```markdown
# H1 Başlık
## H2 Başlık
### H3 Başlık
```

### Listeler

```markdown
- Liste öğesi 1
- Liste öğesi 2
  - Alt liste öğesi
```

### Kod Blokları

````markdown
```python
def merhaba():
    print("Merhaba Dünya!")
```
````

### Linkler

```markdown
[Link metni](https://example.com)
[İç sayfa linki](/docs/kurulum/)
```

### Resimler

```markdown
![Açıklama](/images/resim.png)
```

### Tablolar

```markdown
| Başlık 1 | Başlık 2 |
|----------|----------|
| Hücre 1  | Hücre 2  |
| Hücre 3  | Hücre 4  |
```

## Hugo Shortcode'lar

Hugo Book teması birçok özel shortcode sunar:

### Uyarı Kutuları

```markdown
{{</* hint info */>}}
Bu bir bilgi kutusudur.
{{</* /hint */>}}

{{</* hint warning */>}}
Bu bir uyarı kutusudur.
{{</* /hint */>}}

{{</* hint danger */>}}
Bu bir tehlike kutusudur.
{{</* /hint */>}}
```

### Sekmeler

```markdown
{{</* tabs "benzersiz-id" */>}}
{{</* tab "Tab 1" */>}}
Tab 1 içeriği
{{</* /tab */>}}
{{</* tab "Tab 2" */>}}
Tab 2 içeriği
{{</* /tab */>}}
{{</* /tabs */>}}
```

### Genişletilebilir Bölümler

```markdown
{{</* expand "Buraya tıklayın" */>}}
Gizli içerik burada
{{</* /expand */>}}
```

## İpuçları

- Dosya ve klasör isimlerinde Türkçe karakter kullanmaktan kaçının
- URL'lerde küçük harf kullanın ve boşlukları tire (-) ile değiştirin
- Her bölümde bir `_index.md` dosyası bulundurun
- Görselleri `static/images/` klasörüne yerleştirin
