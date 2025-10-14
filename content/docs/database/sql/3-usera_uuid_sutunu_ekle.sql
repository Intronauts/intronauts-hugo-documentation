ALTER TABLE users
ADD COLUMN auth_user_id uuid REFERENCES auth.users(id) UNIQUE;
