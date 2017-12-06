# Change Log

## [2.1.1](https://github.com/zammad/zammad/tree/2.1.1) (2017-12-06)
[Full Changelog](https://github.com/zammad/zammad/compare/2.1.0...2.1.1)

**Implemented enhancements:**
- Improve i-doit filtering \(without type\) [\#1571](https://github.com/zammad/zammad/issues/1571) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Reset customer selection in ticket create screen if input field cleared [\#1670](https://github.com/zammad/zammad/issues/1670) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Add config option for intelligent customer selection of incoming emails of agents [\#1671](https://github.com/zammad/zammad/issues/1671) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Translation for form widget in Dutch [\#1623](https://github.com/zammad/zammad/issues/1623) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Twitter: Allow tweet articles to be 280 chars long [\#1628](https://github.com/zammad/zammad/issues/1628) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Chat language setting or behaviour in dutch [\#1618](https://github.com/zammad/zammad/issues/1618) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]


**Fixed bugs:**
- Webform isn´t available | 401 Unauthorized [\#1604](https://github.com/zammad/zammad/issues/1604) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to re-order overviews in admin interface with over 100 overviews [\#1681](https://github.com/zammad/zammad/issues/1681) [[bug](https://github.com/zammad/zammad/labels/bug)]
- TimeAccounting ticket condition prevents submit of Zoom [\#1513](https://github.com/zammad/zammad/issues/1513) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to open trigger in admin interface [\#1666](https://github.com/zammad/zammad/issues/1666) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Users mail\_delivery\_failed is not removed after changing the email address [\#1661](https://github.com/zammad/zammad/issues/1661) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tickets are deleted but database is still the same size [\#1649](https://github.com/zammad/zammad/issues/1649) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ignore Twitter search key with only \# [\#1606](https://github.com/zammad/zammad/issues/1606) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to sort overview by priority  [\#1595](https://github.com/zammad/zammad/issues/1595) [[bug](https://github.com/zammad/zammad/labels/bug)]


## [2.1.0](https://github.com/zammad/zammad/tree/2.1.0) (2017-10-25)
[Full Changelog](https://github.com/zammad/zammad/compare/2.0.0...2.1.0)

**Implemented enhancements:**
- Added reporting feature.
- Added Minit support.
- Added Check_MK support.
- Moved to Ruby on Rails 5.1.
- leading and tailing utf8 spaces are not removed for email addresses are not removed [\#1579](https://github.com/zammad/zammad/issues/1579) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Import emails with same message\_id but target was different channels [\#1578](https://github.com/zammad/zammad/issues/1578) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Allow cti log entries to check done \(also if no hangup state is available\) [\#1478](https://github.com/zammad/zammad/issues/1478) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Selecting specific users for overviews [\#1418](https://github.com/zammad/zammad/issues/1418) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- support Weibo OAuth2 login [\#1465](https://github.com/zammad/zammad/issues/1465) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]


**Fixed bugs:**
- prevent admin from locking out [\#1563](https://github.com/zammad/zammad/issues/1563) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to reindex tickets / elasticsearch error "MapperParsingException\[failed to parse \[article.ticket\]\]; nested: JsonParseException\[Current token \(START\_OBJECT\) not of boolean type" [\#1538](https://github.com/zammad/zammad/issues/1538) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to show overview if selected order by attribute is not show in header [\#1528](https://github.com/zammad/zammad/issues/1528) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Cannot update notification preferences when nothing is selected [\#1276](https://github.com/zammad/zammad/issues/1276) [[bug](https://github.com/zammad/zammad/labels/bug)] [[notification](https://github.com/zammad/zammad/labels/notification)]
- ReplyAll - moves recipients from "To" to "CC" [\#1303](https://github.com/zammad/zammad/issues/1303) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zammad sends reply to itself [\#986](https://github.com/zammad/zammad/issues/986) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Exchange Integration SSL Error with self-signed root certificate authority  [\#1442](https://github.com/zammad/zammad/issues/1442) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Exchange Feature - URL? [\#1406](https://github.com/zammad/zammad/issues/1406) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tickets sent by agent via email into Zammad have state open \(not new\) [\#1482](https://github.com/zammad/zammad/issues/1482) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Scheduler not running because of Bad file descriptor in PGConsumeInput\(\) [\#1405](https://github.com/zammad/zammad/issues/1405) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Icinga/Nagios Integration: No longer accepts regex in "Sender" [\#1439](https://github.com/zammad/zammad/issues/1439) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Invalidate cache when switching users [\#1280](https://github.com/zammad/zammad/issues/1280) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Job BackgroundJobSearchIndex NoMethodError: undefined method `lookup' for User::Permission:Module [\#1424](https://github.com/zammad/zammad/issues/1424) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Profile not clickable on browsers with touch events or on some Chrome for Windows [\#1398](https://github.com/zammad/zammad/issues/1398) [[bug](https://github.com/zammad/zammad/labels/bug)]


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*