# Change Log

## [1.5.1](https://github.com/zammad/zammad/tree/1.5.1) (2017-09-11)
[Full Changelog](https://github.com/zammad/zammad/compare/1.5.0...1.5.1)

**Fixed bugs:**

- Broken email with huge pdf inline \(lead to huge article body with bigger then 7MB\) is blocking rendering of web app [\#1390](https://github.com/zammad/zammad/issues/1390) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Macro/Bulk action: Cannot transfer more than one ticket to agent [\#1107](https://github.com/zammad/zammad/issues/1107) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Duplicates in Caller Log \(Sipgate\) [\#1253](https://github.com/zammad/zammad/issues/1253) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Time Accounting not showing all tickets, time is missing completly of specific ticket [\#1315](https://github.com/zammad/zammad/issues/1315) [[bug](https://github.com/zammad/zammad/labels/bug)]
- 'Access-Control-Allow-Origin' error when submitting web form. [\#1318](https://github.com/zammad/zammad/issues/1318) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket Hook Position between RE: and the ticket subject [\#1369](https://github.com/zammad/zammad/issues/1369) [[bug](https://github.com/zammad/zammad/labels/bug)]
- OTRS Import fails with "incompatible character encodings: ASCII-8BIT and UTF-8 \(Encoding::CompatibilityError\)" [\#1349](https://github.com/zammad/zammad/issues/1349) [[bug](https://github.com/zammad/zammad/labels/bug)]
- DynamicFields imported from OTRS are mandatory, hidden and stop input forms from submitting [\#1175](https://github.com/zammad/zammad/issues/1175) [[bug](https://github.com/zammad/zammad/labels/bug)]
- handling of incoming mails seems strange / customer is not set correctly [\#1351](https://github.com/zammad/zammad/issues/1351) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP group retrieval fails for objectClass 'organization' [\#1347](https://github.com/zammad/zammad/issues/1347) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zendesk import fails for deleted tickets [\#1161](https://github.com/zammad/zammad/issues/1161) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing replacement of Config and Current User objects in text modules and signatures [\#1290](https://github.com/zammad/zammad/issues/1290) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Chat widget error "chat notice || Translation 'es' needed!" [\#1267](https://github.com/zammad/zammad/issues/1267) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Tel Protocol Link for Telephone and Mobile [\#991](https://github.com/zammad/zammad/issues/991) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Don't use Proxy on localhost Address. [\#1292](https://github.com/zammad/zammad/issues/1292) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Race condition if agents merge ticket at same time but in different directions. [\#1216](https://github.com/zammad/zammad/issues/1216) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Block escape key when creating / editing text modules [\#1291](https://github.com/zammad/zammad/issues/1291) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Problem with cyrillic letters in name of overviews. [\#1151](https://github.com/zammad/zammad/issues/1151) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Backslash issue [\#1230](https://github.com/zammad/zammad/issues/1230) [[bug](https://github.com/zammad/zammad/labels/bug)]
- OTRS import fails for attributes containing null bytes strings on PostgreSQL [\#1200](https://github.com/zammad/zammad/issues/1200) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket create state after OTRS import is wrong [\#1184](https://github.com/zammad/zammad/issues/1184) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Lost LDAP users are still valid after sync [\#1211](https://github.com/zammad/zammad/issues/1211) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- LDAP - Role assignment based on groups does not work [\#1179](https://github.com/zammad/zammad/issues/1179) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Generation of weekly report fails with internal server error [\#1176](https://github.com/zammad/zammad/issues/1176) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Zendesk import: uninitialized constant Import::Zendesk::ObjectAttribute::Basic\_priority [\#1153](https://github.com/zammad/zammad/issues/1153) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Configuration of LDAP with disabled anonymous bind fails [\#1114](https://github.com/zammad/zammad/issues/1114) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Group and User filter detection for freeIPA LDAP fails [\#1155](https://github.com/zammad/zammad/issues/1155) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zendesk import: Error while importing ticket field with dash in name [\#1095](https://github.com/zammad/zammad/issues/1095) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP: mapping LDAP groups to multiple Zammad roles [\#1097](https://github.com/zammad/zammad/issues/1097) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Email loop if default trigger for follow up is active and customer email address is invalid [\#1131](https://github.com/zammad/zammad/issues/1131) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Update of object attribute leads to CSRF token verification failure [\#1034](https://github.com/zammad/zammad/issues/1034) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Not showing TO: / CC: fields on IE11 when answering a ticket [\#764](https://github.com/zammad/zammad/issues/764) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Internet Explorer 11 and lower - no paste from Clipboard possible [\#990](https://github.com/zammad/zammad/issues/990) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tag Bug - tag is deleted if renamed without changes via admin interface [\#1086](https://github.com/zammad/zammad/issues/1086) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unprocessable Email \(without email address in from header\) [\#811](https://github.com/zammad/zammad/issues/811) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP Integration eDirectoy doesn't find user entries/attributes [\#1088](https://github.com/zammad/zammad/issues/1088) [[bug](https://github.com/zammad/zammad/labels/bug)]

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*