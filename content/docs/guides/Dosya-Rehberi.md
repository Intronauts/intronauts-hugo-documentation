---
title: "Dosya Rehberi - lib/ Yapısı"
weight: 25
---

# lib/ Klasör Yapısı ve Dosya Rehberi

Bu doküman, projedeki tüm lib/ klasörü ve alt klasörlerdeki .dart dosyalarının işlevlerini açıklar.

---

## lib/

### `main.dart`
Uygulamanın başlangıç noktası. Supabase bağlantısı, tema ayarları ve routing yapılandırması burada yapılır.

---

## lib/common/

Tüm kullanıcı tipleri (öğrenci, öğretmen, admin) tarafından paylaşılan ortak kodlar.

### common/config/

#### `env.dart`
Çevre değişkenleri (Supabase URL, API anahtarları) burada tanımlanır.

---

### common/core/

Uygulamanın temel yapı taşları ve ayarlar.

#### core/constants/

##### `app_colors.dart`
Uygulamada kullanılan tüm renk sabitleri (primary, secondary, background vb.).

##### `app_dimensions.dart`
Padding, margin, border radius gibi boyut sabitleri.

##### `app_strings.dart`
Uygulamada kullanılan statik metin sabitleri ve etiketler.

#### core/providers/

##### `theme_provider.dart`
Dark/Light tema yönetimi için Provider sınıfı.

#### core/theme/

##### `app_theme.dart`
Material Design tema konfigürasyonları (ThemeData).

---

### common/mock/

Test ve geliştirme için sahte veriler.

#### `exam_mock_data.dart`
Sınav verileri için örnek mock data.

---

### common/models/

Veri modelleri ve DTO'lar.

#### `class_member_model.dart`
Sınıf üyeliği (öğrenci-sınıf ilişkisi) veri modeli.

#### `class_model.dart`
Sınıf bilgilerini temsil eden model (id, name, code, academic_year vb.).

#### `exam_model.dart`
Sınav bilgilerini temsil eden model (id, title, date, type, status vb.).

#### `performance_model.dart`
Öğrenci/sınıf performans verilerini temsil eden model.

#### `user_type.dart`
Kullanıcı tiplerini temsil eden enum (Student, Teacher, Admin).

#### models/api/

##### `api_response.dart`
API çağrılarının standart response wrapper'ı (success, data, error).

---

### common/pages/

Ortak kullanılan ekranlar.

#### `app_splash_screen.dart`
Uygulama başlangıcında gösterilen basit splash screen.

#### `dashboard_screen.dart`
Kullanıcı rolüne göre doğru dashboard'a yönlendiren wrapper screen.

#### `exam_detail_screen.dart`
Sınav detay bilgilerini gösteren ekran.

#### `login_screen.dart`
Kullanıcı giriş ekranı (email/password).

#### `profile_screen.dart`
Kullanıcı rolüne göre profile sayfasına yönlendiren wrapper.

#### `register_screen.dart`
Yeni kullanıcı kayıt ekranı (öğrenci/öğretmen seçimi ile).

#### `splash_screen.dart`
Animasyonlu splash screen, session kontrolü yapar.

---

### common/painters/

Custom paint widget'ları.

#### `shield_logo_painter.dart`
Uygulamanın kalkan logosunu çizen CustomPainter.

#### `star_field_painter.dart`
Arka plan için yıldız efekti çizen CustomPainter.

---

### common/services/

İş mantığı ve API çağrıları.

#### `auth_service.dart`
Kullanıcı authentication işlemleri (login, register, logout, password reset).

#### `class_member_service.dart`
Sınıf üyeliği işlemleri (join class, leave class, get students, get classes).

#### `class_service.dart`
Sınıf CRUD işlemleri (create, read, update, delete).

#### `permission_service.dart`
Kullanıcı yetkilendirme kontrolü (can create class, can edit class vb.).

#### `school_service.dart`
Okul bilgilerini getiren servis.

#### `session_manager.dart`
Kullanıcı oturum yönetimi (current user, role check vb.).

#### services/api/

##### `base_api_service.dart`
Tüm API çağrıları için base servis, error handling ve logging içerir.

##### `class_api.dart`
Sınıf ile ilgili API endpoint'lerini yöneten servis.

#### services/repositories/

##### `class_repository.dart`
Sınıf veri erişim katmanı, API ve local cache arasında köprü.

---

### common/widgets/

Tekrar kullanılabilir UI bileşenleri.

#### `class_card.dart`
Sınıf bilgilerini gösteren kart widget'ı.

#### `custom_input_field.dart`
Özelleştirilmiş text input field.

#### `date_input_field.dart`
Tarih seçimi için özel input field.

#### `exam_card_widget.dart`
Sınav bilgilerini gösteren kart widget'ı.

#### `exam_list_item.dart`
Sınav listesinde kullanılan item widget'ı.

#### `main_layout.dart`
Ana layout wrapper, bottom navigation bar içerir.

#### `performance_card.dart`
Performans istatistiklerini gösteren kart widget'ı.

#### `phone_input_field.dart`
Telefon numarası için özel input field.

#### `primary_button.dart`
Uygulamanın ana buton stili.

#### `school_dropdown_field.dart`
Okul seçimi için dropdown widget'ı.

#### `user_type_selector.dart`
Kullanıcı tipi seçimi için custom widget (öğrenci/öğretmen).

---

## lib/student/

Öğrenci rolüne özel sayfalar ve widget'lar.

### student/pages/

#### `join_class_dialog.dart`
Sınıf koduna göre sınıfa katılma dialog'u.

#### `student_class_detail_screen.dart`
Öğrencinin katıldığı sınıfın detay ekranı.

#### `student_class_list_screen.dart`
Öğrencinin katıldığı sınıfların liste ekranı.

#### `student_dashboard_screen.dart`
Öğrenci ana sayfa ekranı (dashboard).

#### `student_exams_screen.dart`
Öğrencinin sınavlarını listeleyen ekran.

#### `student_profile_screen.dart`
Öğrenci profil sayfası.

---

### student/widgets/

#### `student_navigation_bar.dart`
Öğrenci için özel bottom navigation bar widget'ı.

---

## lib/teacher/

Öğretmen rolüne özel sayfalar ve widget'lar.

### teacher/pages/

Öğretmen ekranları, 4 ana kategoriye ayrılmış.

#### pages/class/

Sınıf yönetimi ile ilgili ekranlar.

##### `class_list_screen.dart`
Öğretmenin sınıflarını listeleyen ekran.

##### `create_class_screen.dart`
Yeni sınıf oluşturma ekranı.

##### `teacher_class_detail_screen.dart`
Sınıf detay ekranı (öğrenciler, sınavlar, performans tab'ları ile).

##### class_detail/dialogs/

###### `edit_class_dialog.dart`
Sınıf bilgilerini düzenleme ve silme dialog'u.

###### `show_code_dialog.dart`
Sınıf kodunu gösterme dialog'u.

###### `student_detail_dialog.dart`
Öğrenci detay bilgilerini gösteren dialog.

##### class_detail/widgets/

###### `class_detail_header.dart`
Sınıf detay ekranının üst header widget'ı.

###### `class_detail_tab_bar.dart`
Sınıf detay ekranının tab bar widget'ı (Öğrenciler, Sınavlar, Performans).

###### `exams_tab_view.dart`
Sınıf detayında sınavlar tab'ının içeriği.

###### `performance_tab_view.dart`
Sınıf detayında performans tab'ının içeriği.

###### `students_tab_view.dart`
Sınıf detayında öğrenciler tab'ının içeriği (öğrenci listesi).

---

#### pages/exams/

Sınav yönetimi ile ilgili ekranlar.

##### `exams_screen.dart`
Öğretmenin tüm sınavlarını listeleyen ana ekran.

##### `create_exam_screen.dart`
Yeni sınav oluşturma ekranı (manuel soru girişi).

##### `exam_read_ocr_screen.dart`
OCR ile optik form okuma ekranı (sınav kağıdı tarama).

##### `exam_paper_viewer.dart`
Öğrenci sınav kağıdını görüntüleme ekranı.

##### `student_exam_view.dart`
Öğrenci bazında sınav sonuçlarını görüntüleme ekranı.

##### `score_store.dart`
Öğrenci notlarını geçici olarak tutmak için in-memory store (ChangeNotifier).

---

#### pages/home/

Ana sayfa ile ilgili ekranlar.

##### `teacher_dashboard_screen.dart`
Öğretmen ana sayfa ekranı (sınıflar, son sınavlar, istatistikler).

##### `ai_assistant_screen.dart`
AI asistan ekranı (yapay zeka destekli özellikler).

---

#### pages/profile/

Profil ile ilgili ekranlar.

##### `teacher_profile_screen.dart`
Öğretmen profil sayfası (bilgiler, ayarlar, tema değiştirme).

---

### teacher/widgets/

Öğretmen için özel widget'lar (şu anda boş, gelecekte eklenebilir).

---

## Klasör İstatistikleri

- **Toplam Klasör:** 20
- **Toplam .dart Dosyası:** 65+
- **Ana Kategoriler:** 3 (common, student, teacher)
- **Teacher Alt Kategorisi:** 4 (class, exams, home, profile)

---

## Dosya Organizasyon Prensipleri

1. **common/**: Tüm roller için ortak kod
2. **student/**: Sadece öğrenci için kod
3. **teacher/**: Sadece öğretmen için kod
4. **Klasör yapısı**, navigasyon menüsü yapısını takip eder
5. **Her ekran**, kendi alt widget'larını kendi klasöründe tutar
6. **Servisler**, iş mantığını UI'dan ayırır
7. **Models**, veri yapısını tanımlar
8. **Widgets**, tekrar kullanılabilir UI bileşenleri içerir

---

## Dosya İsimlendirme Kuralları

- **Ekranlar**: `*_screen.dart` (örn: `login_screen.dart`)
- **Widget'lar**: `*_widget.dart` veya özel isim (örn: `class_card.dart`)
- **Servisler**: `*_service.dart` (örn: `auth_service.dart`)
- **Modeller**: `*_model.dart` (örn: `class_model.dart`)
- **Dialog'lar**: `*_dialog.dart` (örn: `edit_class_dialog.dart`)
- **Provider'lar**: `*_provider.dart` (örn: `theme_provider.dart`)
- **Repository'ler**: `*_repository.dart` (örn: `class_repository.dart`)
- **API'ler**: `*_api.dart` (örn: `class_api.dart`)

---

## Mimari Akış

```
UI Layer (Screens/Widgets)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
API Layer (Network Calls)
    ↓
Supabase (Backend)
```

---

## Hızlı Referans

- **Yeni ekran eklemek için**: İlgili role ve kategoriye uygun klasöre `*_screen.dart` ekle
- **Yeni API çağrısı için**: `services/` altına uygun servisi güncelle
- **Yeni widget için**: `common/widgets/` veya role özel widgets klasörüne ekle
- **Yeni model için**: `common/models/` altına `*_model.dart` ekle
Kullanıcı giriş ekranı (email/password).

#### `profile_screen.dart`
Kullanıcı rolüne göre profile sayfasına yönlendiren wrapper.

#### `register_screen.dart`
Yeni kullanıcı kayıt ekranı (öğrenci/öğretmen seçimi ile).

#### `splash_screen.dart`
Animasyonlu splash screen, session kontrolü yapar.

---

### 📁 common/painters/

Custom paint widget'ları.

#### `shield_logo_painter.dart`
Uygulamanın kalkan logosunu çizen CustomPainter.

#### `star_field_painter.dart`
Arka plan için yıldız efekti çizen CustomPainter.

---

### 📁 common/services/

İş mantığı ve API çağrıları.

#### `auth_service.dart`
Kullanıcı authentication işlemleri (login, register, logout, password reset).

#### `class_member_service.dart`
Sınıf üyeliği işlemleri (join class, leave class, get students, get classes).

#### `class_service.dart`
Sınıf CRUD işlemleri (create, read, update, delete).

#### `permission_service.dart`
Kullanıcı yetkilendirme kontrolü (can create class, can edit class vb.).

#### `school_service.dart`
Okul bilgilerini getiren servis.

#### `session_manager.dart`
Kullanıcı oturum yönetimi (current user, role check vb.).

#### 📁 services/api/

##### `base_api_service.dart`
Tüm API çağrıları için base servis, error handling ve logging içerir.

##### `class_api.dart`
Sınıf ile ilgili API endpoint'lerini yöneten servis.

#### 📁 services/repositories/

##### `class_repository.dart`
Sınıf veri erişim katmanı, API ve local cache arasında köprü.

---

### 📁 common/widgets/

Tekrar kullanılabilir UI bileşenleri.

#### `class_card.dart`
Sınıf bilgilerini gösteren kart widget'ı.

#### `custom_input_field.dart`
Özelleştirilmiş text input field.

#### `date_input_field.dart`
Tarih seçimi için özel input field.

#### `exam_card_widget.dart`
Sınav bilgilerini gösteren kart widget'ı.

#### `exam_list_item.dart`
Sınav listesinde kullanılan item widget'ı.

#### `main_layout.dart`
Ana layout wrapper, bottom navigation bar içerir.

#### `performance_card.dart`
Performans istatistiklerini gösteren kart widget'ı.

#### `phone_input_field.dart`
Telefon numarası için özel input field.

#### `primary_button.dart`
Uygulamanın ana buton stili.

#### `school_dropdown_field.dart`
Okul seçimi için dropdown widget'ı.

#### `user_type_selector.dart`
Kullanıcı tipi seçimi için custom widget (öğrenci/öğretmen).

---

## 📁 lib/student/

Öğrenci rolüne özel sayfalar ve widget'lar.

### 📁 student/pages/

#### `join_class_dialog.dart`
Sınıf koduna göre sınıfa katılma dialog'u.

#### `student_class_detail_screen.dart`
Öğrencinin katıldığı sınıfın detay ekranı.

#### `student_class_list_screen.dart`
Öğrencinin katıldığı sınıfların liste ekranı.

#### `student_dashboard_screen.dart`
Öğrenci ana sayfa ekranı (dashboard).

#### `student_exams_screen.dart`
Öğrencinin sınavlarını listeleyen ekran.

#### `student_profile_screen.dart`
Öğrenci profil sayfası.

---

### 📁 student/widgets/

#### `student_navigation_bar.dart`
Öğrenci için özel bottom navigation bar widget'ı.

---

## 📁 lib/teacher/

Öğretmen rolüne özel sayfalar ve widget'lar.

### 📁 teacher/pages/

Öğretmen ekranları, 4 ana kategoriye ayrılmış.

#### 📁 pages/class/

Sınıf yönetimi ile ilgili ekranlar.

##### `class_list_screen.dart`
Öğretmenin sınıflarını listeleyen ekran.

##### `create_class_screen.dart`
Yeni sınıf oluşturma ekranı.

##### `teacher_class_detail_screen.dart`
Sınıf detay ekranı (öğrenciler, sınavlar, performans tab'ları ile).

##### 📁 class_detail/dialogs/

###### `edit_class_dialog.dart`
Sınıf bilgilerini düzenleme ve silme dialog'u.

###### `show_code_dialog.dart`
Sınıf kodunu gösterme dialog'u.

###### `student_detail_dialog.dart`
Öğrenci detay bilgilerini gösteren dialog.

##### 📁 class_detail/widgets/

###### `class_detail_header.dart`
Sınıf detay ekranının üst header widget'ı.

###### `class_detail_tab_bar.dart`
Sınıf detay ekranının tab bar widget'ı (Öğrenciler, Sınavlar, Performans).

###### `exams_tab_view.dart`
Sınıf detayında sınavlar tab'ının içeriği.

###### `performance_tab_view.dart`
Sınıf detayında performans tab'ının içeriği.

###### `students_tab_view.dart`
Sınıf detayında öğrenciler tab'ının içeriği (öğrenci listesi).

---

#### 📁 pages/exams/

Sınav yönetimi ile ilgili ekranlar.

##### `exams_screen.dart`
Öğretmenin tüm sınavlarını listeleyen ana ekran.

##### `create_exam_screen.dart`
Yeni sınav oluşturma ekranı (manuel soru girişi).

##### `exam_read_ocr_screen.dart`
OCR ile optik form okuma ekranı (sınav kağıdı tarama).

##### `exam_paper_viewer.dart`
Öğrenci sınav kağıdını görüntüleme ekranı.

##### `student_exam_view.dart`
Öğrenci bazında sınav sonuçlarını görüntüleme ekranı.

##### `score_store.dart`
Öğrenci notlarını geçici olarak tutmak için in-memory store (ChangeNotifier).

---

#### 📁 pages/home/

Ana sayfa ile ilgili ekranlar.

##### `teacher_dashboard_screen.dart`
Öğretmen ana sayfa ekranı (sınıflar, son sınavlar, istatistikler).

##### `ai_assistant_screen.dart`
AI asistan ekranı (yapay zeka destekli özellikler).

---

#### 📁 pages/profile/

Profil ile ilgili ekranlar.

##### `teacher_profile_screen.dart`
Öğretmen profil sayfası (bilgiler, ayarlar, tema değiştirme).

---

### 📁 teacher/widgets/

Öğretmen için özel widget'lar (şu anda boş, gelecekte eklenebilir).

---

## 📊 Klasör İstatistikleri

- **Toplam Klasör:** 20
- **Toplam .dart Dosyası:** 65+
- **Ana Kategoriler:** 3 (common, student, teacher)
- **Teacher Alt Kategorisi:** 4 (class, exams, home, profile)

---

## 🎯 Dosya Organizasyon Prensipleri

1. **common/**: Tüm roller için ortak kod
2. **student/**: Sadece öğrenci için kod
3. **teacher/**: Sadece öğretmen için kod
4. **Klasör yapısı**, navigasyon menüsü yapısını takip eder
5. **Her ekran**, kendi alt widget'larını kendi klasöründe tutar
6. **Servisler**, iş mantığını UI'dan ayırır
7. **Models**, veri yapısını tanımlar
8. **Widgets**, tekrar kullanılabilir UI bileşenleri içerir

---

## 📝 Dosya İsimlendirme Kuralları

- **Ekranlar**: `*_screen.dart` (örn: `login_screen.dart`)
- **Widget'lar**: `*_widget.dart` veya özel isim (örn: `class_card.dart`)
- **Servisler**: `*_service.dart` (örn: `auth_service.dart`)
- **Modeller**: `*_model.dart` (örn: `class_model.dart`)
- **Dialog'lar**: `*_dialog.dart` (örn: `edit_class_dialog.dart`)
- **Provider'lar**: `*_provider.dart` (örn: `theme_provider.dart`)
- **Repository'ler**: `*_repository.dart` (örn: `class_repository.dart`)
- **API'ler**: `*_api.dart` (örn: `class_api.dart`)

---

## 🔄 Mimari Akış

```
UI Layer (Screens/Widgets)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
API Layer (Network Calls)
    ↓
Supabase (Backend)
```

---

## ⚡ Hızlı Referans

- **Yeni ekran eklemek için**: İlgili role ve kategoriye uygun klasöre `*_screen.dart` ekle
- **Yeni API çağrısı için**: `services/` altına uygun servisi güncelle
- **Yeni widget için**: `common/widgets/` veya role özel widgets klasörüne ekle
- **Yeni model için**: `common/models/` altına `*_model.dart` ekle

