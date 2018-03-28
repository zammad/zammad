# Change Log

## [2.3.1](https://github.com/zammad/zammad/tree/2.3.1) (2018-03-29)
[Full Changelog](https://github.com/zammad/zammad/compare/2.3.0...2.3.1)

**Fixed bugs:**
- Direct access to organization tickets possible even though shared is deactivated [\#1857](https://github.com/zammad/zammad/issues/1857) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't create email-account with local MTA as outgoing server  [\#1852](https://github.com/zammad/zammad/issues/1852) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Issues in the rights-management  [\#1810](https://github.com/zammad/zammad/issues/1810) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Reporting: profile condition is ignored [\#1809](https://github.com/zammad/zammad/issues/1809) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Taskbar item race condition causes JS exception [\#1841](https://github.com/zammad/zammad/issues/1841) [[bug](https://github.com/zammad/zammad/labels/bug)]
- The column widths of a table are shifted after manual change and use of pagination. [\#1829](https://github.com/zammad/zammad/issues/1829) [[bug](https://github.com/zammad/zammad/labels/bug)]
- JS error on creating new customer [\#1813](https://github.com/zammad/zammad/issues/1813) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Customer response via note does not trigger escalation [\#1322](https://github.com/zammad/zammad/issues/1322) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP authentication doen't work in 2.3.x [\#1795](https://github.com/zammad/zammad/issues/1795) [[bug](https://github.com/zammad/zammad/labels/bug)]
- XSS issue in ticket overview [\#1869](https://github.com/zammad/zammad/issues/1869) [[bug](https://github.com/zammad/zammad/labels/bug)]

## [2.3.0](https://github.com/zammad/zammad/tree/2.3.0) (2018-01-30)
[Full Changelog](https://github.com/zammad/zammad/compare/2.2.0...2.3.0)

**Implemented enhancements:**
- Convert Chat into Ticket [\#422](https://github.com/zammad/zammad/issues/422)
- Added support of blocking IPs and/or countries for chat.
- Added support to search and reopen already finised chat sessions.
- LDAP User uid attribute is not reliable [\#1709](https://github.com/zammad/zammad/issues/1709) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Add article.body support for triggers [\#1745](https://github.com/zammad/zammad/issues/1745) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Do not allow roles as default signup with admin, admin.\* and ticket.agent permissions [\#1758](https://github.com/zammad/zammad/issues/1758) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Attachments with content-id header but not shown as inline part are note taken for forward action [\#1778](https://github.com/zammad/zammad/issues/1778) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Need data\_option\[:null\] - Ticket Object Manager [\#1742](https://github.com/zammad/zammad/issues/1742) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP login not possible since change to objectguid [\#1764](https://github.com/zammad/zammad/issues/1764) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Generated excel report fails to create for special strings in ticket titles \(also: CSV formula injection possible\) [\#1756](https://github.com/zammad/zammad/issues/1756) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Loss of LDAP group assignment is not reflected in Zammad role assignment [\#1751](https://github.com/zammad/zammad/issues/1751) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket search fails for limit exceeding 100 with internal server error [\#1753](https://github.com/zammad/zammad/issues/1753) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Trigger ignoring tag condition [\#1683](https://github.com/zammad/zammad/issues/1683) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to send auto reply if from contains 2 or more senders with invalid email address [\#1749](https://github.com/zammad/zammad/issues/1749) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Report for Created tickets should not have "merged" tickets [\#1741](https://github.com/zammad/zammad/issues/1741) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Exchange integration process stuck at 1000 users [\#1740](https://github.com/zammad/zammad/issues/1740) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Telegram bot error when exit and delete telegram group [\#1732](https://github.com/zammad/zammad/issues/1732) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Exchange integration tries to import user twice and fails [\#1663](https://github.com/zammad/zammad/issues/1663) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP - missing support for groupOfUniqueNames / uniquemember [\#1664](https://github.com/zammad/zammad/issues/1664) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Removed LDAP attributes aren't reflected on the user [\#1665](https://github.com/zammad/zammad/issues/1665) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Wrong ticket number count in preview [\#1723](https://github.com/zammad/zammad/issues/1723) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zammad Api for idoit.object\_ids broken [\#1711](https://github.com/zammad/zammad/issues/1711) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to login with Office365 [\#1710](https://github.com/zammad/zammad/issues/1710) [[bug](https://github.com/zammad/zammad/labels/bug)]
- No user preference for out-of-office available [\#1699](https://github.com/zammad/zammad/issues/1699) [[bug](https://github.com/zammad/zammad/labels/bug)]
- SipgateController - undefined method `each' for nil:NilClass \(NoMethodError\) [\#1698](https://github.com/zammad/zammad/issues/1698) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Agent ticket overview broken [\#789](https://github.com/zammad/zammad/issues/789) [[bug](https://github.com/zammad/zammad/labels/bug)]

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*