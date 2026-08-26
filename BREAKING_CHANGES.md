# Breaking Changes

## Upcoming releases

### Inline attachments will be listed separately in ticket article API responses

**Who is affected?** Integrations that read inline images from the `attachments` list of ticket article
REST API responses.

Ticket article responses such as `GET /api/v1/ticket_articles/{id}` currently include inline image
attachments in the `attachments` list. In a future release they will no longer be part of that list and
will be returned in a dedicated `inline_attachments` key instead.

⚠️ Update such integrations to read inline images from the new `inline_attachments` key.

**Related issue:** [#6254](https://github.com/zammad/zammad/issues/6254)

### Deleting organizations via API will require the `admin.organization` permission

**Who is affected?** Integrations that call `DELETE /api/v1/organizations/:id` with a token that only
has the `ticket.agent` permission.

The endpoint has historically been permitted for users with only the `ticket.agent` permission. That is
deprecated and will be restricted to `admin.organization` in a future release; agent tokens will then
receive `403 Forbidden`.

⚠️ Switch such integrations to an account with the `admin.organization` permission.

**Related issue:** [#6315](https://github.com/zammad/zammad/issues/6315)

### Import mode will also enable maintenance mode

**Who is affected?** Admins of instances that are left in import mode while users are expected to work
in them.

Import mode was never intended for productive environments. In a future release, an instance running in
import mode will automatically run in maintenance mode as well, which prevents non-admin users from
logging in.

⚠️ Disable import mode before letting users work in the instance.

**Related issue:** [#6237](https://github.com/zammad/zammad/issues/6237)

### `Exceptions::UnprocessableEntity` will be removed

**Who is affected?** Developers of custom packages, patches or add-ons that still reference
`Exceptions::UnprocessableEntity`.

The constant, deprecated since Zammad 7.1, will be removed in Zammad 8.0. Code still using it will then
raise `NameError: uninitialized constant Exceptions::UnprocessableEntity`.

⚠️ Switch to `Exceptions::UnprocessableContent` before updating to Zammad 8.0.

**Related issue:** [#6198](https://github.com/zammad/zammad/issues/6198)

### The deprecated `Rails.application.config.db_*` values will be removed

**Who is affected?** Developers of custom packages, patches or add-ons that read database preferences
from the Rails configuration.

The values deprecated with the removal of MySQL support in Zammad 7.0 will be removed in Zammad 8.0.
Until then they emit a deprecation warning and return the value that always applies to PostgreSQL:

- `Rails.application.config.db_null_byte` — always `false`
- `Rails.application.config.db_case_sensitive` — always `true`
- `Rails.application.config.db_like` — always `ILIKE`
- `Rails.application.config.db_column_array` — always `true`

⚠️ Remove branches that depend on these values from custom code and rely on the PostgreSQL behaviour
instead.

**Related issue:** [#5580](https://github.com/zammad/zammad/issues/5580)

## 7.2

### Dates with a year outside 1 to 9999 are no longer accepted

**Who is affected?** Integrations that write date or datetime values with a year outside the range 1
to 9999, for example a ticket object attribute set via `PUT /api/v1/tickets/:id`.

Date and datetime attributes of all objects are now validated against the year range that
Elasticsearch and RFC 3339 support. Previously such a value was stored, but broke the indexing of the
whole record afterwards, so the affected ticket, user or organization could no longer be found via
search at all. Saving a value like `20026-08-18` now fails with the validation error
`must have a year between 1 and 9999` instead.

Only attributes that are actually changed by a save are validated, so existing records keep their
out-of-range values until the affected attribute is written again.

⚠️ Update integrations that send such values, and correct existing out-of-range dates to make the
affected records findable again.

**Related issue:** [#6306](https://github.com/zammad/zammad/issues/6306)

### Import mode is reported as an issue by the health check

**Who is affected?** Admins of instances that are left in import mode after a migration, and monitoring
setups that alert on the `health_check` endpoint.

Import mode is only meant for bulk imports and migrations, never for productive operation. The
`health_check` endpoint and the "Monitoring" section therefore now report an issue while `import_mode`
is enabled, which turns a previously green monitoring check red. The same applies while
`system_init_done` is still `false`.

⚠️ Disable import mode once a migration is finished, or expect the monitoring check to stay red.

**Related issue:** [#6236](https://github.com/zammad/zammad/issues/6236)

### Knowledge Base answers index a new `publication_state` field

**Who is affected?** Admins of systems with Elasticsearch enabled who update to Zammad 7.2 without
rebuilding the search index.

The "Suggested searches" shortcut menu added to the Knowledge Base search introduced a new
`publication_state` field for `KnowledgeBase::Answer::Translation`, reflecting an answer's current
state (draft, internal, published, archived). Existing indices do not contain the field, so
`publication_state` queries such as `publication_state:draft` return no results.

⚠️ Rebuild the search index after the update: `zammad run rake zammad:searchindex:rebuild`

**Related issue:** [#6142](https://github.com/zammad/zammad/issues/6142)

### Elasticsearch 7 is no longer supported, 8.15 is the new minimum

**Who is affected?** Admins of systems that run an Elasticsearch older than 8.15, including every
Elasticsearch 7 installation.

Elasticsearch 7 has reached its end of life and was deprecated with Zammad 7.1. Support for it was
removed with this release, so the supported range is now **Elasticsearch 8.15 up to, but not
including, 10** — 8.15 and later 8.x releases and every 9.x release. The requirement is enforced
where Zammad reads the server version: the `zammad:searchindex:*` rake tasks, including
`zammad:searchindex:rebuild`, and the "Elasticsearch version" system report abort with
`Version <x> of configured elasticsearch is not supported.`

⚠️ Upgrade the Elasticsearch installation to 8.15 or newer before updating to Zammad 7.2. Note that
Elasticsearch 10 and later are not supported either.

**Related issue:** [#6314](https://github.com/zammad/zammad/issues/6314)

### Local file paths are no longer supported as calendar iCal feed source

**Who is affected?** Admins of instances with a calendar whose iCalendar feed points to a local `.ics`
file instead of an HTTP(S) URL.

Calendars can no longer read their iCal feed from the local file system. Only `http://` and `https://`
URLs are accepted, which is now enforced by a validation of the `ical_url` attribute. Calendars that
still hold a local path stop syncing their public holidays, and saving them fails until the value is
changed.

⚠️ Host the `.ics` file on an HTTP(S) server and update the calendar's iCalendar feed accordingly.

**Related issue:** [#6316](https://github.com/zammad/zammad/issues/6316)

### The deprecated `es-ca` locale was inactivated

**Who is affected?** Admins of instances with users or a Knowledge Base still set to the deprecated
Catalan locale `es-ca`.

The `es-ca` locale, deprecated since Zammad 7.0 in favour of the correct code `ca`, is no longer
offered for selection. Users still set to it are migrated to `ca` automatically. Knowledge Base locales
referencing `es-ca` are left untouched, because changing the locale of a Knowledge Base changes its
public URLs.

⚠️ Migrate a Knowledge Base that still uses the deprecated locale manually:

```ruby
zammad run rails r "KnowledgeBase::Locale.find_by(system_locale: Locale.find_by(locale: 'es-ca'))&.update!(system_locale: Locale.find_by(locale: 'ca'))"
```

**Related issue:** [#5886](https://github.com/zammad/zammad/issues/5886)

### The default Content-Security-Policy became stricter

**Who is affected?** Setups that embed the Zammad web interface in an `<iframe>` on a different origin.

A `frame-ancestors 'self'` directive was added to the default `Content-Security-Policy` response
header. Setups that previously re-enabled embedding by overriding the `X-Frame-Options` header at the
reverse proxy are blocked again by it.

⚠️ To allow embedding from trusted origins, adjust the `frame-ancestors` directive of the
`Content-Security-Policy` response header at the reverse proxy as well.

**Related issue:** [#6087](https://github.com/zammad/zammad/issues/6087)

## 7.1

### Elasticsearch 7 was deprecated

**Who is affected?** Admins of systems that run Elasticsearch 7.

Elasticsearch 7 has reached its end of life and was deprecated with this release. It is still
supported in Zammad 7.1, but a later release requires **Elasticsearch 8** or later.

⚠️ Plan the upgrade of the Elasticsearch installation to version 8 or later.

**Related issue:** [#6314](https://github.com/zammad/zammad/issues/6314)

### `Exceptions::UnprocessableEntity` was deprecated in favour of `Exceptions::UnprocessableContent`

**Who is affected?** Developers of custom packages, patches or add-ons that reference
`Exceptions::UnprocessableEntity`.

The exception was renamed to `Exceptions::UnprocessableContent`, following the rename of the HTTP
status code itself. The old constant still resolves, but it is deprecated and emits a deprecation
warning.

⚠️ Replace references to `Exceptions::UnprocessableEntity` with `Exceptions::UnprocessableContent`.

**Related issue:** [#6198](https://github.com/zammad/zammad/issues/6198)

## 7.0

### MySQL support was removed and database-related settings were deprecated

**Who is affected?** Admins of instances still running on MySQL or MariaDB, and developers of custom
packages that read database preferences from the Rails configuration.

After a long period of deprecation, support for the MySQL and MariaDB databases was removed —
PostgreSQL is the only supported database. Alongside, the following configuration values were
deprecated and will be removed with Zammad 8.0:

- `Rails.application.config.db_null_byte`
- `Rails.application.config.db_case_sensitive`
- `Rails.application.config.db_like`
- `Rails.application.config.db_column_array`

⚠️ Migrate a MySQL or MariaDB installation to PostgreSQL _before_ updating to Zammad 7.0, following the
[migration documentation](https://docs.zammad.org/en/latest/appendix/migrate-to-postgresql.html).

**Related issue:** [#5580](https://github.com/zammad/zammad/issues/5580)

### Fulltext search ignores diacritics by default

**Who is affected?** Admins of systems with Elasticsearch enabled, especially those who rely on
searches matching diacritics exactly.

The global search and other fulltext searches now use the Elasticsearch
[asciifolding](https://github.com/zammad/zammad/pull/5537) analyzer, which is enabled by default:
searching for `Munchen` matches `München` and vice versa. With the analyzer disabled, searching for
`Munchen` does not match `München`.

The new behaviour only applies to a rebuilt search index. To keep the previous behaviour instead,
disable the `es_asciifolding` setting — no rebuild is needed in that case:
`zammad run rails r "Setting.set('es_asciifolding', false)"`

Thanks to [Jano Suchal](https://github.com/jsuchal) for the contribution.

⚠️ Rebuild the search index after the update: `zammad run rake zammad:searchindex:rebuild`

**Related issue:** [#3782](https://github.com/zammad/zammad/issues/3782)

### nginx configuration requires `proxy_http_version 1.1`

**Who is affected?** Admins of installations that use an nginx reverse proxy with a configuration file
from an earlier Zammad version.

The nginx configuration shipped with Zammad sets `proxy_http_version 1.1;` for the main location as
well, so that all proxied requests use HTTP/1.1 like the websocket and cable locations already did.
Existing configuration files are not changed by the update.

⚠️ Add the line to the `location /` section of the nginx configuration:

```diff
   location / {
+    proxy_http_version 1.1;
     proxy_set_header Host $http_host;
```

**Related issue:** [#6317](https://github.com/zammad/zammad/issues/6317)

### Assigning the same organization as primary and secondary is no longer allowed

**Who is affected?** Integrations that write user records via API and set the same organization as both
primary and secondary organization.

The same organization can no longer be a user's primary and secondary organization at the same time.
Such requests now fail with a validation error, and an automatic migration brings existing user data
into a consistent state during the update.

⚠️ Update API calls that put users into this state before updating.

**Related issue:** [#5254](https://github.com/zammad/zammad/issues/5254)

### The Catalan locale moved to the correct `ca` locale code

**Who is affected?** Admins of instances with users using the Catalan locale, and especially those with
a Catalan Knowledge Base.

The previously available Catalan locale used the wrong internal locale code `es-ca` and was deprecated;
it will be removed in a future release. A new Catalan locale with the correct code `ca` is available,
and a migration switches the language preference of all Catalan user profiles to the new
"Catalan (Català)" locale.

Knowledge Base locales are not migrated automatically, because changing the locale of a Knowledge Base
changes its public URLs.

⚠️ Migrate a Knowledge Base using the Catalan language at your own pace:

```ruby
zammad run rails r "KnowledgeBase::Locale.find_by(system_locale: Locale.find_by(locale: 'es-ca'))&.update!(system_locale: Locale.find_by(locale: 'ca'))"
```

**Related issue:** [#5886](https://github.com/zammad/zammad/issues/5886)

### The Slack integration was removed

**Who is affected?** Admins of instances that still use the Slack integration.

The Slack integration was removed from the codebase; existing configurations stop working and are not
migrated automatically. Everything the integration did can be achieved with webhooks, see
[Slack notifications via webhook](https://admin-docs.zammad.org/en/latest/manage/webhook/examples/slack-notifications.html).

⚠️ Recreate existing Slack notifications as webhooks, if not already done.

**Related issue:** [#5583](https://github.com/zammad/zammad/issues/5583)

### The Twitter integration was removed

**Who is affected?** Admins of instances that still have a Twitter/X channel configured.

The Twitter integration was removed due to problems with the API licensing, and there is no replacement
available. Existing tickets and articles stay accessible, but no messages are fetched or sent any more.

**Related issue:** [#5581](https://github.com/zammad/zammad/issues/5581)

## 6.5.2

The following breaking changes occurred due to a security fix.

### PGPController parameter name changes

The field `key` of the "key add" endpoint was renamed to `private_key`.

### SMIMEController parameter name changes

- The field `data` of the "certificate add" endpoint was renamed to `certificate`.
- The field `data` of the "private key add" endpoint was renamed to `private_key`.

### HttpLogsController access control

Logging subsystem (`HttpLog`) API access control is now more fine grained.
In the past, any `admin.*` permission was sufficient to access this data.
Now, only the relevant parts can be accessed (e.g. `admin.webhook`)

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

The **count search** (e.g. `/ticket/search?only_total_count=true`) is a new feature.

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

Additionally, existing custom group object attributes named _name_last_ and _parent_id_ will be renamed too, by adding
an underscore in front (_\_name_last_ and _\_parent_id_). This is due to these attributes now being part of the group
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
