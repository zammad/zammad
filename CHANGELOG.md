# Change Log

## [2.4.1](https://github.com/zammad/zammad/tree/2.4.1) (2018-06-05)
[Full Changelog](https://github.com/zammad/zammad/compare/2.4.0...2.4.1)

**Implemented enhancements:**
- Missing CC autocomplete / type ahead function in ticket create screen \(\#1018286\) [\#1990](https://github.com/zammad/zammad/issues/1990) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- "Create new Customer" form delayed display [\#1957](https://github.com/zammad/zammad/issues/1957) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zendesk import: To/From extraction for system comments fails [\#2040](https://github.com/zammad/zammad/issues/2040) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Import fails for Object Attribute with non-ASCII name [\#2039](https://github.com/zammad/zammad/issues/2039) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Import job \(LDAP/Exchange\) hangs on scheduler restart [\#2014](https://github.com/zammad/zammad/issues/2014) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Scheduler destroys variables in text \(after a while\) [\#2001](https://github.com/zammad/zammad/issues/2001) [[bug](https://github.com/zammad/zammad/labels/bug)] [[notification](https://github.com/zammad/zammad/labels/notification)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Admin UI does not allow to select Timezone in "Calendars" options [\#1971](https://github.com/zammad/zammad/issues/1971) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket waiting time report backend creates high CPU load with script/scheduler.rb [\#1995](https://github.com/zammad/zammad/issues/1995) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Use of wrong recipient if sender is also an agent [\#1996](https://github.com/zammad/zammad/issues/1996) [[bug](https://github.com/zammad/zammad/labels/bug)]
- ObjectManager: New select attributes with empty selection will lead block UI [\#1980](https://github.com/zammad/zammad/issues/1980) [[bug](https://github.com/zammad/zammad/labels/bug)]
- If fingerprint is an integer background job for verifying will fail [\#1974](https://github.com/zammad/zammad/issues/1974) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket templates disappear after logout/login in same browser session [\#1669](https://github.com/zammad/zammad/issues/1669) [[bug](https://github.com/zammad/zammad/labels/bug)] [[ticket templates](https://github.com/zammad/zammad/labels/ticket%20templates)]
- CalendarimportSync-Errors in Outlook 2016  [\#1332](https://github.com/zammad/zammad/issues/1332) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Generic OAuth2 authentication: incorrect redirect\_uri during access token request, does not match authorization request due to query parameters being appended [\#1642](https://github.com/zammad/zammad/issues/1642) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Failing scheduler job retries to fast without any time offset [\#1950](https://github.com/zammad/zammad/issues/1950) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Use mime type of attachments if present for outgoing emails [\#1919](https://github.com/zammad/zammad/issues/1919) [[bug](https://github.com/zammad/zammad/labels/bug)]
- New ticket attributes is also show for customers \(which should not\). [\#1952](https://github.com/zammad/zammad/issues/1952) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't find organization anymore after index rebuild [\#1933](https://github.com/zammad/zammad/issues/1933) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Sometimes notifications are not marked as seen if somebody else already closed the ticket [\#1920](https://github.com/zammad/zammad/issues/1920) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Generated chat widget code misses required option chatId  [\#1936](https://github.com/zammad/zammad/issues/1936) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Pulldowns are not sorted currently [\#1923](https://github.com/zammad/zammad/issues/1923) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Only images in new note are lost on submit [\#1917](https://github.com/zammad/zammad/issues/1917) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Stored Exchange remote\_id in login causes sync to update wrong user [\#1905](https://github.com/zammad/zammad/issues/1905) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket-Property of type Tree-Select mixes up children [\#1660](https://github.com/zammad/zammad/issues/1660) [[bug](https://github.com/zammad/zammad/labels/bug)]


## [2.4.0](https://github.com/zammad/zammad/tree/2.4.0) (2018-03-29)
[Full Changelog](https://github.com/zammad/zammad/compare/2.3.0...2.4.0)

**Implemented enhancements:**
- Autocomplete Email-Address-Fields [\#338](https://github.com/zammad/zammad/issues/338) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- API: Ticket creation - wrong user in notifcations, activity stream [\#1805](https://github.com/zammad/zammad/issues/1805) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Admin interface: Generic clone function for objects
- RichText: Adjustment of the image size which were inserted from the clipboard
- Admin users can be disabled by Agents [\#1794](https://github.com/zammad/zammad/issues/1794) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Failing Scheduler Delayed::Job - jobs are not listed in the monitoring result [\#1866](https://github.com/zammad/zammad/issues/1866) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Reset owner of ticket on followup if owner is invalid or has no access to group anymore. [\#1816](https://github.com/zammad/zammad/issues/1816) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Clearing the entered value in a not required ticket field [\#1882](https://github.com/zammad/zammad/issues/1882)
- Pending till date not displayed correctly? [\#1716](https://github.com/zammad/zammad/issues/1716) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Login fails after fast logout right after previous login [\#1859](https://github.com/zammad/zammad/issues/1859) [[bug](https://github.com/zammad/zammad/labels/bug)]
- customer field in customer\_ticket\_new when customer is logged in [\#1856](https://github.com/zammad/zammad/issues/1856) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Direct access to organization tickets possible even though shared is deactivated [\#1857](https://github.com/zammad/zammad/issues/1857) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't create email-account with local MTA as outgoing server  [\#1852](https://github.com/zammad/zammad/issues/1852) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Role - Group cant be unchecked [\#1488](https://github.com/zammad/zammad/issues/1488) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't un-link i-doit Objects in a Ticket [\#1733](https://github.com/zammad/zammad/issues/1733) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Issues in the rights-management  [\#1810](https://github.com/zammad/zammad/issues/1810) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Sometimes pending time is show as first ticket attribute [\#949](https://github.com/zammad/zammad/issues/949) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Taskbar item race condition causes JS exception [\#1841](https://github.com/zammad/zammad/issues/1841) [[bug](https://github.com/zammad/zammad/labels/bug)]
- The column widths of a table are shifted after manual change and use of pagination. [\#1829](https://github.com/zammad/zammad/issues/1829) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Auto assignment of unassigned tickets at first open time [\#1825](https://github.com/zammad/zammad/issues/1825) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Boolean default option in object manager not selecting when it is already saved [\#1792](https://github.com/zammad/zammad/issues/1792)
- Ticket shown multiple times in overview [\#1769](https://github.com/zammad/zammad/issues/1769) [[bug](https://github.com/zammad/zammad/labels/bug)]
- JS error on creating new customer [\#1813](https://github.com/zammad/zammad/issues/1813) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Customer response via note does not trigger escalation [\#1322](https://github.com/zammad/zammad/issues/1322) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Reporting: profile condition is ignored [\#1809](https://github.com/zammad/zammad/issues/1809) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP authentication doen't work in 2.3.x [\#1795](https://github.com/zammad/zammad/issues/1795) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing create/add customer from ticket [\#1522](https://github.com/zammad/zammad/issues/1522) [[bug](https://github.com/zammad/zammad/labels/bug)]
- XSS issue in ticket overview [\#1869](https://github.com/zammad/zammad/issues/1869) [[bug](https://github.com/zammad/zammad/labels/bug)]


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*