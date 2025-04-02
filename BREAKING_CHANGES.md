# Breaking Changes

## 6.5

### Textarea object manager attribute values

When used as [template variables](https://admin-docs.zammad.org/en/latest/misc/variables.html), the `textarea` object
manager attributes are now replaced with an HTML representation of their value. This is a consequence of a bugfix for
[#5330](https://github.com/zammad/zammad/issues/5330), which expects newline characters are respected for these
attributes in all contexts, including the rich text article body. The administrators are advised to check for usage of
such variables in their objects (e.g. triggers, text modules, etc), by making sure the new value type will not break
their existing workflows.

### Changes to search API endpoints

All search endpoints (`/:object/search`) have been revised, extended and unified. This will also result in breaking
changes in the existing endpoints. Be prepared that the structure in the responses may change (have a look at the
[API documentation](https://docs.zammad.org/en/latest/api/intro.html) where you can find updated examples).

The **standard search** (e.g. `/ticket/search`) returned a hash for some objects, such as the ticket. This will no
longer be the case.

The structure for the **expanded search** (e.g. `/ticket/search?expand=true`) remains the same.

The structure of the **full search** (e.g. `/ticket/search?full=true`) remains the same, but is supplemented by a
`total_count`, which counts all results.

Some objects used an object-related hash key, such as `ticket_ids`. This is now always `record_ids`.

The **count search** (e.g. `/ticket/search?only_total_count=true`) is a  new feature.

### API performance optimization of asset return data

Most API endpoints have some parameter called full=true which returns the data with all related assets.
[In order to improve the front end performance](https://github.com/zammad/zammad/issues/5495), we decided to reduce
certain assets which are populated on the login. Normally this parameter is mainly used to show additional data to our
legacy app. We have some static data which rarely changes and are currently added on every object like:

- Ticket Priority
- Ticket State
- Ticket Group
- Role

This information will not be added in the future any more when requesting a user or a ticket. If you have an external
script which is for example requesting tickets with assets and using the group name or some role information out of the
assets, you need to adjust your code to do either:

1. Do a separate request to the object specific endpoint e.g. `/api/v1/groups`
2. Get the global assets before requesting the ticket e.g. `/api/v1/signshow`

### Limit to one `merged` state

It will not be possible to have more than one state of the `merged` type. Additional states will be changed to the
`closed` type automatically with that update. If you want to prevent that, make sure to only have one state of the type
`merged` before you make an update to the **next release**.

### `APP_RESTART_CMD` and Zammad self-shutdown

Zammad will now cause a self-shutdown of all running processes after certain configuration changes by default. It is the
responsibility of the controlling process manager (e.g. Docker, Kubernetes, systemd) to bring them up again by way of a
proper restart policy. This is the default for vanilla Docker, Kubernetes or Package deployments of Zammad.

The previous environment variable `APP_RESTART_CMD` is not supported any more.

For systems where this behaviour is not wanted, it can be disabled by setting the Zammad Setting `auto_shutdown` to
`false`.

### `ZAMMAD_SESSION_JOBS_CONCURRENT` was renamed to `ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS`

The background worker shutdown handling [was improved](https://github.com/zammad/zammad/commit/b5141f6670920bd960ab4269dc80b1d09d7c8eb6)
to be more graceful and allow processes to finish first.

Together with this change, the session jobs logic that computes the ticket overviews was moved to be
a first-class background service. Therefore the name of its configuration variable changed
from `ZAMMAD_SESSION_JOBS_CONCURRENT` to `ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS`. The old one will continue
to work for now, but emit a deprecation warning.

### nginx configuration update

Please update your nginx configuration file to insert the line `proxy_set_header Host $http_host;` to the `location /ws`
and `location /cable` sections like in the example below:

```diff
@@ -38,10 +38,11 @@ server {
   # legacy web socket server
   location /ws {
     proxy_http_version 1.1;
     proxy_set_header Upgrade $http_upgrade;
     proxy_set_header Connection "Upgrade";
+    proxy_set_header Host $http_host;
     proxy_set_header CLIENT_IP $remote_addr;
     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_set_header X-Forwarded-Proto $scheme;
     proxy_read_timeout 86400;
     proxy_pass http://zammad-websocket;
@@ -50,10 +51,11 @@ server {
   # action cable
   location /cable {
     proxy_http_version 1.1;
     proxy_set_header Upgrade $http_upgrade;
     proxy_set_header Connection "Upgrade";
+    proxy_set_header Host $http_host;
     proxy_set_header CLIENT_IP $remote_addr;
     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_set_header X-Forwarded-Proto $scheme;
     proxy_read_timeout 86400;
     proxy_pass http://zammad-railsserver;
```

## 6.4

### JavaScript Package Manager Change

This version changes the JavaScript toolchains to be based on pnpm rather than yarn. This is only relevant for source
installations, where you need to provide a recent version of pnpm in order to run the assets:precompile command.

### Changed CSV-format for user/organization import/export

We slightly changed the format of the CSV-files you use for importing/exporting users and organizations. If you somehow
do that in an automated process via our REST-API, you will need to review that process before updating to Zammad 6.4.
Check the details in our documentation.

## 6.3

### Knowledge base granular permissions setup changed

Zammad allows configuration of a granular permission structure for knowledge base access. Previous Zammad versions
allowed to misconfigure this in cases of allowing agents editor access to only some, but not all categories: it was
possible to grant editor access at a higher level in the category tree, and then restricting access to reader or none
for sub-categories. This was not effective due to permission inheritance.

Such a misconfiguration is no longer possible in Zammad 6.3. Administrators with existing knowledge base granular
permission structures should review their configuration to ensure that at top-level only reader access is granted, and
editor access only for the relevant sub-categories.

### Permissions for Ticket State and Priority REST-API

With this release, we will introduce new permissions for the ticket state and priority management. It will no longer be
possible to access the corresponding REST-API with "admin.object" permission. Existing roles and/or access tokens that
are used for these specific REST-API endpoints need to be updated to include the new permissions ("admin.ticket_state"
and "admin.ticket_priority").

## 6.2

### Default SSL Verification in UserAgent

The default SSL behaviour of the _UserAgent_ class in Zammad was changed. Previously, it would not perform SSL
verification unless explicitly requested. Now, it will perform SSL verification unless explicitly rejected.

This may cause issues on systems with custom addons using the _UserAgent_ to access other systems via _https_, if these
systems have self-signed certificates. In such cases, these certificates or the CA certificates used for their
generation should be uploaded via the new _SSL Certificates_ management screen of Zammad. Alternatively, custom code can
be adjusted to pass _verify_ssl: false_ to _UserAgent_ calls to restore the old behaviour.

### Oversized Email Handling

The handling of emails larger than the size limit changed. Previously, Zammad would send a reply and save the emails
locally in _var/spool/oversized_email_ (if the setting _postmaster_send_reject_if_mail_too_large_ is _true_). No ticket
is created in this case.

The new behaviour is that Zammad sends the reply like before, but no longer creates files for these emails locally -
they are discarded.

### Reserved Delimiter in Group Name

The double colon (`::`) is now a reserved delimiter in the group name, in order to facilitate nested structure for
complex hierarchies. Previously, it was possible to freely use this set of characters as part of the group name, but
now it is forbidden.

On existing systems, the group names that contain the now reserved delimiter will be renamed, with sets of double colons
being replaced by a dash (`-`) during the migration process.

Additionally, existing custom group object attributes named _name\_last_ and _parent\_id_ will be renamed too, by adding
an underscore in front (_\_name\_last_ and _\_parent\_id_). This is due to these attributes now being part of the group
model, requiring dedicated table columns under the reserved names.

### Disallowed URL Values in User's Name Attributes

Text values that resemble valid URI addresses are now disallowed for user's first and last name attributes. Previously,
it was possible to save any text in these attributes. The administrators should take a note of this change since it can
have an impact on existing user data.

No migration will be run for existing users on update to Zammad 6.2. In case there are user records that contain URLs in
their name attributes, they will be sanitized during subsequent updates. No manual action from administrator will be
required, as the URI scheme or protocol will be automatically stripped from offending values.

## 6.1

### New Organization Attribute `vip`

Zammad 6.1 creates a new `vip` attribute for organizations. For systems with previously created `vip` attributes, there
is special caution needed. In case of `boolean` attributes, Zammad will adjust them to the new settings and keep using
them. For attributes of other types, Zammad will rename the existing attribute to `_vip` and add a new `vip` boolean
attribute. This may cause issues if the previous attribute was used in other parts of the system, e.g. Triggers.
In such cases, the relevant configurations must be reviewed and adjusted.

### Support for the Unicorn Web Server is removed

It seems that the Unicorn Web Server is no longer really used with Zammad. Therefore, we have decided to remove it with
Zammad 6.1 after it was deprecated in Zammad 6.0.

## 6.0

### nginx configuration update

When updating to Zammad 6.0 from a previous version, the system administrator needs to add some content to the
configuration of the reverse proxy.

Example for Apache:

```apache
ProxyPass /cable ws://127.0.0.1:3000/cable
```

Example for nginx:

```nginx
location /cable {
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "Upgrade";
  proxy_set_header CLIENT_IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_read_timeout 86400;
  proxy_pass http://zammad-railsserver;
}
```

This is required to enable the new Rails Action Cable based realtime communication. You can find more details about this
change at [this github commit](https://github.com/zammad/zammad/commit/d873b2a04bd172b90573170bc2d1d4ee75a47f02).

### Mandatory Redis Dependency

Starting with Zammad version 6.0, Redis is required to run Zammad. For package-based installations, the new dependency
is automatically installed in the system during the update.

Note: Hosted customers do not need to take any further action regarding this change!

### Health Check API Changes

Starting with Zammad 6.0, the "health check" monitoring API at `/api/v1/monitoring/health_check` will no longer echo the
used authentication token in the response payload.

### Excel Export Format Change

Starting with Zammad version 6.0, all Excel exports will be exported exclusively in xlsx format. The original xls format
will no longer be supported.

### Storage location of unprocessable/oversized emails

Zammad stores emails that were unprocessable or rejected due to size constraints in the file system. The location of
such emails changed from `tmp/unprocessable_mail` and `tmp/oversized_mail` to `var/spool/unprocessable_mail` and
`var/spool/oversized_mail` within the `/opt/zammad` directory. Existing emails are automatically moved to the new
location.

### Naming change in Token model and EmailAddress model

The `token` model is used to store access tokens and had field names which may have caused confusion for developers
using them. Therefore, the field previously called `name:` now has the correct identifier `token:` (as it stores the
actual token value), and the field previously called `label:` is now called `name:` for better consistency with other
models. The `EmailAddress` model is used to information about email addresses Zammad receives mail for. For consistency
reasons, its `realname:` field is now called `name:`.

This means that the attribute via the REST API also changes: from token or realname to "name".

### Docker image zammad-docker was archived

The repository [zammad-docker](https://github.com/zammad/zammad-docker) was intended for testing / development purposes
only. This repository was archived and will receive no further updates. Please use
[zammad-docker-compose](https://github.com/zammad/zammad-docker-compose) instead.
