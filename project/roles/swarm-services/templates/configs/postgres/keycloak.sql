CREATE ROLE {{ keycloak_db_user }} WITH LOGIN PASSWORD '{{ keycloak_db_user_password }}';

CREATE DATABASE keycloak WITH OWNER = '{{ keycloak_db_user }}';