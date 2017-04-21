# Change Log

## [1.2.3](https://github.com/zammad/zammad/tree/1.2.3) (2017-03-16)
[Full Changelog](https://github.com/zammad/zammad/compare/1.2.2...1.2.3)

**Fixed bugs:**

- Follow up detection is broken for Ticket::Number::Date ticket number generator. [\#899](https://github.com/zammad/zammad/issues/899) [[bug](https://github.com/zammad/zammad/labels/bug)]


## [1.2.2](https://github.com/zammad/zammad/tree/1.2.2) (2017-03-16)
[Full Changelog](https://github.com/zammad/zammad/compare/1.2.1...1.2.2)

**Fixed bugs:**

- Disabled macros are still shown in ticket screen [\#838](https://github.com/zammad/zammad/issues/838) [[bug](https://github.com/zammad/zammad/labels/bug)]


## [1.2.1](https://github.com/zammad/zammad/tree/1.2.1) (2017-02-15)
[Full Changelog](https://github.com/zammad/zammad/compare/1.2.0...1.2.1)

**Fixed bugs:**

- Ticket without Subject is blocked - can't do anything with it \("Title needed"\) [\#719](https://github.com/zammad/zammad/issues/719) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Unable to process emails with email addresses longer then 140 signs. [\#650](https://github.com/zammad/zammad/issues/650) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process emails if "Additional follow-up detection" was checked and unchecked again [\#740](https://github.com/zammad/zammad/issues/740) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Time accounting works only with dot [\#705](https://github.com/zammad/zammad/issues/705) [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Close Tab" & "Next in Overview" don't work [\#730](https://github.com/zammad/zammad/issues/730) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Prevent attachment preview in browser attachment download [\#617](https://github.com/zammad/zammad/issues/617) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Feedback form not working in Safari [\#685](https://github.com/zammad/zammad/issues/685) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Follow up detection not working if ticket\_hook\_position "none" is used. [\#686](https://github.com/zammad/zammad/issues/686) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Customer get forced to save time for time accounting in customer interface - only allow it for agents. [\#636](https://github.com/zammad/zammad/issues/636) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to activate time accounting in admin interface. [\#633](https://github.com/zammad/zammad/issues/633) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Prevent attachment preview in browser attachment download [\#617](https://github.com/zammad/zammad/issues/617) [[bug](https://github.com/zammad/zammad/labels/bug)]

## [1.2.0](https://github.com/zammad/zammad/tree/1.2.0) (2017-01-16)
[Full Changelog](https://github.com/zammad/zammad/compare/1.1.0...1.2.0)

**Implemented enhancements:**

- Feature "Time recording" [\#373](https://github.com/zammad/zammad/issues/373) [[feature](https://github.com/zammad/zammad/labels/feature)]
- Proxy support [\#439](https://github.com/zammad/zammad/issues/439) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Improved call log workflow [\#517](https://github.com/zammad/zammad/pull/517) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] ([TeaMoe](https://github.com/TeaMoe))
- Create ticket with customer [\#514](https://github.com/zammad/zammad/pull/514) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] ([TeaMoe](https://github.com/TeaMoe))
- Versions françaises [\#578](https://github.com/zammad/zammad/pull/578) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[translation](https://github.com/zammad/zammad/labels/translation)] ([GeraldElbaze-Medias-Cite](https://github.com/GeraldElbaze-Medias-Cite))
- French for Chat widget [\#580](https://github.com/zammad/zammad/issues/580) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Show other active agents in ticket detail view \(collision prevention\) [\#352](https://github.com/zammad/zammad/issues/352) [[feature](https://github.com/zammad/zammad/labels/feature)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]

**Fixed bugs:**

- OTRS import - long content type shows warning and gets cut [\#582](https://github.com/zammad/zammad/issues/582) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Setup asks for FQDN, but doesn't write to DB [\#462](https://github.com/zammad/zammad/issues/462) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Group restrictions not respected in slack notification [\#587](https://github.com/zammad/zammad/issues/587) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Keyboard shortcuts dialog breaks url bar [\#530](https://github.com/zammad/zammad/issues/530) [[bug](https://github.com/zammad/zammad/labels/bug)]
- OTRS import - unsupported DynamicField type fields cause import to abort [\#565](https://github.com/zammad/zammad/issues/565) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Gitlab Auth not working [\#596](https://github.com/zammad/zammad/issues/596) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Admin user login via Oauth [\#602](https://github.com/zammad/zammad/issues/602) [[bug](https://github.com/zammad/zammad/labels/bug)]
- If "new ticket created" popover is shown you can't click search box [\#597](https://github.com/zammad/zammad/issues/597) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- New ticket attributes are not shown for customer [\#576](https://github.com/zammad/zammad/issues/576) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Imap sort errors with gmail in production.log [\#568](https://github.com/zammad/zammad/issues/568) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Agent - Group assignment shows "\<br\>" [\#566](https://github.com/zammad/zammad/issues/566) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Renaming standard roles breaks ticket views [\#499](https://github.com/zammad/zammad/issues/499) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Overview is not show it organization is used as row and first ticket has no organization \(app is not responding anymore\) [\#554](https://github.com/zammad/zammad/issues/554) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Add organization to overview in manage users \(admin interface\) [\#552](https://github.com/zammad/zammad/issues/552) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- OTRS import: Empty created\_at of customer user record brakes import. [\#548](https://github.com/zammad/zammad/issues/548) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Layout broken if outbound channel has a error message [\#547](https://github.com/zammad/zammad/issues/547) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Do not show arrow down on ajax auto completion fields [\#546](https://github.com/zammad/zammad/issues/546) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Error message at creation of new overview with not existing specific customer [\#545](https://github.com/zammad/zammad/issues/545) [[bug](https://github.com/zammad/zammad/labels/bug)]


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