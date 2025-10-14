create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
as $$
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();
