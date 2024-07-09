#!/bin/sh

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

# wait until self-signed certificate file exists
until [ -f /usr/local/share/ca-certificates/server.crt ]; do
  echo 'Waiting for certificate'
  sleep 1
done

# update the system list of accepted CA certificates
update-ca-certificates

#
# Download from keycloak grafana's client id and secret 
#
keycloakAdminToken() {
  curl -k -X POST https://auth.vcc.local/realms/master/protocol/openid-connect/token \
    --data-urlencode "username=${KEYCLOAK_ADMIN}" \
    --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' | jq -r '.access_token'
}

grafana_client_id=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" https://auth.vcc.local/admin/realms/vcc/clients?clientId=grafana | jq -r '.[0].id')
grafana_client_secret=$(curl -k -H "Authorization: Bearer $(keycloakAdminToken)" -X POST https://auth.vcc.local/admin/realms/vcc/clients/${grafana_client_id}/client-secret | jq -r '.value')

# setup authentication
export GF_AUTH_GENERIC_OAUTH_CLIENT_ID="grafana"
export GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET="${grafana_client_secret}"
export GF_AUTH_GENERIC_OAUTH_SCOPES="openid profile email roles"
export GF_AUTH_GENERIC_OAUTH_ENABLED=true
export GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP=true
export GF_AUTH_GENERIC_OAUTH_NAME=Keycloak
export GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN=true 
export GF_AUTH_GENERIC_OAUTH_AUTH_URL=https://auth.vcc.local/realms/vcc/protocol/openid-connect/auth
export GF_AUTH_GENERIC_OAUTH_TOKEN_URL=https://auth.vcc.local/realms/vcc/protocol/openid-connect/token
export GF_AUTH_GENERIC_OAUTH_API_URL=https://auth.vcc.local/realms/vcc/protocol/openid-connect/userinfo
export GF_AUTH_GENERIC_OAUTH_TLS_SKIP_VERIFY_INSECURE=true


# https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/
# In startation of the project only one user exit and his default role is viewer, to test other roles in grafana we need to config in Keycloak UI roles Admin and Editor
# For the moment tested only with as admin and viewer
export GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH="contains(roles[*], 'Admin') && 'Admin' || contains(roles[*], 'Editor') && 'Editor' || 'Viewer'"

export GF_SERVER_DOMAIN=mon.vcc.local
export GF_SERVER_ROOT_URL=https://mon.vcc.local

# relaunch original
exec /run.sh "$@"
