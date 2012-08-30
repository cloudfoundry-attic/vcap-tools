========================================
Securing Dashboard using Oauth2 and UAA
========================================

.. contents:: Table of Contents

Purpose of this document
=========================
This document outlines how the resources on the dashboard_v2 java-based webapp server are secured using OAuth2_ and UAA_ .
If you are a developer who needs to run a dashboard_v2 server instance LOCALLY, please continue reading to learn how to setup dashboard to work with a UAA_ server.
SREs or anyone looking to bosh deploy the dashboard_v2 server and have it work with a UAA_ server instance, please look for a different document - tools/dashboard_v2/docs/Dashboard-UAA-Bosh.rst

Recommended (but not required) reading in order to be able to follow the rest of this document: `OAuth2 Roles`_ and `OAuth2 Authorization Code Grant`_ .

.. _OAuth2: http://tools.ietf.org/html/draft-ietf-oauth-v2
.. _OAuth2 Roles: http://tools.ietf.org/html/draft-ietf-oauth-v2-31#section-1.1
.. _UAA: http://github.com/cloudfoundry/uaa
.. _OAuth2 Authorization Code Grant: http://tools.ietf.org/html/draft-ietf-oauth-v2-31#section-4.1

UAA and the uaac cli
=====================
In order to successfully access the resources on dashboard, you need a running instance of the UAA_. There are a couple of ways to achieve this -

- Use the UAA_ running on your dev-instance.
- Startup a UAA_ server on your own box.

uaac is an easy-to-use CLI for the UAA_ APIs. Regardless of which UAA_ server you choose to use (either from your dev-instance or from your localhost), you need the uaac_cli to proceed further.

Getting the uaac cli
---------------------
As of this writing, the uaac cli gem is not available in any public gem repo. Get the code directly from git as follows - ::

    $ git clone git@github.com:cloudfoundry/uaa.git
    $ cd uaa; mvn install
    $ cd gem; bundle install; export PATH="$PATH;`pwd`/bin"; cd ../
    $ uaac -h

Using a local UAA with uaac
===========================
The dashboard web-app is configured by default to work with a locally running UAA_ server @ http://localhost:8081/uaa . A couple of things to note when running UAA_ locally -

- The UAA server is bootstrapped by default with 1 OAuth2_ client - 'admin', and 1 user - 'marissa'.
- It uses an in-memory database for storing clients, users and tokens. Hence the following configurations you do using uaac will be lost every time you restart UAA_. You can avoid this by using the alternative config-file approach described below.

Starting up the UAA server
---------------------------
Pre-requisites: Maven 3, install instructions at http://maven.apache.org/download.html ::

    $ mvn -v
      Apache Maven 3.0.3 (r1075438; 2011-02-28 09:31:09-0800)

Assuming you have the above setup, do the following - ::

    $ cd uaa; mvn tomcat:run -Dmaven.tomcat.port=8081 > uaa.log 2>&1 &

The next sections address how you can configure the UAA_ server with the OAuth2_ clients and user accounts that you would need to successfully authenticate and login to dashboard.

Managing OAuth2 clients with uaac
----------------------------------
The dashboard needs 2 OAuth2 clients registered with the UAA_ server, use the following commands to create them using uaac - ::

    $ uaac target http://localhost:8081/uaa
    $ uaac client token get admin --secret adminsecret
    ('adminsecret' is the default secret that the bootstrapped admin client is configured with.)
    $ uaac client add dashboard         --access_token_validity 5000 --refresh_token_validity 10000 --secret secret     --authorized_grant_types "authorization_code,refresh_token" --authorities "uaa.resource,tokens.read,tokens.write"                                    --scope "openid,dashboard.user"
    $ uaac client add dashboard_admin   --access_token_validity 5000 --refresh_token_validity 10000 --secret somesecret --authorized_grant_types "client_credentials"               --authorities "scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write" --scope "scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write"

You can now use the dashboard_admin client to update the client configuration for both the dashboard and dashboard_admin clients - ::

    $ uaac token client get dashboard_admin -s somesecret
    (first login as the dashboard_admin client to manage and administer clients)
    $ uaac client update dashboard --refresh_token_validity 24000 --access_token_validity 6000   // increase the lifetime of refresh_token and access_token

and so on.

Managing users with uaac
-------------------------
Now that you have a dashboard_admin OAuth2_ client with scim.read and scim.write scopes, you can use that client to manage (add, get, delete) users as follows - ::

    $ uaac client token get dashboard_admin --secret somesecret
    (first login as the dashboard_admin client to manage and administer clients)
    $ uaac user add --email user1@test.org --given_name user1 --family_name test --password pwd1 --groups "openid,dashboard.user"
    $ uaac user add --groups "openid,dashboard.user" --password pwd2
    (When promoted, choose a username for the user)
    $ uaac user get <chosen username>

Alternative approach: Bootstrapping UAA server with a config file
------------------------------------------------------------------
There is an alternative approach to adding the 2 OAuth2_ clients and users using uaac as described above - supplying an appropriate config file for the UAA_ to use while starting up. Steps -

- Set this system variable - CLOUD_FOUNDRY_CONFIG_PATH - to a directory that would contain the config file.
- The config file itself should be named 'uaa.yml' and should contain the following YML properties (equivalent of all the uaac commands we used above to create clients and users) - ::

        oauth:
          clients:
            dashboard:
              id: dashboard
              secret: secret
              authorized-grant-types: authorization_code,refresh_token
              scope: openid,dashboard.user
              authorities: uaa.resource,tokens.read,tokens.write
            dashboard_admin:
              id: dashboard_admin
              secret: somesecret
              authorized-grant-types: client_credentials
              scope: scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write
              authorities: scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write
        scim:
          users:
          - user1|pwd1|user1@test.org|user1|test|openid,dashboard.user
          - user2|pwd2|openid,dashboard.user
          - <more accounts as per your need>

- Now startup the UAA_ using the instructions given above. The UAA_ will be bootstrapped with the dashboard clients and users.

Configuring Dashboard web-app to work with your local UAA
----------------------------------------------------------
Once you have a UAA_ server up and running, with the clients and user accounts that dashboard needs, the rest is straightforward.

The file : dashboard_v2/src/main/resources/application.properties has various properties relating to the UAA_. Among them, the following - ::

        uaa.client.id = dashboard
        uaa.client.secret = secret

should match the 'id' and 'secret' that you chose above for the 'dashboard' OAuth2_ client.

That's it, you should be set. Startup the dashboard webapp server as you usually do. Enter 'http://localhost:8080/dashboard/dashboard.html' or any other valid resource URL on the dashboard, and the following should happen -

- If this is the first ever request you are trying after starting up the servers, you should be redirected to the login page on UAA_.
- Enter username/password for a user account that you either created with uaac or bootstrapped using a config property.
- On submitting the credentials, you should be authenticated and redirected back to the dashboard resource that you originally tried to access.
- To logout of dashboard, go to http://localhost:8080/dashboard/logout . Note that this will not log you out of the UAA_ server, hence the next time you try to access a page on dashboard, you will be shown the login page only if your existing token has expired. To logout of UAA_ as well, go to http://localhost:8081/logout.do .

Once you have logged in, you should not be required to login again for 'X' amount of time, where 'X' is the value you chose for 'refresh_token_validity' while configuring the 'dashboard' OAuth2_ client. As in the example shown above, you can use the dashboard_admin client to change this value to be longer or shorter, whichever suits your need.

Using your dev-instance UAA with uaac
======================================
If you do not want to run a UAA_ server locally, you could use the one available on your dev-instance instead. A few things to note about the UAA_ server running on your dev-instance -

- Unlike on your locahost, the dev-instance UAA_ uses a database to store client configurations, user accounts etc. This means that the following configurations you do is not lost across server restarts and bosh deploys. However if you delete a bosh deployment and do a new deployment from scratch, the data will be lost.
- Assuming your dev-instance has a domain like 'cfXX.dev.las01.vcsops.com', the UAA_ server is available at http://uaa.cfXX.dev.las01.vcsops.com/ , unless you have manually changed your manifest file to make the UAA_ run elsewhere.
- Like on your localhost, the UAA_ server in your dev-instance is also bootstrapped with an 'admin' OAuth2_ client.
- Like on your localhost, the dev-instance UAA_ server also needs to be configured with the OAuth2_ clients and users that the dashboard web-app needs to function correctly.

Refer to the 'Managing OAuth2 clients with uaac' and 'Managing users with uaac' sections above for instructions, with 2 minor changes -

#. Target uaac to use your dev-instance UAA_ server instead of localhost, i.e ::

    $ uaac target http://uaa.cfXX.dev.las01.vcsops.com

#. When logging in as the 'admin' client to create the dashboard OAuth2_ clients, the secret to use is NOT 'adminsecret' (that is only on your localhost). On your dev-instance, this secret is configured in your manifest file (devXX.yml) under the property 'uaa.admin.client_secret'.

The rest of the instructions for configuring UAA_ remain the same.

An alternative to using uaac cli to configure UAA_ is to add properties to your manifest, so that the UAA_ server on your dev instance is bootstrapped with the clients and users you need. To do this, add the following to your manifest file (devXX.yml) - ::

        uaa:
          clients:
            dashboard:
              id: dashboard
              secret: secret
              authorized-grant-types: authorization_code,refresh_token
              scope: openid,dashboard.user
              authorities: uaa.resource,tokens.read,tokens.write
            dashboard_admin:
              id: dashboard_admin
              secret: somesecret
              authorized-grant-types: client_credentials
              scope: scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write
              authorities: scim.read,scim.write,tokens.read,tokens.write,clients.read,clients.write
          scim:
            users:
            - user1|pwd1|user1@test.org|user1|test|openid,dashboard.user
            - user2|pwd2|openid,dashboard.user
            - <more accounts as per your need>

and re-deploy using bosh to upgrade the UAA_ server.

Configuring Dashboard web-app to work with your dev-instance UAA
-----------------------------------------------------------------
Once you have used uaac to add the clients and users you need OR changed your manifest and re-deployed the UAA_ server, do the following changes to your local file: dashboard_v2/src/main/resources/application.properties -

- Ensure that uaa.client.secret = <whatever secret you chose for the dashboard client using uaac or manifest file property>
- Replace all properties that use a 'http://localhost:8081/' URL to access an end-point on UAA_, to use 'http://uaa.cfXX.dev.las01.vcsops.com/' instead.

That's it, you should be set. Startup the dashboard webapp server as you usually do. Enter 'http://localhost:8080/dashboard/dashboard.html' or any other valid resource URL on the dashboard, and the following should happen -

- If this is the first ever request you are trying after starting up the servers, you should be redirected to the login page on UAA_.
- Enter username/password for a user account that you either created with uaac or bootstrapped using a config property.
- On submitting the credentials, you should be authenticated and redirected back to the dashboard resource that you originally tried to access.
- To logout of dashboard, go to http://localhost:8080/dashboard/logout . Note that this will not log you out of the UAA_ server, hence the next time you try to access a page on dashboard, you will be shown the login page only if your existing token has expired. To logout of UAA_ as well, go to http://uaa.cfXX.dev.las01.vcsops.com/logout.do .

Once you have logged in, you should not be required to login again for 'X' amount of time, where 'X' is the value you chose for 'refresh_token_validity' while configuring the 'dashboard' OAuth2_ client. As in the example shown above, you can use the dashboard_admin client to change this value to be longer or shorter, whichever suits your need.
