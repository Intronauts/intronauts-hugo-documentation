


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

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."class_members" (
    "id" integer NOT NULL,
    "class_id" integer,
    "student_id" integer,
    "joined_at" timestamp with time zone DEFAULT "now"()
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
    "points" real
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
    "ai_score" real,
    "teacher_score" real,
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



CREATE TABLE IF NOT EXISTS "public"."syllabus" (
    "id" integer NOT NULL,
    "class_id" integer NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text",
    "original_file_path" character varying(255),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."syllabus" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."syllabus_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."syllabus_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."syllabus_id_seq" OWNED BY "public"."syllabus"."id";



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
    "name" character varying(100),
    "email" character varying(150) NOT NULL,
    "school_number" character varying(50),
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



ALTER TABLE ONLY "public"."student_paper_files" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."student_paper_files_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."student_papers" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."student_papers_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."syllabus" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."syllabus_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."syllabus_topics" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."syllabus_topics_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."class_members"
    ADD CONSTRAINT "class_members_class_id_student_id_key" UNIQUE ("class_id", "student_id");



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



ALTER TABLE ONLY "public"."student_paper_files"
    ADD CONSTRAINT "student_paper_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."student_papers"
    ADD CONSTRAINT "student_papers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."syllabus"
    ADD CONSTRAINT "syllabus_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."syllabus_topics"
    ADD CONSTRAINT "syllabus_topics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_key" UNIQUE ("auth_user_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."class_members"
    ADD CONSTRAINT "class_members_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."class_members"
    ADD CONSTRAINT "class_members_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."exam_questions"
    ADD CONSTRAINT "exam_questions_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "public"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exam_questions"
    ADD CONSTRAINT "exam_questions_topic_id_fkey" FOREIGN KEY ("topic_id") REFERENCES "public"."syllabus_topics"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."exams"
    ADD CONSTRAINT "exams_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id");



ALTER TABLE ONLY "public"."student_paper_files"
    ADD CONSTRAINT "student_paper_files_paper_id_fkey" FOREIGN KEY ("paper_id") REFERENCES "public"."student_papers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."student_papers"
    ADD CONSTRAINT "student_papers_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "public"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."student_papers"
    ADD CONSTRAINT "student_papers_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."syllabus"
    ADD CONSTRAINT "syllabus_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."syllabus_topics"
    ADD CONSTRAINT "syllabus_topics_parent_topic_id_fkey" FOREIGN KEY ("parent_topic_id") REFERENCES "public"."syllabus_topics"("id");



ALTER TABLE ONLY "public"."syllabus_topics"
    ADD CONSTRAINT "syllabus_topics_syllabus_id_fkey" FOREIGN KEY ("syllabus_id") REFERENCES "public"."syllabus"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id");





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";








































































































































































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



GRANT ALL ON TABLE "public"."syllabus" TO "anon";
GRANT ALL ON TABLE "public"."syllabus" TO "authenticated";
GRANT ALL ON TABLE "public"."syllabus" TO "service_role";



GRANT ALL ON SEQUENCE "public"."syllabus_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."syllabus_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."syllabus_id_seq" TO "service_role";



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

