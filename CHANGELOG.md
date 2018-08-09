# Change Log

## [2.5.1](https://github.com/zammad/zammad/tree/2.5.1) (2018-08-08)
[Full Changelog](https://github.com/zammad/zammad/compare/2.5.0...2.5.1)

**Implemented enhancements:**
- Add delete existing records to CSV import feature. [\#2064](https://github.com/zammad/zammad/issues/2064) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Do not allow to create pre existing attributes like updated\_at via object manager [\#2172](https://github.com/zammad/zammad/issues/2172) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Overview not showing unassigned tickets "if not defined" [\#2171](https://github.com/zammad/zammad/issues/2171) [[bug](https://github.com/zammad/zammad/labels/bug)]
- i-doit: Setting object before filling in the ticket information removed the i-doit objects [\#2165](https://github.com/zammad/zammad/issues/2165) [[bug](https://github.com/zammad/zammad/labels/bug)]
- i-doit: Double click needed to select object after searching \(w/o category\) [\#2164](https://github.com/zammad/zammad/issues/2164) [[bug](https://github.com/zammad/zammad/labels/bug)]
- 30 concurrent agents + each of them 30 overviews - script/scheduler.rb takes 100% CPU time - background jobs cannot be processed [\#2108](https://github.com/zammad/zammad/issues/2108) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Visible organizsation content \(organization profile\) not updated [\#1616](https://github.com/zammad/zammad/issues/1616) [[bug](https://github.com/zammad/zammad/labels/bug)]
- RegexpError: failed to allocate memory for large attachments [\#2141](https://github.com/zammad/zammad/issues/2141) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to link objects at ticket creation [\#2132](https://github.com/zammad/zammad/issues/2132) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket "update" cancels active attachment upload [\#2117](https://github.com/zammad/zammad/issues/2117) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Deleting all tickets throws errors for old IDs [\#2066](https://github.com/zammad/zammad/issues/2066) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP sync: Updating association of deactivated instance fails [\#2110](https://github.com/zammad/zammad/issues/2110) [[bug](https://github.com/zammad/zammad/labels/bug)]
- User history shows LDAP deactivation was done by a regular agent [\#2111](https://github.com/zammad/zammad/issues/2111) [[bug](https://github.com/zammad/zammad/labels/bug)]
- strip out auto generated links by the browser [\#2019](https://github.com/zammad/zammad/issues/2019) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Route for /auth/failure is missing to show login failure messages form oauth provider \(if request was technical ok - only login was not possible by oauth provider\) [\#2128](https://github.com/zammad/zammad/issues/2128) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Auto responder is not set from correct group [\#2125](https://github.com/zammad/zammad/issues/2125) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Shown ticket changed unexpected when viewing an attached image [\#2104](https://github.com/zammad/zammad/issues/2104) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Update button unusable after modal dialog is gone [\#2105](https://github.com/zammad/zammad/issues/2105) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Viewpoint::EWS::EwsFolderNotFound during Exchange connection [\#1802](https://github.com/zammad/zammad/issues/1802) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- A ticket created by customer via web with state new is set to open on second update by customer [\#2118](https://github.com/zammad/zammad/issues/2118) [[bug](https://github.com/zammad/zammad/labels/bug)]
- autoreply email filter [\#1316](https://github.com/zammad/zammad/issues/1316) [[bug](https://github.com/zammad/zammad/labels/bug)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- No mime\_type on nil message \(no message body\) / email will not be processed [\#2087](https://github.com/zammad/zammad/issues/2087) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Report profiles: "before\(relative\)" and friends broken. [\#2098](https://github.com/zammad/zammad/issues/2098) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Changing data type of new object attributes will lead to errors [\#2099](https://github.com/zammad/zammad/issues/2099) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Autocomplete hangs on dot in the new user form [\#2058](https://github.com/zammad/zammad/issues/2058) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to create an overview with a new ticket file which is starting with number like "1\_test" [\#2090](https://github.com/zammad/zammad/issues/2090) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Inline images are lost on forward or quoted reply [\#2101](https://github.com/zammad/zammad/issues/2101) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Filename of images \(c&p\) downloaded via lightbox is invalid [\#1246](https://github.com/zammad/zammad/issues/1246) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Special characters get HTML encoded when displayed in overviews was\(Umlauts in overview not working\) [\#2046](https://github.com/zammad/zammad/issues/2046) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Scheduler will stop after removing own ticket attribute but overview with condition which is including attribute git dropped [\#2016](https://github.com/zammad/zammad/issues/2016) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to create an overview with a new ticket file which is starting with number like "1\_test" [\#2090](https://github.com/zammad/zammad/issues/2090) [[bug](https://github.com/zammad/zammad/labels/bug)]
- escalation\_at are not updated correctly [\#2082](https://github.com/zammad/zammad/issues/2082) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Inserting space character in translations \(in Overviews menu item and User menu\) [\#1531](https://github.com/zammad/zammad/issues/1531) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Cannot close tickets when you reply to an E-Mail at the same time [\#2069](https://github.com/zammad/zammad/issues/2069) [[bug](https://github.com/zammad/zammad/labels/bug)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Error after apt upgrade on ubuntu 16.04 [\#2054](https://github.com/zammad/zammad/issues/2054) [[bug](https://github.com/zammad/zammad/labels/bug)]

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*