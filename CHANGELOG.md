# Change Log

## [1.3.1](https://github.com/zammad/zammad/tree/1.3.1) (2017-03-16)
[Full Changelog](https://github.com/zammad/zammad/compare/1.3.0...1.3.1)

**Fixed bugs:**

- multiplication of the attachment-field in \#channels/form [\#833](https://github.com/zammad/zammad/issues/833) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Disabled macros are still shown in ticket screen [\#838](https://github.com/zammad/zammad/issues/838) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't select object with type date as filter for overviews [\#821](https://github.com/zammad/zammad/issues/821) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Simple triggers resulting in error condition [\#779](https://github.com/zammad/zammad/issues/779) [[bug](https://github.com/zammad/zammad/labels/bug)]
- User password reset doesn't work - user not able to login [\#791](https://github.com/zammad/zammad/issues/791) [[bug](https://github.com/zammad/zammad/labels/bug)]
- admin interface -\> time accounting setting will not be saved [\#677](https://github.com/zammad/zammad/issues/677) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]


## [1.3.0](https://github.com/zammad/zammad/tree/1.3.0) (2017-02-15)
[Full Changelog](https://github.com/zammad/zammad/compare/1.2.0...1.3.0)

**Implemented enhancements:**

- Ticket without Subject is blocked - can't do anything with it \("Title needed"\) [\#719](https://github.com/zammad/zammad/issues/719) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Chat not working, web socket error in http/https mixed setup. Use protocol from script location of chat.js. [\#708](https://github.com/zammad/zammad/issues/708) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- user.preferences\['locale'\] not initialized at user creation [\#429](https://github.com/zammad/zammad/issues/429) [[bug](https://github.com/zammad/zammad/labels/bug)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Auto Focus on "Time Accounting" Popupbox [\#670](https://github.com/zammad/zammad/issues/670) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Do not import own notification emails in Zammad [\#731](https://github.com/zammad/zammad/issues/731) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Do not log last\_login in user history [\#722](https://github.com/zammad/zammad/issues/722) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Change font and font size in emails \(templates\) [\#718](https://github.com/zammad/zammad/issues/718) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Improve feature "show more" with "show less" option [\#570](https://github.com/zammad/zammad/issues/570) [[feature](https://github.com/zammad/zammad/labels/feature)]
- where to find version of zammad [\#264](https://github.com/zammad/zammad/issues/264) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- change default ticket\_priorities [\#728](https://github.com/zammad/zammad/issues/728) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**

- OTRS import breaks a lot of assumptions in Zammad [\#689](https://github.com/zammad/zammad/issues/689) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process emails if "Additional follow-up detection" was checked and unchecked again [\#740](https://github.com/zammad/zammad/issues/740) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Time accounting works only with dot [\#705](https://github.com/zammad/zammad/issues/705) [[bug](https://github.com/zammad/zammad/labels/bug)]
- "Close Tab" & "Next in Overview" don't work [\#730](https://github.com/zammad/zammad/issues/730) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing comma in 'manual button' causes syntax error [\#664](https://github.com/zammad/zammad/issues/664) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Prevent attachment preview in browser attachment download [\#617](https://github.com/zammad/zammad/issues/617) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Group follow up check for closed tickets does not work. [\#643](https://github.com/zammad/zammad/issues/643) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Feedback form not working in Safari [\#685](https://github.com/zammad/zammad/issues/685) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Changing Sound problem [\#219](https://github.com/zammad/zammad/issues/219) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process emails with email addresses longer then 140 signs. [\#650](https://github.com/zammad/zammad/issues/650) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Sending emails via SMTPS \(Port 465 and SSL\) not possible. [\#648](https://github.com/zammad/zammad/issues/648) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Error 500 opening a ticket view [\#639](https://github.com/zammad/zammad/issues/639) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Error 500 after upgrading to 1.2.0 \(existing Taskbar entries in DB\) [\#638](https://github.com/zammad/zammad/issues/638) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Customer get forced to save time for time accounting in customer interface - only allow it for agents. [\#636](https://github.com/zammad/zammad/issues/636) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to activate time accounting in admin interface. [\#633](https://github.com/zammad/zammad/issues/633) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Follow up detection not working if ticket\_hook\_position "none" is used. [\#686](https://github.com/zammad/zammad/issues/686) [[bug](https://github.com/zammad/zammad/labels/bug)]

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*