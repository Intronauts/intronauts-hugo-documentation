-- 1. Random benzersiz sınıf kodu üretici fonksiyon
create or replace function public.generate_unique_class_code()
returns text as $$
declare
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  new_code text;
  i int;
begin
  loop
    new_code := '';
    for i in 1..8 loop
      new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    end loop;

    -- Eğer bu kod zaten varsa tekrar üret
    exit when not exists (
      select 1 from public.classes c where c.code = new_code
    );
  end loop;

  return new_code;
end;
$$ language plpgsql;

-- 2. Trigger fonksiyonu (insert sırasında otomatik kod atama)
create or replace function public.assign_class_code()
returns trigger as $$
begin
  if new.code is null or trim(new.code) = '' then
    new.code := public.generate_unique_class_code();
  end if;
  return new;
end;
$$ language plpgsql;

-- 3. Trigger tanımı
drop trigger if exists trg_assign_class_code on public.classes;
create trigger trg_assign_class_code
before insert on public.classes
for each row
execute function public.assign_class_code();





-- Improved trigger function to populate classes.code when missing
CREATE OR REPLACE FUNCTION public.generate_class_code()
RETURNS trigger
LANGUAGE plpgsql
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


DROP TRIGGER IF EXISTS classes_generate_code_trigger ON public.classes;

CREATE TRIGGER classes_generate_code_trigger
BEFORE INSERT ON public.classes
FOR EACH ROW
EXECUTE FUNCTION public.generate_class_code();