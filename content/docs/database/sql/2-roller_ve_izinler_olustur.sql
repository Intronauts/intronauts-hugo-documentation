-- 1. ADIM: ROLLERİ GÜNCELLEME
INSERT INTO roles (id, name, description) VALUES
(1, 'student', 'Platformdaki öğrenci kullanıcıları.'),
(2, 'teacher', 'Sınıf ve sınav yöneten öğretmen kullanıcıları.'),
(3, 'admin', 'Tüm sistemi yöneten yönetici.'),
(4, 'editor', 'Kurumdaki tüm verileri görüntüleyebilen gözetmen/yetkili rolü.')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;


-- 2. ADIM: DETAYLI YETKİLERİ GÜNCELLEME (YENİ YETKİLER EKLENDİ)
INSERT INTO permissions (id, code, description) VALUES
-- Sınıf Yönetimi
(101, 'class:create', 'Yeni bir sınıf oluşturma.'),
(102, 'class:read:own', 'Kullanıcının kendi sınıflarını listelemesi/görüntülemesi.'),
(103, 'class:update:own', 'Kullanıcının kendi sınıflarının detaylarını güncellemesi.'),
(104, 'class:delete:own', 'Kullanıcının kendi sınıflarını silmesi.'),
(105, 'class:members:manage:own', 'Kullanıcının kendi sınıflarına öğrenci eklemesi/çıkarması.'),
(106, 'class:read:all', 'Kurumdaki TÜM sınıfları görüntüleme (Editör/Admin için).'),

-- Müfredat Yönetimi
(201, 'syllabus:create:own', 'Kendi sınıfına yeni bir müfredat eklemesi.'),
(202, 'syllabus:update:own', 'Kendi sınıfının müfredatını güncellemesi.'),

-- Sınav Yönetimi
(301, 'exam:create', 'Yeni bir sınav oluşturma (AI Editör veya kağıt yükleyerek).'),
(302, 'exam:update:own', 'Kendi oluşturduğu bir sınavı güncelleme.'),
(303, 'exam:delete:own', 'Kendi oluşturduğu bir sınavı silme.'),
(304, 'exam:read:all', 'Kurumdaki TÜM sınavları görüntüleme (Editör/Admin için).'),

-- Değerlendirme Süreci
(401, 'exam:upload_papers', 'Bir sınava ait öğrenci kağıtlarını topluca yükleme.'),
(402, 'exam:match_papers', 'Eşleşmeyen kağıtları manuel olarak öğrencilerle eşleştirme.'),
(403, 'exam:review_grades', 'Yapay zekanın verdiği notları inceleme ve üzerine yazma (override).'),
(404, 'exam:publish_results', 'Nihai sonuçları öğrencilere yayınlama.'),

-- Sonuç Görüntüleme
(501, 'results:read:own', 'Öğrencinin sadece kendi sınav sonuçlarını ve kağıdını görmesi.'),
(502, 'results:read:class', 'Öğretmenin bir sınıftaki tüm sınav sonuçlarını ve kağıtlarını görmesi.'),
(503, 'results:read:all', 'Kurumdaki TÜM sınav sonuçlarını ve analizleri görüntüleme (Editör/Admin için).'),

-- Öğrenci Eylemleri
(601, 'class:join', 'Öğrencinin bir davet kodu ile sınıfa katılması.'),

-- Yönetimsel Yetkiler
(901, 'admin:users:manage', 'Sistemdeki tüm kullanıcıları yönetme.')
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, description = EXCLUDED.description;


-- 3. ADIM: ROLLERİ YENİ YETKİLERLE EŞLEŞTİRME

-- Önce mevcut tüm eşleşmeleri temizleyelim ki yeniden doğru kurabilelim.
TRUNCATE TABLE role_permissions;

-- Öğrenci Yetkileri (Role ID: 1)
INSERT INTO role_permissions (role_id, permission_id) VALUES
(1, 501), -- results:read:own
(1, 601); -- class:join

-- Öğretmen Yetkileri (Role ID: 2)
INSERT INTO role_permissions (role_id, permission_id) VALUES
(2, 101), -- class:create
(2, 102), -- class:read:own
(2, 103), -- class:update:own
(2, 104), -- class:delete:own
(2, 105), -- class:members:manage:own
(2, 201), -- syllabus:create:own
(2, 202), -- syllabus:update:own
(2, 301), -- exam:create
(2, 302), -- exam:update:own
(2, 303), -- exam:delete:own
(2, 401), -- exam:upload_papers
(2, 402), -- exam:match_papers
(2, 403), -- exam:review_grades
(2, 404), -- exam:publish_results
(2, 502); -- results:read:class

-- Editör/Gözetmen Yetkileri (Role ID: 4) - SADECE OKUMA VE GÖRÜNTÜLEME
INSERT INTO role_permissions (role_id, permission_id) VALUES
(4, 106), -- class:read:all
(4, 304), -- exam:read:all
(4, 503); -- results:read:all

-- Admin Yetkileri (Role ID: 3) - Tüm yetkilere sahip
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions;