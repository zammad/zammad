# Change Log

## [2.0.0](https://github.com/zammad/zammad/tree/2.0.0) (2017-09-11)
[Full Changelog](https://github.com/zammad/zammad/compare/1.6.0...2.0.0)

**Implemented enhancements:**
- Calendar: ICAL ignores recurring appointments/events [\#1362](https://github.com/zammad/zammad/issues/1362) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Inconsistent data state causes PostgreSQL Database to break update/migration with PG::InFailedSqlTransaction [\#1261](https://github.com/zammad/zammad/issues/1261) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Added rtl/i18n support for Hebrew
- Chat widget error "chat notice || Translation 'es' needed!" [\#1267](https://github.com/zammad/zammad/issues/1267) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Chat Widget should support richtext \(same as agent chat\)  [\#1255](https://github.com/zammad/zammad/issues/1255) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Using text modules also in chat [\#443](https://github.com/zammad/zammad/issues/443) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Added possibility to keep emails on IMAP server (do not delete them from server) [\#539](https://github.com/zammad/zammad/issues/539) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- OAuth2: Office365 [\#1177](https://github.com/zammad/zammad/issues/1177) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Ticket creation - allow to create users without email [\#562](https://github.com/zammad/zammad/issues/562) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Switch elasticsearch standard operator from OR to AND [\#1090](https://github.com/zammad/zammad/issues/1090) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Delete tickets via admin interface as job [\#214](https://github.com/zammad/zammad/issues/214) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Suggestion: More Efficient Use of Ticket Area [\#957](https://github.com/zammad/zammad/issues/957) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Macro/Bulk action: Cannot transfer more than one ticket to agent [\#1107](https://github.com/zammad/zammad/issues/1107) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Duplicates in Caller Log \(Sipgate\) [\#1253](https://github.com/zammad/zammad/issues/1253) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Time Accounting not showing all tickets, time is missing completly of specific ticket [\#1315](https://github.com/zammad/zammad/issues/1315) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Exchange config with error message [\#1381](https://github.com/zammad/zammad/issues/1381) [[bug](https://github.com/zammad/zammad/labels/bug)]
- 'Access-Control-Allow-Origin' error when submitting web form. [\#1318](https://github.com/zammad/zammad/issues/1318) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Delete action for tickets not working [\#1331](https://github.com/zammad/zammad/issues/1331) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Relative and absolute time bug [\#1340](https://github.com/zammad/zammad/issues/1340) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket Hook Position between RE: and the ticket subject [\#1369](https://github.com/zammad/zammad/issues/1369) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing replacement of Config and Current User objects in text modules and signatures [\#1290](https://github.com/zammad/zammad/issues/1290) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tel Protocol Link for Telephone and Mobile [\#991](https://github.com/zammad/zammad/issues/991) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Don't use Proxy on localhost Address. [\#1292](https://github.com/zammad/zammad/issues/1292) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Reopen ticket on mail delivery failure [\#1198](https://github.com/zammad/zammad/issues/1198) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Block escape key when creating / editing text modules [\#1291](https://github.com/zammad/zammad/issues/1291) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Race condition if agents merge ticket at same time but in different directions. [\#1216](https://github.com/zammad/zammad/issues/1216) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Config option to have uniq email addresses for users [\#1251](https://github.com/zammad/zammad/issues/1251) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Feature Request: clear caller log [\#1254](https://github.com/zammad/zammad/issues/1254) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Problem with cyrillic letters in name of overviews. [\#1151](https://github.com/zammad/zammad/issues/1151) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Backslash issue [\#1230](https://github.com/zammad/zammad/issues/1230) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to add Linked Gitlab account [\#1240](https://github.com/zammad/zammad/issues/1240) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Firefox - Focus lost after using :: TextSnippts [\#884](https://github.com/zammad/zammad/issues/884) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Trigger: Wrong behaviour for condition "is not" "not set"  [\#1149](https://github.com/zammad/zammad/issues/1149) [[bug](https://github.com/zammad/zammad/labels/bug)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Add date/time information to time accounting \(xls export\) [\#1194](https://github.com/zammad/zammad/issues/1194) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Zammad Chat widget not working with jquery 3 [\#1220](https://github.com/zammad/zammad/issues/1220) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Feedback Form Channel - Ability to set a target group for incoming tickets [\#1206](https://github.com/zammad/zammad/issues/1206) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Add recaptcha option to web form channel [\#1207](https://github.com/zammad/zammad/issues/1207) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Too many emails about new client access if user agent is "" [\#1208](https://github.com/zammad/zammad/issues/1208) [[bug](https://github.com/zammad/zammad/labels/bug)]
- User can not be removed from organization [\#1165](https://github.com/zammad/zammad/issues/1165) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Edge looses text formatting on reply \(may also on other browsers\) [\#707](https://github.com/zammad/zammad/issues/707) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Generation of weekly report fails with internal server error [\#1176](https://github.com/zammad/zammad/issues/1176) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Update of object attribute leads to CSRF token verification failure [\#1034](https://github.com/zammad/zammad/issues/1034) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Not showing TO: / CC: fields on IE11 when answering a ticket [\#764](https://github.com/zammad/zammad/issues/764) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Internet Explorer 11 and lower - no paste from Clipboard possible [\#990](https://github.com/zammad/zammad/issues/990) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tag Bug - tag is deleted if renamed without changes via admin interface [\#1086](https://github.com/zammad/zammad/issues/1086) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unprocessable Email \(without email address in from header\) [\#811](https://github.com/zammad/zammad/issues/811) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Bulk Action -\> JS Error - Bug [\#1053](https://github.com/zammad/zammad/issues/1053) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Reply-To is not considered for automatic responses \(triggers\). [\#1006](https://github.com/zammad/zammad/issues/1006) [[bug](https://github.com/zammad/zammad/labels/bug)] [[notification](https://github.com/zammad/zammad/labels/notification)]
- Creation of overview fails [\#1014](https://github.com/zammad/zammad/issues/1014) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Gui stuck / Error on random switching through overviews [\#1012](https://github.com/zammad/zammad/issues/1012) [[bug](https://github.com/zammad/zammad/labels/bug)]
- HTML Table in email being re-formatted [\#930](https://github.com/zammad/zammad/issues/930) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Wrong article order after merging of tickets [\#187](https://github.com/zammad/zammad/issues/187) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Ticket were shown twice [\#655](https://github.com/zammad/zammad/issues/655) [[bug](https://github.com/zammad/zammad/labels/bug)]


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
