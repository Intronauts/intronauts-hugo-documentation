-- /////////////////////////////////////////////////////////
-- AI Sınav Değerlendirme Sistemi - Nihai Şema (v3.3 - Final Extended)
-- Multi-Tenant (Okul Bazlı) Yapı + Idempotent Enum + Partial Index + updated_at Trigger
-- Tarih: 10 Ekim 2025
-- /////////////////////////////////////////////////////////

-- ======================
-- ENUM TANIMLARI (idempotent)
-- ======================
DO $$ BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'exam_status') THEN 
    CREATE TYPE exam_status AS ENUM ('draft', 'published', 'archived'); 
  END IF; 
END $$;

DO $$ BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'paper_status') THEN 
    CREATE TYPE paper_status AS ENUM (
      'pending',
      'identifying',
      'needs_identification',
      'evaluated',
      'published'
    ); 
  END IF; 
END $$;

-- ======================
-- 0. KURUM / OKUL YÖNETİMİ
-- ======================
CREATE TABLE IF NOT EXISTS public.schools (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ======================
-- 1. KULLANICI ve YETKİ YÖNETİMİ
-- ======================
CREATE TABLE IF NOT EXISTS public.roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS public.permissions (
  id SERIAL PRIMARY KEY,
  code VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
  id SERIAL PRIMARY KEY,
  role_id INT REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id INT REFERENCES public.permissions(id) ON DELETE CASCADE,
  UNIQUE (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.users (
  id SERIAL PRIMARY KEY,
  school_id INT NOT NULL DEFAULT 1 REFERENCES public.schools(id) ON DELETE RESTRICT,
  name VARCHAR(100),
  email VARCHAR(150) NOT NULL UNIQUE,
  school_number VARCHAR(50),
  phone_number VARCHAR(20),
  birth_date DATE,
  role_id INT NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  password_hash VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (school_id, school_number)
);

-- ======================
-- 2. SINIF ve MÜFREDAT YÖNETİMİ
-- ======================
CREATE TABLE IF NOT EXISTS public.classes (
  id SERIAL PRIMARY KEY,
  school_id INT NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  teacher_id INT NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(20) UNIQUE,
  academic_year VARCHAR(50),
  term VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.class_members (
  id SERIAL PRIMARY KEY,
  class_id INT REFERENCES public.classes(id) ON DELETE CASCADE,
  student_id INT REFERENCES public.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.syllabi (
  id SERIAL PRIMARY KEY,
  class_id INT NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  original_file_path VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.syllabus_topics (
  id SERIAL PRIMARY KEY,
  syllabus_id INT NOT NULL REFERENCES public.syllabi(id) ON DELETE CASCADE,
  parent_topic_id INT REFERENCES public.syllabus_topics(id) ON DELETE CASCADE,
  topic_name VARCHAR(255) NOT NULL,
  description TEXT,
  expected_week INT
);

-- ======================
-- 3. SINAV ve DEĞERLENDİRME YÖNETİMİ
-- ======================
CREATE TABLE IF NOT EXISTS public.exams (
  id SERIAL PRIMARY KEY,
  class_id INT NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  title VARCHAR(150) NOT NULL,
  exam_content TEXT,
  answer_key JSONB DEFAULT '{}'::jsonb,
  status exam_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.exam_questions (
  id SERIAL PRIMARY KEY,
  exam_id INT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  topic_id INT REFERENCES public.syllabus_topics(id) ON DELETE SET NULL,
  question_number INT NOT NULL,
  question_text TEXT,
  points FLOAT,
  UNIQUE (exam_id, question_number)
);

CREATE TABLE IF NOT EXISTS public.student_papers (
  id SERIAL PRIMARY KEY,
  exam_id INT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  student_id INT REFERENCES public.users(id) ON DELETE SET NULL,
  ai_score FLOAT,
  teacher_score FLOAT,
  feedback TEXT,
  evaluation_summary JSONB DEFAULT '{}'::jsonb,
  ocr_student_info JSONB DEFAULT '{}'::jsonb,
  status paper_status NOT NULL DEFAULT 'pending',
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.student_paper_files (
  id SERIAL PRIMARY KEY,
  paper_id INT NOT NULL REFERENCES public.student_papers(id) ON DELETE CASCADE,
  page_image_path VARCHAR(255) NOT NULL,
  page_number INT NOT NULL,
  ocr_text JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (paper_id, page_number)
);

-- ======================
-- 4. INDEXLER ve PERFORMANS İYİLEŞTİRMELERİ
-- ======================

CREATE INDEX IF NOT EXISTS idx_exams_status ON public.exams(status);
CREATE INDEX IF NOT EXISTS idx_student_papers_status ON public.student_papers(status);
CREATE INDEX IF NOT EXISTS idx_exam_questions_topic_id ON public.exam_questions(topic_id);

-- Soft delete destekli benzersiz üyelik
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_class_member
ON public.class_members (class_id, student_id)
WHERE deleted_at IS NULL;

-- ======================
-- 5. updated_at OTOMATİK GÜNCELLEME TRIGGERLARI
-- ======================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE 
  tbl text;
BEGIN
  FOR tbl IN 
    SELECT unnest(ARRAY['users','classes','exams','student_papers'])
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at_trigger ON public.%I;', tbl);
    EXECUTE format('CREATE TRIGGER set_updated_at_trigger BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();', tbl);
  END LOOP;
END
$$;

-- ======================
-- TAMAMLANDI ✅
-- ======================
