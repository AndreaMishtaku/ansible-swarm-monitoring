CREATE ROLE {{ grafana_db_user }} WITH LOGIN PASSWORD '{{ grafana_db_user_password }}';

CREATE DATABASE grafana WITH OWNER = '{{ grafana_db_user }}';