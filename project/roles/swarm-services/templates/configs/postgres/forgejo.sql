CREATE ROLE {{ forgejo_db_user }} WITH LOGIN PASSWORD '{{ forgejo_db_user_password }}';

CREATE DATABASE forgejo WITH OWNER = '{{ forgejo_db_user }}';