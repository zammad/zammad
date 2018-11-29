# Change Log

## [2.5.0](https://github.com/zammad/zammad/tree/2.5.0) (2018-06-06)
[Full Changelog](https://github.com/zammad/zammad/compare/2.4.0...2.5.0)

**Implemented enhancements:**

- Auto Assignment of unassigned ticket at first open time
- Import users and organisations via csv files [\#675](https://github.com/zammad/zammad/issues/675) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Allow pagination in search result with more then 100 results [\#1951](https://github.com/zammad/zammad/issues/1951) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Allow to automatically linking of existing user by initial login via third party authentication provider [\#1954](https://github.com/zammad/zammad/issues/1954) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Date of last contact \(customer\) - make behaviour configurable [\#1865](https://github.com/zammad/zammad/issues/1865) [[feature backlog](https://github.com/zammad/zammad/labels/feature%20backlog)]
- Allow recursive triggers for tickets [\#2035](https://github.com/zammad/zammad/issues/2035) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Generic CTI integration [\#2044](https://github.com/zammad/zammad/issues/2044) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Add max\_allowed\_packet to config/initializers/db\_preferences\_mysql.rb [\#2034](https://github.com/zammad/zammad/issues/2034) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Missing CC autocomplete / type ahead function in ticket create screen \(\#1018286\) [\#1990](https://github.com/zammad/zammad/issues/1990) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Make ticket create article types configurable [\#1987](https://github.com/zammad/zammad/issues/1987) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Implement STARTTLS for IMAP [\#1963](https://github.com/zammad/zammad/issues/1963) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]


**Fixed bugs:**

- Make sipgate.io integration working by just enable it [\#2029](https://github.com/zammad/zammad/issues/2029) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Deny ticket creation over webinterface for customers doesn't work [\#1339](https://github.com/zammad/zammad/issues/1339) [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Create new Customer" form delayed display [\#1957](https://github.com/zammad/zammad/issues/1957) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Telephone notify not clearing on leftside, the number of open calls are froozen [\#2017](https://github.com/zammad/zammad/issues/2017) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Import job \(LDAP/Exchange\) hangs on scheduler restart [\#2014](https://github.com/zammad/zammad/issues/2014) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Import fails for Object Attribute with non-ASCII name [\#2039](https://github.com/zammad/zammad/issues/2039) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Restart of processes from application context fails [\#2037](https://github.com/zammad/zammad/issues/2037) [[bug](https://github.com/zammad/zammad/labels/bug)]
- bulk action is not executed for a pending-state [\#1930](https://github.com/zammad/zammad/issues/1930) [[bug](https://github.com/zammad/zammad/labels/bug)]
- User can have "full" and a la carte \('create', 'change'\) group permissions at the same time [\#2012](https://github.com/zammad/zammad/issues/2012) [[bug](https://github.com/zammad/zammad/labels/bug)]
- User appears multiple times in drag&drop overlay in a group [\#2011](https://github.com/zammad/zammad/issues/2011) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Drag and Drop Groups empty [\#1591](https://github.com/zammad/zammad/issues/1591) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Scheduler destroys variables in text \(after a while\) [\#2001](https://github.com/zammad/zammad/issues/2001) [[bug](https://github.com/zammad/zammad/labels/bug)] [[notification](https://github.com/zammad/zammad/labels/notification)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Admin UI does not allow to select Timezone in "Calendars" options [\#1971](https://github.com/zammad/zammad/issues/1971) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Overviews - condition minutes/hours/days/years range only possible between 0 and 31 [\#1956](https://github.com/zammad/zammad/issues/1956) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Remove online notifications too if user is deleted. [\#1977](https://github.com/zammad/zammad/issues/1977) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket waiting time report backend creates high CPU load with script/scheduler.rb [\#1995](https://github.com/zammad/zammad/issues/1995) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Owner reset after group selection [\#1770](https://github.com/zammad/zammad/issues/1770) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- Use of wrong recipient if sender is also an agent [\#1996](https://github.com/zammad/zammad/issues/1996) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Configuration of new LDAP Server not possible [\#1814](https://github.com/zammad/zammad/issues/1814) [[bug](https://github.com/zammad/zammad/labels/bug)]
- avoid null pointer exception [\#1822](https://github.com/zammad/zammad/pull/1822) [[bug](https://github.com/zammad/zammad/labels/bug)] ([sscholl](https://github.com/sscholl))
- Missing identifier attribute on LDAP entry causes Sync to fail [\#1891](https://github.com/zammad/zammad/issues/1891) [[bug](https://github.com/zammad/zammad/labels/bug)]
- If fingerprint is an integer background job for verifying will fail [\#1974](https://github.com/zammad/zammad/issues/1974) [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Host unreachable" is shown when configuring an IMAP email inbox with SSL on port 993 [\#1972](https://github.com/zammad/zammad/issues/1972) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket templates disappear after logout/login in same browser session [\#1669](https://github.com/zammad/zammad/issues/1669) [[bug](https://github.com/zammad/zammad/labels/bug)] [[ticket templates](https://github.com/zammad/zammad/labels/ticket%20templates)]
- Password reset: No such file or directory @ rb\_sysopen - app/views/mailer/application\_wrapper.html.erb [\#1969](https://github.com/zammad/zammad/issues/1969) [[bug](https://github.com/zammad/zammad/labels/bug)]
- CalendarimportSync-Errors in Outlook 2016  [\#1332](https://github.com/zammad/zammad/issues/1332) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Paginated Organization search returns wrong entries at/after last page [\#1966](https://github.com/zammad/zammad/issues/1966) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Generic OAuth2 authentication: incorrect redirect\_uri during access token request, does not match authorization request due to query parameters being appended [\#1642](https://github.com/zammad/zammad/issues/1642) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Failing scheduler job retries to fast without any time offset [\#1950](https://github.com/zammad/zammad/issues/1950) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Use mime type of attachments if present for outgoing emails [\#1919](https://github.com/zammad/zammad/issues/1919) [[bug](https://github.com/zammad/zammad/labels/bug)]
- New ticket attributes is also show for customers \(which should not\). [\#1952](https://github.com/zammad/zammad/issues/1952) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Cannot reply to Twitter Direct Message from Zammad [\#1931](https://github.com/zammad/zammad/issues/1931) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't find organization anymore after index rebuild [\#1933](https://github.com/zammad/zammad/issues/1933) [[bug](https://github.com/zammad/zammad/labels/bug)]
- RTL Profile - Pending Close calendar is missing 2 days [\#1842](https://github.com/zammad/zammad/issues/1842) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Signin detected from a new device" Spam [\#1337](https://github.com/zammad/zammad/issues/1337) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Generated chat widget code misses required option chatId  [\#1936](https://github.com/zammad/zammad/issues/1936) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Pulldowns are not sorted currently [\#1923](https://github.com/zammad/zammad/issues/1923) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Only images in new note are lost on submit [\#1917](https://github.com/zammad/zammad/issues/1917) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Issue with space \(%20\) in HyperLinks [\#1902](https://github.com/zammad/zammad/issues/1902) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Cannot use ticket templates since 2.4 anymore [\#1913](https://github.com/zammad/zammad/issues/1913) [[bug](https://github.com/zammad/zammad/labels/bug)] [[ticket templates](https://github.com/zammad/zammad/labels/ticket%20templates)]


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*