#/bin/sh

# if you are running both dashboard and UAA servers locally,
# use this script to quickly bootstrap UAA with the resources required by dashboard,
# including one user account for testing purposes

# usage: ./setup_uaa.sh <uaa-url> <uaa's admin client secret>
# eg. ./setup_uaa.sh http://localhost:8081/uaa adminsecret

# if you are using a UAA running locally on your box, the secret for the admin client is 'adminsecret' (unless you changed it in the UAA config)
# if you are using a UAA running on a dev instance, the secret is configured in your manifest file under the property 'uaa.admin.client_secret'

uaac target $1
uaac token client get admin --secret $2
uaac client add dashboard --access_token_validity 5000 --refresh_token_validity 10000 --secret secret --authorized_grant_types "authorization_code,refresh_token" --authorities "uaa.resource,tokens.read,tokens.write" --scope "openid,dashboard.user"
uaac client add dashboard_admin --access_token_validity 5000 --refresh_token_validity 10000 --secret somesecret --authorized_grant_types "client_credentials" --authorities "scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write,uaa.admin" --scope "uaa.none"
uaac token client get dashboard_admin --secret somesecret
uaac group add openid
uaac group add dashboard.user
uaac user add duser1 --email user1@dashboard.org --given_name user1 --family_name test --password pwd1
uaac member add openid duser1
uaac member add dashboard.user duser1

echo
echo "<================================>"
echo "created test user account"
echo "username: duser1, password: pwd1"
uaac user get duser1
echo "<================================>"