


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."exam_status" AS ENUM (
    'draft',
    'published',
    'archived'
);


ALTER TYPE "public"."exam_status" OWNER TO "postgres";


CREATE TYPE "public"."paper_status" AS ENUM (
    'pending',
    'identifying',
    'needs_identification',
    'evaluated',
    'published'
);


ALTER TYPE "public"."paper_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_class_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  new_code text;
  i int;
  use_pgcrypto boolean := EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'
  );
  b bytea;
  idx int;
  p_length int := 8; -- default code length; change if you want a different length
BEGIN
  -- Only generate if code is null or empty
  IF NEW.code IS NOT NULL AND btrim(NEW.code) <> '' THEN
    RETURN NEW;
  END IF;

  LOOP
    new_code := '';
    IF use_pgcrypto THEN
      -- generate p_length random bytes and map to chars
      b := gen_random_bytes(p_length);
      FOR i IN 0..p_length-1 LOOP
        idx := (get_byte(b, i) % length(chars)) + 1;
        new_code := new_code || substr(chars, idx, 1);
      END LOOP;
    ELSE
      -- fallback to built-in random()
      FOR i IN 1..p_length LOOP
        idx := floor(random() * length(chars) + 1)::int;
        new_code := new_code || substr(chars, idx, 1);
      END LOOP;
    END IF;

    -- ensure uniqueness
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.classes c WHERE c.code = new_code
    );
    -- otherwise loop and try again
  END LOOP;

  NEW.code := new_code;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."generate_class_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_class_student_count"("p_class_id" integer) RETURNS integer
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  student_count int;
BEGIN
  SELECT COUNT(*)
  INTO student_count
  FROM class_members
  WHERE class_id = p_class_id
    AND deleted_at IS NULL;
  
  RETURN student_count;
END;
$$;


ALTER FUNCTION "public"."get_class_student_count"("p_class_id" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_class_student_count"("p_class_id" integer) IS 'Bir sınıftaki aktif öğrenci sayısını döndürür. RLS bypass için SECURITY DEFINER kullanılır.';



CREATE OR REPLACE FUNCTION "public"."get_class_students"("p_class_id" integer) RETURNS TABLE("id" integer, "name" character varying, "email" character varying, "school_number" character varying, "joined_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.name,
    u.email,
    u.school_number,
    cm.joined_at
  FROM class_members cm
  INNER JOIN users u ON cm.student_id = u.id
  WHERE cm.class_id = p_class_id
    AND cm.deleted_at IS NULL
  ORDER BY cm.joined_at ASC;
END;
$$;


ALTER FUNCTION "public"."get_class_students"("p_class_id" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_class_students"("p_class_id" integer) IS 'Bir sınıftaki aktif öğrenci listesini döndürür. RLS bypass için SECURITY DEFINER kullanılır.';



CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  user_role text;
  resolved_role_id int;
  resolved_school_id int;
  student_school_number text;
  user_birth_date date;
begin
  user_role := coalesce(
    new.raw_app_meta_data->>'role',
    new.raw_user_meta_data->>'role',
    'student'
  );
  resolved_school_id := coalesce(
    (new.raw_user_meta_data->>'school_id')::int,
    1
  );

  select id into resolved_role_id
  from public.roles
  where lower(name) = lower(user_role)
  limit 1;

  if resolved_role_id is null then
    select id into resolved_role_id from public.roles where name = 'student' limit 1;
  end if;

  if lower(user_role) = 'student' then
    student_school_number := new.raw_user_meta_data->>'school_number';
  else
    student_school_number := null;
  end if;

  if new.raw_user_meta_data ? 'birth_date' then
    user_birth_date := to_date(new.raw_user_meta_data->>'birth_date', 'YYYY-MM-DD');
  else
    user_birth_date := null;
  end if;

  if exists(select 1 from public.users where email = new.email) then
    return new;
  end if;

  insert into public.users (
    school_id,
    name,
    email,
    phone_number,
    school_number,
    birth_date,
    role_id,
    auth_user_id,
    created_at,
    updated_at
  )
  values (
    resolved_school_id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'phone_number',
    student_school_number,
    user_birth_date,
    resolved_role_id,
    new.id,
    now(),
    now()
  );

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."join_class_by_code"("p_class_code" "text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_user_id int;
  v_user_role_id int;
  v_user_school_id int;
  v_class_id int;
  v_class_school_id int;
  v_class_name text;
  v_existing_member_id int;
  v_result json;
BEGIN
  -- 1. Mevcut kullanıcıyı al
  SELECT id, role_id, school_id
  INTO v_user_id, v_user_role_id, v_user_school_id
  FROM users
  WHERE auth_user_id = auth.uid();

  -- Debug log
  RAISE NOTICE 'User ID: %, Role: %, School ID: %', v_user_id, v_user_role_id, v_user_school_id;

  -- Kullanıcı bulunamadıysa
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Oturum açmanız gerekiyor.'
      USING HINT = 'USER_NOT_FOUND';
  END IF;

  -- 2. Role kontrolü - sadece öğrenciler (role_id = 1)
  IF v_user_role_id != 1 THEN
    RAISE EXCEPTION 'Sadece öğrenciler sınıfa katılabilir.'
      USING HINT = 'INVALID_ROLE';
  END IF;

  -- 3. Sınıfı kod ile bul
  SELECT id, school_id, name
  INTO v_class_id, v_class_school_id, v_class_name
  FROM classes
  WHERE code = UPPER(TRIM(p_class_code));

  -- Debug log
  RAISE NOTICE 'Class ID: %, Class School ID: %, Class Name: %', v_class_id, v_class_school_id, v_class_name;

  -- Sınıf bulunamadıysa
  IF v_class_id IS NULL THEN
    RAISE EXCEPTION 'Geçersiz sınıf kodu: %', p_class_code
      USING HINT = 'CLASS_NOT_FOUND';
  END IF;

  -- 4. OKUL KONTROLÜ - DÜZELTME
  -- NULL kontrolü ekledik ve COALESCE kullandık
  IF COALESCE(v_class_school_id, -1) != COALESCE(v_user_school_id, -2) THEN
    RAISE EXCEPTION 'Bu sınıf farklı bir okula ait. (Sınıf Okul ID: %, Öğrenci Okul ID: %)', 
      v_class_school_id, v_user_school_id
      USING HINT = 'SCHOOL_MISMATCH';
  END IF;

  -- 5. Öğrenci zaten bu sınıfta mı kontrol et (aktif üyelik)
  SELECT id
  INTO v_existing_member_id
  FROM class_members
  WHERE class_id = v_class_id
    AND student_id = v_user_id
    AND deleted_at IS NULL;

  -- Zaten üyeyse
  IF v_existing_member_id IS NOT NULL THEN
    RAISE EXCEPTION 'Zaten bu sınıftasınız.'
      USING HINT = 'ALREADY_MEMBER';
  END IF;

  -- 6. Sınıfa katıl (INSERT)
  INSERT INTO class_members (class_id, student_id, joined_at)
  VALUES (v_class_id, v_user_id, NOW())
  RETURNING id INTO v_existing_member_id;

  -- 7. Başarı mesajı döndür
  v_result := json_build_object(
    'success', true,
    'message', 'Sınıfa başarıyla katıldınız',
    'class_member_id', v_existing_member_id,
    'class_id', v_class_id,
    'class_name', v_class_name,
    'user_school_id', v_user_school_id,
    'class_school_id', v_class_school_id
  );

  RAISE NOTICE 'Success: %', v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    -- Hata mesajını logla ve yeniden fırlat
    RAISE EXCEPTION '%', SQLERRM
      USING HINT = SQLSTATE;
END;
$$;


ALTER FUNCTION "public"."join_class_by_code"("p_class_code" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."join_class_by_code"("p_class_code" "text") IS 'Öğrencinin sınıf kodunu kullanarak sınıfa katılmasını sağlar. Okul kontrolü eklenmiştir.';



CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."class_members" (
    "id" integer NOT NULL,
    "class_id" integer,
    "student_id" integer,
    "joined_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."class_members" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."class_members_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."class_members_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."class_members_id_seq" OWNED BY "public"."class_members"."id";



CREATE TABLE IF NOT EXISTS "public"."classes" (
    "id" integer NOT NULL,
    "school_id" integer NOT NULL,
    "teacher_id" integer NOT NULL,
    "name" character varying(100) NOT NULL,
    "code" character varying(20),
    "academic_year" character varying(50),
    "term" character varying(50),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."classes" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."classes_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."classes_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."classes_id_seq" OWNED BY "public"."classes"."id";



CREATE TABLE IF NOT EXISTS "public"."exam_questions" (
    "id" integer NOT NULL,
    "exam_id" integer NOT NULL,
    "topic_id" integer,
    "question_number" integer NOT NULL,
    "question_text" "text",
    "points" double precision
);


ALTER TABLE "public"."exam_questions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."exam_questions_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."exam_questions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."exam_questions_id_seq" OWNED BY "public"."exam_questions"."id";



CREATE TABLE IF NOT EXISTS "public"."exams" (
    "id" integer NOT NULL,
    "class_id" integer NOT NULL,
    "title" character varying(150) NOT NULL,
    "exam_content" "text",
    "answer_key" "jsonb" DEFAULT '{}'::"jsonb",
    "status" "public"."exam_status" DEFAULT 'draft'::"public"."exam_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."exams" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."exams_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."exams_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."exams_id_seq" OWNED BY "public"."exams"."id";



CREATE TABLE IF NOT EXISTS "public"."permissions" (
    "id" integer NOT NULL,
    "code" character varying(100) NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."permissions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."permissions_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."permissions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."permissions_id_seq" OWNED BY "public"."permissions"."id";



CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "id" integer NOT NULL,
    "role_id" integer,
    "permission_id" integer
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."role_permissions_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."role_permissions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."role_permissions_id_seq" OWNED BY "public"."role_permissions"."id";



CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" integer NOT NULL,
    "name" character varying(50) NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."roles_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."roles_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."roles_id_seq" OWNED BY "public"."roles"."id";



CREATE TABLE IF NOT EXISTS "public"."schools" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "address" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."schools" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."schools_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."schools_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."schools_id_seq" OWNED BY "public"."schools"."id";



CREATE TABLE IF NOT EXISTS "public"."student_paper_files" (
    "id" integer NOT NULL,
    "paper_id" integer NOT NULL,
    "page_image_path" character varying(255) NOT NULL,
    "page_number" integer NOT NULL,
    "ocr_text" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."student_paper_files" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."student_paper_files_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."student_paper_files_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."student_paper_files_id_seq" OWNED BY "public"."student_paper_files"."id";



CREATE TABLE IF NOT EXISTS "public"."student_papers" (
    "id" integer NOT NULL,
    "exam_id" integer NOT NULL,
    "student_id" integer,
    "ai_score" double precision,
    "teacher_score" double precision,
    "feedback" "text",
    "evaluation_summary" "jsonb" DEFAULT '{}'::"jsonb",
    "ocr_student_info" "jsonb" DEFAULT '{}'::"jsonb",
    "status" "public"."paper_status" DEFAULT 'pending'::"public"."paper_status" NOT NULL,
    "uploaded_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."student_papers" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."student_papers_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."student_papers_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."student_papers_id_seq" OWNED BY "public"."student_papers"."id";



CREATE TABLE IF NOT EXISTS "public"."syllabi" (
    "id" integer NOT NULL,
    "class_id" integer NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text",
    "original_file_path" character varying(255),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."syllabi" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."syllabi_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."syllabi_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."syllabi_id_seq" OWNED BY "public"."syllabi"."id";



CREATE TABLE IF NOT EXISTS "public"."syllabus_topics" (
    "id" integer NOT NULL,
    "syllabus_id" integer NOT NULL,
    "parent_topic_id" integer,
    "topic_name" character varying(255) NOT NULL,
    "description" "text",
    "expected_week" integer
);


ALTER TABLE "public"."syllabus_topics" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."syllabus_topics_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."syllabus_topics_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."syllabus_topics_id_seq" OWNED BY "public"."syllabus_topics"."id";



CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" integer NOT NULL,
    "school_id" integer,
    "name" character varying(100),
    "email" character varying(150) NOT NULL,
    "school_number" character varying(50),
    "phone_number" character varying(20),
    "birth_date" "date",
    "role_id" integer NOT NULL,
    "password_hash" character varying(255),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "auth_user_id" "uuid"
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."users_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_id_seq" OWNED BY "public"."users"."id";



ALTER TABLE ONLY "public"."class_members" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."class_members_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."classes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."classes_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."exam_questions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."exam_questions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."exams" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."exams_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."permissions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."permissions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."role_permissions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."role_permissions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."roles" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."roles_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."schools" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."schools_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."student_paper_files" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."student_paper_files_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."student_papers" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."student_papers_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."syllabi" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."syllabi_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."syllabus_topics" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."syllabus_topics_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."class_members"
    ADD CONSTRAINT "class_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exam_questions"
    ADD CONSTRAINT "exam_questions_exam_id_question_number_key" UNIQUE ("exam_id", "question_number");



ALTER TABLE ONLY "public"."exam_questions"
    ADD CONSTRAINT "exam_questions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exams"
    ADD CONSTRAINT "exams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_permission_id_key" UNIQUE ("role_id", "permission_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schools"
    ADD CONSTRAINT "schools_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."schools"
    ADD CONSTRAINT "schools_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."student_paper_files"
    ADD CONSTRAINT "student_paper_files_paper_id_page_number_key" UNIQUE ("paper_id", "page_number");



ALTER TABLE ONLY "public"."student_paper_files"
    ADD CONSTRAINT "student_paper_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."student_papers"
    ADD CONSTRAINT "student_papers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."syllabi"
    ADD CONSTRAINT "syllabi_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."syllabus_topics"
    ADD CONSTRAINT "syllabus_topics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_key" UNIQUE ("auth_user_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_school_id_school_number_key" UNIQUE ("school_id", "school_number");



CREATE INDEX "idx_exam_questions_topic_id" ON "public"."exam_questions" USING "btree" ("topic_id");



CREATE INDEX "idx_exams_status" ON "public"."exams" USING "btree" ("status");



CREATE INDEX "idx_student_papers_status" ON "public"."student_papers" USING "btree" ("status");



CREATE UNIQUE INDEX "idx_unique_active_class_member" ON "public"."class_members" USING "btree" ("class_id", "student_id") WHERE ("deleted_at" IS NULL);



CREATE OR REPLACE TRIGGER "classes_generate_code_trigger" BEFORE INSERT ON "public"."classes" FOR EACH ROW EXECUTE FUNCTION "public"."generate_class_code"();



CREATE OR REPLACE TRIGGER "set_updated_at_trigger" BEFORE UPDATE ON "public"."classes" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at_trigger" BEFORE UPDATE ON "public"."exams" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at_trigger" BEFORE UPDATE ON "public"."student_papers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at_trigger" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."class_members"
    ADD CONSTRAINT "class_members_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."class_members"
    ADD CONSTRAINT "class_members_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "public"."schools"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "public"."users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."exam_questions"
    ADD CONSTRAINT "exam_questions_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "public"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exam_questions"
    ADD CONSTRAINT "exam_questions_topic_id_fkey" FOREIGN KEY ("topic_id") REFERENCES "public"."syllabus_topics"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."exams"
    ADD CONSTRAINT "exams_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."student_paper_files"
    ADD CONSTRAINT "student_paper_files_paper_id_fkey" FOREIGN KEY ("paper_id") REFERENCES "public"."student_papers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."student_papers"
    ADD CONSTRAINT "student_papers_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "public"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."student_papers"
    ADD CONSTRAINT "student_papers_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."syllabi"
    ADD CONSTRAINT "syllabi_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."syllabus_topics"
    ADD CONSTRAINT "syllabus_topics_parent_topic_id_fkey" FOREIGN KEY ("parent_topic_id") REFERENCES "public"."syllabus_topics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."syllabus_topics"
    ADD CONSTRAINT "syllabus_topics_syllabus_id_fkey" FOREIGN KEY ("syllabus_id") REFERENCES "public"."syllabi"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "public"."schools"("id") ON DELETE RESTRICT;



CREATE POLICY "anyone_can_view_schools" ON "public"."schools" FOR SELECT USING (true);



CREATE POLICY "authenticated_can_insert_memberships" ON "public"."class_members" FOR INSERT TO "authenticated" WITH CHECK ((("student_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE ("users"."auth_user_id" = "auth"."uid"()))) OR (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = ANY (ARRAY[3, 4])))))));



ALTER TABLE "public"."class_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."classes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owners_can_delete_classes" ON "public"."classes" FOR DELETE TO "authenticated" USING ((("teacher_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = 2)))) OR (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = ANY (ARRAY[3, 4])))))));



CREATE POLICY "owners_can_update_classes" ON "public"."classes" FOR UPDATE TO "authenticated" USING ((("teacher_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = 2)))) OR (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = ANY (ARRAY[3, 4])))))));



ALTER TABLE "public"."schools" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "students_can_update_own_memberships" ON "public"."class_members" FOR UPDATE TO "authenticated" USING ((("student_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = 1)))) OR (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = ANY (ARRAY[3, 4]))))))) WITH CHECK ((("student_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = 1)))) OR (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = ANY (ARRAY[3, 4])))))));



CREATE POLICY "teachers_admins_editors_can_create_classes" ON "public"."classes" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."id" = "classes"."teacher_id") AND ("users"."role_id" = ANY (ARRAY[2, 3, 4]))))));



CREATE POLICY "users_can_view_memberships" ON "public"."class_members" FOR SELECT TO "authenticated" USING ((("student_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = 1)))) OR (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."auth_user_id" = "auth"."uid"()) AND ("users"."role_id" = ANY (ARRAY[3, 4])))))));



CREATE POLICY "users_can_view_relevant_classes" ON "public"."classes" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM ("public"."class_members" "cm"
     JOIN "public"."users" "u" ON (("cm"."student_id" = "u"."id")))
  WHERE (("cm"."class_id" = "classes"."id") AND ("u"."auth_user_id" = "auth"."uid"()) AND ("u"."role_id" = 1) AND ("cm"."deleted_at" IS NULL)))) OR (EXISTS ( SELECT 1
   FROM "public"."users" "u"
  WHERE (("u"."id" = "classes"."teacher_id") AND ("u"."auth_user_id" = "auth"."uid"()) AND ("u"."role_id" = 2)))) OR (EXISTS ( SELECT 1
   FROM "public"."users" "u"
  WHERE (("u"."auth_user_id" = "auth"."uid"()) AND ("u"."role_id" = ANY (ARRAY[3, 4])))))));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."generate_class_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_class_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_class_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_class_student_count"("p_class_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_class_student_count"("p_class_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_class_student_count"("p_class_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_class_students"("p_class_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_class_students"("p_class_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_class_students"("p_class_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."join_class_by_code"("p_class_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."join_class_by_code"("p_class_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."join_class_by_code"("p_class_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";


















GRANT ALL ON TABLE "public"."class_members" TO "anon";
GRANT ALL ON TABLE "public"."class_members" TO "authenticated";
GRANT ALL ON TABLE "public"."class_members" TO "service_role";



GRANT ALL ON SEQUENCE "public"."class_members_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."class_members_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."class_members_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."classes" TO "anon";
GRANT ALL ON TABLE "public"."classes" TO "authenticated";
GRANT ALL ON TABLE "public"."classes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."classes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."classes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."classes_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."exam_questions" TO "anon";
GRANT ALL ON TABLE "public"."exam_questions" TO "authenticated";
GRANT ALL ON TABLE "public"."exam_questions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."exam_questions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."exam_questions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."exam_questions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."exams" TO "anon";
GRANT ALL ON TABLE "public"."exams" TO "authenticated";
GRANT ALL ON TABLE "public"."exams" TO "service_role";



GRANT ALL ON SEQUENCE "public"."exams_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."exams_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."exams_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."permissions" TO "anon";
GRANT ALL ON TABLE "public"."permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."schools" TO "anon";
GRANT ALL ON TABLE "public"."schools" TO "authenticated";
GRANT ALL ON TABLE "public"."schools" TO "service_role";



GRANT ALL ON SEQUENCE "public"."schools_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."schools_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."schools_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."student_paper_files" TO "anon";
GRANT ALL ON TABLE "public"."student_paper_files" TO "authenticated";
GRANT ALL ON TABLE "public"."student_paper_files" TO "service_role";



GRANT ALL ON SEQUENCE "public"."student_paper_files_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."student_paper_files_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."student_paper_files_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."student_papers" TO "anon";
GRANT ALL ON TABLE "public"."student_papers" TO "authenticated";
GRANT ALL ON TABLE "public"."student_papers" TO "service_role";



GRANT ALL ON SEQUENCE "public"."student_papers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."student_papers_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."student_papers_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."syllabi" TO "anon";
GRANT ALL ON TABLE "public"."syllabi" TO "authenticated";
GRANT ALL ON TABLE "public"."syllabi" TO "service_role";



GRANT ALL ON SEQUENCE "public"."syllabi_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."syllabi_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."syllabi_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."syllabus_topics" TO "anon";
GRANT ALL ON TABLE "public"."syllabus_topics" TO "authenticated";
GRANT ALL ON TABLE "public"."syllabus_topics" TO "service_role";



GRANT ALL ON SEQUENCE "public"."syllabus_topics_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."syllabus_topics_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."syllabus_topics_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































RESET ALL;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_auth_user();


