#!/bin/sh

# as the cli does not run as root
# you need to wrap the forgejo command to run as the `git` user
forgejo_cli() {
  su-exec "$USER_UID":"$USER_GID" forgejo "$@"
}

# fix for unable to create chunked upload directory: /data/gitea/data/tmp/package-upload
# https://github.com/go-gitea/gitea/issues/25938
export GITEA_WORK_DIR=/tmp/test-gitea

# waits until database is alive (port 5432 replies)
check_database() {
  nc -z database.vcc.local 5432
  return $?
}

until check_database; do
  echo "Database still unreachable. Retrying in 5 seconds..."
  sleep 5
done

echo "Database check passed."

# prepares database (`forgejo migrate` cli command)
forgejo_cli "migrate"

echo "Migration passed"


# Print Forgejo admin users
echo "Forgejo admin users:"
forgejo_cli admin user list --admin

# creates admin user (if it does not exists already)
if ! forgejo_cli admin user list --admin | grep -q "$FORGEJO_ADMIN"; then
    echo "No admin user found. Creating a new admin user..."

    forgejo_cli admin user create --username "$FORGEJO_ADMIN" --password "$FORGEJO_ADMIN_PASSWORD" --email "forgejo@vcc.local" --admin true

    echo "Admin user created successfully."
fi


# starts forgejo (in background)
/bin/s6-svscan /etc/s6 "$@" &

# waits until forgejo is active (use curl, check for 200 code)
until [ "$(curl -k -s -o /dev/null -w '%{http_code}' localhost:3000)" -eq 200 ]; do 
  echo 'Forgejo...'
  sleep 5
done


# waits until authentication server is alive (use curl, check for 200 code)
until [ "$(curl -k -s -o /dev/null -w '%{http_code}' https://auth.vcc.local/)" -eq 200 ]; do
  echo 'auth.vcc.local...'
  sleep 5
done

# waits until https://auth.vcc.local/realms/vcc is alive (use curl, check for 200 code)
until [ "$(curl -k -s -o /dev/null -w '%{http_code}' https://auth.vcc.local/realms/vcc)" -eq 200 ]; do
  echo 'auth.vcc.local/realms/vcc...'
  sleep 5
done

# waits until self-signed certificate file exists
until [ -f /usr/local/share/ca-certificates/server.crt ]; do
  echo 'Waiting for certificate'
  sleep 1
done

# updates the system list of accepted CA certificates
update-ca-certificates

#
# Download from keycloak forgejo's client id and secret 
#
keycloakAdminToken() {
  curl -k -X POST https://auth.vcc.local/realms/master/protocol/openid-connect/token \
    --data-urlencode "username=${KEYCLOAK_ADMIN}" \
    --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' | jq -r '.access_token'
}
forgejo_client_id=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" https://auth.vcc.local/admin/realms/vcc/clients?clientId=forgejo | jq -r '.[0].id')
forgejo_client_secret=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" -X POST https://auth.vcc.local/admin/realms/vcc/clients/${forgejo_client_id}/client-secret | jq -r '.value')


# Checks if authentication setup exists
if forgejo_cli "admin" "auth" "list" | grep -q "openidConnect"; then
    echo "Authentication setup already exists."
else
    echo "Setting up authentication..."

    # Set up authentication using forgejo admin auth add-oauth
    forgejo_cli "admin" "auth" "add-oauth" "--name" "keycloak" "--auto-discover-url" \
     "https://auth.vcc.local/realms/vcc/.well-known/openid-configuration" \
     "--provider" "openidConnect" \
     "--key" "forgejo" "--secret" "$forgejo_client_secret"
    echo "Authentication setup completed."
fi

echo "All steps passed."

# wait forever
wait