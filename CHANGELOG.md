# Change Log

## [1.1.1](https://github.com/zammad/zammad/tree/1.1.1) (2016-12-14)
[Full Changelog](https://github.com/zammad/zammad/compare/1.1.0...1.1.1)

**Implemented enhancements:**

- Improved ticket number generator settings \(just show necessary settings based on generator selection\) [\#427](https://github.com/zammad/zammad/issues/427) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Provide a Debian Package [\#209](https://github.com/zammad/zammad/issues/209) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**

- "Ticket will escalate soon" in online notifications is not translated. [\#408](https://github.com/zammad/zammad/issues/408) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't process email / Error creating ticket with changed Ticket Number Format [\#413](https://github.com/zammad/zammad/issues/413) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to set owner + customer in postmaster/email filter [\#419](https://github.com/zammad/zammad/issues/419) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Switching storage provider for attachments in UI has no effect [\#428](https://github.com/zammad/zammad/issues/428) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to execute more then one trigger \(e. g. adding 2 tags with 2 triggers\) at one ticket at same update cycle [\#441](https://github.com/zammad/zammad/issues/441) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Customer should not have the internal attribute to set in customer interface. [\#437](https://github.com/zammad/zammad/issues/437) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to create job/scheduler if many time options are selected [\#432](https://github.com/zammad/zammad/issues/432) [[bug](https://github.com/zammad/zammad/labels/bug)]
- New overview with article conditions not working [\#448](https://github.com/zammad/zammad/issues/448) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Debian 8 mysql2.so LoadError [\#415](https://github.com/zammad/zammad/issues/415) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing quotation marks on sender address [\#402](https://github.com/zammad/zammad/issues/402) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Search result won't get updated after focus is lost and new search is started [\#466](https://github.com/zammad/zammad/issues/466) [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Password has been changed" email contains unresolved placeholders [\#468](https://github.com/zammad/zammad/issues/468) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Token without expiration timestamp expires "01/01/1970"  [\#478](https://github.com/zammad/zammad/issues/478) [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Get latest Translations" fails\(?\) without error [\#502](https://github.com/zammad/zammad/issues/502) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Pending event time after 22:59 jumps back to 22:59 [\#329](https://github.com/zammad/zammad/issues/329) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Max times for escalation 99 hours [\#418](https://github.com/zammad/zammad/issues/418) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Object manager allows method names as attributes [\#433](https://github.com/zammad/zammad/issues/433) [[bug](https://github.com/zammad/zammad/labels/bug)]
- bugfix: added missing join table [\#541](https://github.com/zammad/zammad/pull/541) [[bug](https://github.com/zammad/zammad/labels/bug)] ([TeaMoe](https://github.com/TeaMoe))
- New users won't get initial user group [\#249](https://githuvb.com/zammad/zammad/issues/249) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Wrong recipient on reply to Received call [\#206](https://github.com/zammad/zammad/issues/206) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to c&p images in Zammad Text-Editor with Firefox \(FF\) and Safari [\#505](https://github.com/zammad/zammad/issues/505) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Fix spelling mistakes [\#470](https://github.com/zammad/zammad/pull/470) [[bug](https://github.com/zammad/zammad/labels/bug)] ([corny](https://github.com/corny))

## [1.1.0](https://github.com/zammad/zammad/tree/1.1.0) (2016-11-14)
[Full Changelog](https://github.com/zammad/zammad/compare/1.0.1...1.1.0)

**Implemented enhancements:**

- Missing translation/edit abilities \(Notification mails, contact form\) [\#388](https://github.com/zammad/zammad/issues/388) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Automatically join users to organizations based on the email address [\#356](https://github.com/zammad/zammad/issues/356) [[feature](https://github.com/zammad/zammad/labels/feature)]
- Create emails via fetchmail / procmail [\#326](https://github.com/zammad/zammad/issues/326) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Display origin url from tweet/facebook post [\#317](https://github.com/zammad/zammad/issues/317) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Vagrant version [\#253](https://github.com/zammad/zammad/issues/253) [[feature](https://github.com/zammad/zammad/labels/feature)]
- Page posts from facebook and tweets from twitter as tickets [\#251](https://github.com/zammad/zammad/issues/251) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**

- Some windows in the config area too wide in firefox [\#392](https://github.com/zammad/zammad/issues/392) [[bug](https://github.com/zammad/zammad/labels/bug)]
- \[Critical\] Short display of "Setup a new system" on public site while restarting Zammad! [\#389](https://github.com/zammad/zammad/issues/389) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Mailresponse to customer not working at all after editing a "Trigger" event text [\#385](https://github.com/zammad/zammad/issues/385) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Click on "Reports" leads to Error 500 [\#384](https://github.com/zammad/zammad/issues/384) [[bug](https://github.com/zammad/zammad/labels/bug)]
- TicketSelector in Overview or SLA not working with filter for ticket customer or owner [\#383](https://github.com/zammad/zammad/issues/383) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Changelog generator breaks packager.io builds [\#379](https://github.com/zammad/zammad/issues/379) [[bug](https://github.com/zammad/zammad/labels/bug)]
- script/scheduler.rb crashes after recreation of Zammad database [\#374](https://github.com/zammad/zammad/issues/374) [[bug](https://github.com/zammad/zammad/labels/bug)]
- ticket search cache issue [\#349](https://github.com/zammad/zammad/issues/349) [[bug](https://github.com/zammad/zammad/labels/bug)]
- IMAP mail fetching stops because of broken spam email \(invalid Content-Transfer-Encoding header\) [\#348](https://github.com/zammad/zammad/issues/348) [[bug](https://github.com/zammad/zammad/labels/bug)]
- IMAP mail fetching stops working on spam mail and invalid email format [\#345](https://github.com/zammad/zammad/issues/345) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to create tickets [\#323](https://github.com/zammad/zammad/issues/323) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Admin -\> Channels -\> Email -\> Filters not shown / no name shown [\#313](https://github.com/zammad/zammad/issues/313) [[bug](https://github.com/zammad/zammad/labels/bug)]
- In object manager, blank line in object deleted all values for selections [\#312](https://github.com/zammad/zammad/issues/312) [[bug](https://github.com/zammad/zammad/labels/bug)]
- triggers do not work? [\#306](https://github.com/zammad/zammad/issues/306) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Answers from google mail shows complete quote [\#286](https://github.com/zammad/zammad/issues/286) [[minor bug](https://github.com/zammad/zammad/labels/minor%20bug)]
- Avatar in Chat not showing - wrong url [\#275](https://github.com/zammad/zammad/issues/275) [[bug](https://github.com/zammad/zammad/labels/bug)]
- chat not working / http 404 [\#274](https://github.com/zammad/zammad/issues/274) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zammad Docker container for rpi/ARM [\#271](https://github.com/zammad/zammad/issues/271) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zendesk: unknown article type fails import. [\#270](https://github.com/zammad/zammad/issues/270) [[bug](https://github.com/zammad/zammad/labels/bug)]
- No space at comment on ticket bulk action  [\#268](https://github.com/zammad/zammad/issues/268) [[bug](https://github.com/zammad/zammad/labels/bug)]
- After adding a new attribute - zammad won't start [\#248](https://github.com/zammad/zammad/issues/248) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Images/Avatars blank [\#217](https://github.com/zammad/zammad/issues/217) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Docker/Ubuntu Not starting postgresql-9.6 service [\#213](https://github.com/zammad/zammad/issues/213) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can´t choose Organization for Customer [\#211](https://github.com/zammad/zammad/issues/211) [[bug](https://github.com/zammad/zammad/labels/bug)]
- CentOS 7 HTTPS Error 404 - Not Found [\#210](https://github.com/zammad/zammad/issues/210) [[bug](https://github.com/zammad/zammad/labels/bug)]



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
