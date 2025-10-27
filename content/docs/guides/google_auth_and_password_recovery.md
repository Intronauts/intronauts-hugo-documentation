---
title: "Google Auth & Şifre Sıfırlama Rehberi"
weight: 24
---

# Supabase Auth + Flutter (Google ile Giriş & Şifre Sıfırlama) — Entegrasyon Rehberi

Bu rehber, **Flutter mobil uygulaması** için **Supabase Auth** kullanarak:

* **Google ile giriş** (OAuth)

* **Şifre sıfırlama** (password recovery)
  akışlarını **derin bağlantı (deep link)** ile uçtan uca anlatır.
  Aşağıdaki örnekler, senin projen için uyarlanmıştır:

* **Project URL**: `https://fajdjdlecqokklpdgnfl.supabase.co`

* **Redirect Deep Links **:

  * Google Login Callback: `intronauts://login-callback`
  * Password Reset Callback: `intronauts://reset-password`

> **Not:** Anahtar/şifre gibi gizli değerleri paylaşmayın; örneklerde `YOUR_SUPABASE_ANON_KEY` şeklinde yer tutucular kullanılmıştır.

---

## 0) Özet Akışlar

### Google ile Giriş (Mobil)

1. Flutter: `signInWithOAuth(Provider.google, redirectTo: 'intronauts://login-callback')`
2. Tarayıcı → Google hesabı seçimi
3. Supabase callback → `intronauts://login-callback?access_token=...&refresh_token=...`
4. Flutter deep link’i yakalar → token’ı **session** olarak set eder → kullanıcıyı uygulama içinde oturum açar.

### Şifre Sıfırlama (Mobil)

1. Flutter/Postman: `POST /auth/v1/recover?redirect_to=intronauts://reset-password` (body: email)
2. Kullanıcıya e-posta gelir (SMTP/Resend ile)
3. Kullanıcı maildeki linke tıklar → `intronauts://reset-password?access_token=...&type=recovery`
4. Flutter deep link’i yakalar → kullanıcı yeni şifreyi girer → `auth.updateUser({ password })`

---

## 1) Supabase & Google & SMTP Ön Hazırlık (Yapildi)

### Supabase → Auth Ayarları

* **Authentication → Providers → Google**

  * **Enable**: açık
  * **Client ID / Secret**: Google Cloud’dan aldığın **Web application** kimlik bilgileri
  * **Callback URL** (Supabase tarafı sabit):
    `https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/callback`
* **Authentication → URL Configuration → Redirect URLs**

  * Aşağıdaki **deep link** adreslerini **Add URL** ile ekle:

    * `intronauts://login-callback`
    * `intronauts://reset-password`
* **Authentication → Settings → Email (SMTP)**

  * **Custom SMTP**: **ON**
  * Örn. **Resend SMTP**:

    * Host: `smtp.resend.com`
    * Port: `587`
    * Username: `resend`
    * Password: **Resend SMTP Key**
    * Sender email: `noreply@intronauts.online` (domain **verified** olmalı)

### Google Cloud (OAuth Client — Web)

* **Application type**: **Web application**
* **Authorized redirect URIs**:

  * `https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/callback`
* Çıkan **Client ID** ve **Client Secret**’ı Supabase Google provider ekranına gir.

### Resend (SMTP) — Deliverability

* **Domains**: Domainini ekle → **Verified** olmalı (SPF/DKIM/Return-Path).
* **Click Tracking** kapatmanı öneririz (transactional e-posta için).

> 🔐 **Kritik Bilgiler:** Resend API Key, SMTP şifresi ve domain yapılandırması için [güvenli dosyaya erişin](https://file.sametanaz.space/files/Active-Directory/Private/resend.txt)

---

## 2) Deep Link (Mobil) Kurulumu (Yapilacak)

**Scheme** olarak `intronauts` kullandığımızı varsayıyoruz.

### Android — `AndroidManifest.xml`

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity ... >
  <!-- ... -->
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="intronauts" android:host="login-callback" />
  </intent-filter>

  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="intronauts" android:host="reset-password" />
  </intent-filter>
</activity>
```

### iOS — `Info.plist`

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>intronauts</string>
    </array>
  </dict>
</array>
```

### Flutter — Deep Link Dinleme

`pubspec.yaml`:

```yaml
dependencies:
  uni_links: ^0.5.1
  supabase_flutter: ^2.6.0 # (uygun en güncel sürümü kullan)
```

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    _sub = linkStream.listen((String? link) async {
      if (link == null) return;
      final uri = Uri.parse(link);

      // Google Login Callback
      if (uri.host == 'login-callback' && uri.queryParameters['access_token'] != null) {
        final accessToken = uri.queryParameters['access_token']!;
        final refreshToken = uri.queryParameters['refresh_token'] ?? '';

        await Supabase.instance.client.auth.setSession(
          RefreshTokenSession(accessToken: accessToken, refreshToken: refreshToken),
        );

        // Kullanıcıyı uygulama ana ekranına al
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      // Password Recovery Callback
      if (uri.host == 'reset-password' && uri.queryParameters['access_token'] != null) {
        final recoveryToken = uri.queryParameters['access_token']!;
        // Token’ı session olarak set et (gerekirse)
        await Supabase.instance.client.auth.setSession(
          RecoveryTokenSession(accessToken: recoveryToken),
        );
        if (mounted) Navigator.pushNamed(context, '/set-new-password', arguments: recoveryToken);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

> **Not:** Supabase bazen `#fragment` yerine query param döndürebilir. `uni_links` ile gelen string’i `Uri.parse` üzerinde `queryParameters` ile okuyorsun — bu mobil deep link’te doğru yöntemdir.

---

## 3) Google ile Giriş — Backend/Frontend Detayları

### Mantık (Backend’te olan)

* Flutter `signInWithOAuth(google)` çağırır → Supabase Google’a yönlendirir.
* Google onayı sonrası Supabase JWT üretir → **redirect_to** adresine `access_token`, `refresh_token` ekleyerek döner.

### Flutter (Frontend) Gerekenler

* `redirect_to` deep link’i whitelist’e ekli (Supabase).
* `uni_links` ile deep link yakalanır → `access_token`/`refresh_token` alınır → `auth.setSession(...)`.

### Flutter Kod (Buton + Çağrı)

```dart
final supabase = Supabase.instance.client;

Future<void> signInWithGoogle() async {
  final res = await supabase.auth.signInWithOAuth(
    Provider.google,
    redirectTo: 'intronauts://login-callback',
  );
  // res.data.url → tarayıcıda açılır; Flutter SDK otomatik yönlendirir.
}
```

### cURL (Tarayıcı testi için)

**📌 Postman Koleksiyonu:**
- [Google Access Key GET Request](https://sametanaz-6209138.postman.co/workspace/Samet-Anaz's-Workspace~c6561109-6ecd-400f-818b-acb03dd5cb3d/request/49152897-016a835b-3859-4ecd-b3ea-8871488aff02?action=share&creator=49152897&active-environment=49152897-87a638ee-0ad5-4b3e-ae91-70dee09f4fee)
- [Google Get User Credentials GET Request](https://sametanaz-6209138.postman.co/workspace/Samet-Anaz's-Workspace~c6561109-6ecd-400f-818b-acb03dd5cb3d/request/49152897-55d5325f-81d6-46e0-a183-81d14aea6d07?action=share&creator=49152897&active-environment=49152897-87a638ee-0ad5-4b3e-ae91-70dee09f4fee)

```bash
# Google'a yönlendiren URL (tarayıcıda açılır)
open "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/authorize?provider=google&redirect_to=intronauts://login-callback"
```

### Login Sonrası Kullanıcıyı Doğrulama (cURL)

```bash
curl -X GET "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/user" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY"
```

---

## 4) Şifre Sıfırlama — Backend/Frontend Detayları

### Mantık (Backend’te olan)

* `POST /auth/v1/recover` çağrılır → Supabase SMTP sağlayıcına (Resend) e-posta bırakır.
* E-postada şu formatta link olur:
  `https://.../auth/v1/verify?token=<...>&type=recovery&redirect_to=intronauts://reset-password`
* Kullanıcı linke tıklayınca Supabase token’ı doğrular → **redirect_to** ile uygulamaya döndürür.

### E-Posta İçeriği (Örnek)

```
From: Intronauts Destek Ekibi <noreply@intronauts.online>
Subject: Reset Your Password

<h2>Reset Password</h2>
<p>Follow this link to reset the password for your user:</p>
<p><a href="https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/verify?token=...&type=recovery&redirect_to=intronauts://reset-password">Reset Password</a></p>
```

### Postman/cURL — Reset Mail Gönderme (Doğru Biçim)

> **Dikkat:** `redirect_to` **URL query parametresi** olmalı.

**📌 Postman Koleksiyonu:**
- [Update Password POST Request](https://sametanaz-6209138.postman.co/workspace/Samet-Anaz's-Workspace~c6561109-6ecd-400f-818b-acb03dd5cb3d/request/49152897-75fee7ad-1e57-4e11-88f6-b2f7ee6bb782?action=share&creator=49152897&ctx=documentation&active-environment=49152897-87a638ee-0ad5-4b3e-ae91-70dee09f4fee)
- [Update Password PUT Request](https://sametanaz-6209138.postman.co/workspace/Samet-Anaz's-Workspace~c6561109-6ecd-400f-818b-acb03dd5cb3d/request/49152897-9be2f4dc-a9d6-41a2-a8cb-25f6cc654bd7?action=share&creator=49152897&active-environment=49152897-87a638ee-0ad5-4b3e-ae91-70dee09f4fee)

```bash
curl -X POST \
  "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/recover?redirect_to=intronauts://reset-password" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "email": "kullanici@mail.com" }'
```

### Flutter — Reset Mail Gönderme

```dart
await Supabase.instance.client.auth.resetPasswordForEmail(
  'kullanici@mail.com',
  redirectTo: 'intronauts://reset-password',
);
```

### Flutter — Yeni Şifre Kaydetme Ekranı

```dart
Future<void> submitNewPassword(String newPassword) async {
  // recovery token deep link ile session’a set edilmiş olmalı
  final res = await Supabase.instance.client.auth.updateUser(
    UserAttributes(password: newPassword),
  );
  if (res.user != null) {
    // başarı → kullanıcıyı login sayfasına veya home’a yönlendir
  }
}
```

### cURL — Yeni Şifre Kaydetme (Token ile)

```bash
curl -X POST "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/user" \
  -H "Authorization: Bearer <RECOVERY_ACCESS_TOKEN>" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "password": "YeniSifre123!" }'
```

---

## 5) Test Planı (Mobil)

1. **Google Login**

   * Uygulamada “Google ile Giriş” butonuna bas → tarayıcı açılır → Google onayı → app’e döner.
   * Deep link yakalanır → `auth.setSession(...)` → `/home` ekranı açılır.
   * `supabase.auth.getUser()` ile kullanıcıyı al.

2. **Şifre Sıfırlama**

   * Uygulamada mail adresini gir → `resetPasswordForEmail(redirectTo: 'intronauts://reset-password')`
   * Mail gelir (Resend Logs’ta görünmeli).
   * Linke tıkla → app açılır → yeni şifre ekranı → `auth.updateUser({ password })`.

3. **Postman**

   * `POST /auth/v1/recover?redirect_to=intronauts://reset-password` → 200
   * Resend **Logs**: `POST /emails` 200 + “Delivered”
   * Gerekirse spam → “Not Spam” işaretle (ilk günlerde normal).

---

## 6) Hata Ayıklama (Checklist)

* **Mail gelmiyor**

  * Resend **Domain = Verified** (SPF/DKIM/Return-Path)
  * Supabase SMTP host/port/user/pass doğru (Resend: host `smtp.resend.com`, port `587`, user `resend`)
  * Supabase **Auth → Logs** içinde `smtp` / `error` ara
  * Spam’i kontrol et; DMARC ekle (öneri: `v=DMARC1; p=quarantine; aspf=r; adkim=r`)

* **Redirect yanlış/localhost**

  * `redirect_to` **URL query parametre** olarak verilmeli
  * **Authentication → URL Configuration → Redirect URLs** listesinde deep link **ekli olmalı**
  * Mobil deep link scheme/host app’te tanımlı olmalı

* **Google “redirect_uri_mismatch”**

  * Google Cloud → OAuth client → Authorized redirect URIs listesinde:
    `https://...supabase.co/auth/v1/callback` **birebir** olmalı.

---

## 7) Güvenlik Notları

* E-postadaki recovery token **tek kullanımlık ve kısa ömürlüdür** (Supabase yönetir).
* Deep link üzerinden gelen token’ı sadece reset/login akışında kullanın, kalıcı saklamayın.
* Üretimde **HTTPS** ve **güncel SDK** sürümlerini kullanın.

---

## 8) Hızlı Referans — Endpoint & cURL

### Google OAuth (tarayıcı testi)

```bash
open "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/authorize?provider=google&redirect_to=intronauts://login-callback"
```

### Kullanıcıyı Getir (token doğrulama)

```bash
curl -X GET "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/user" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY"
```

### Şifre Sıfırlama Maili Gönder

```bash
curl -X POST \
  "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/recover?redirect_to=intronauts://reset-password" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "email": "kullanici@mail.com" }'
```

### Yeni Şifre Kaydet (recovery token ile)

```bash
curl -X POST "https://fajdjdlecqokklpdgnfl.supabase.co/auth/v1/user" \
  -H "Authorization: Bearer <RECOVERY_ACCESS_TOKEN>" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "password": "YeniSifre123!" }'
```

---

## 9) Flutter’da Minimal UI Parçaları

**Google ile Giriş Butonu**

```dart
ElevatedButton(
  onPressed: () => Supabase.instance.client.auth.signInWithOAuth(
    Provider.google,
    redirectTo: 'intronauts://login-callback',
  ),
  child: const Text('Google ile Giriş'),
)
```

**Yeni Şifre Ekranı (özet)**

```dart
class SetNewPasswordPage extends StatefulWidget {
  final String recoveryToken;
  const SetNewPasswordPage({super.key, required this.recoveryToken});

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _ctrl = TextEditingController();

  Future<void> _submit() async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: _ctrl.text.trim()),
    );
    if (mounted) Navigator.pop(context); // veya /login
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yeni Şifre')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _ctrl, obscureText: true),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _submit, child: const Text('Kaydet')),
        ],
      ),
    ),
  );
}
```

