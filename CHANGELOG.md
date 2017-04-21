# Change Log


## [1.4.1](https://github.com/zammad/zammad/tree/1.4.1) (2017-04-21)
[Full Changelog](https://github.com/zammad/zammad/compare/1.4.0...1.4.1)

**Fixed bugs:**
- Fixed issue #912 - Long Twitter direct messages are shown as link after 140 chars. [\#912](https://github.com/zammad/zammad/issues/912) [[enhancement](https://github.com/zammad/zammad/labels/bug)]
- External links in html emails will be open in local context [\#952](https://github.com/zammad/zammad/issues/952) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Schedules - Disable Notification not changable [\#897](https://github.com/zammad/zammad/issues/897) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Auto detection of www urls fails [\#951](https://github.com/zammad/zammad/issues/951) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't use PUT on Organizations REST API with token access [\#902](https://github.com/zammad/zammad/issues/902) [[bug](https://github.com/zammad/zammad/labels/bug)]
- After a while a 500er error message appears  [\#936](https://github.com/zammad/zammad/issues/936) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Template assigned to all new tickets tabs [\#931](https://github.com/zammad/zammad/issues/931) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Placeholder in triggers with created\_by & updated\_by / \> in article.body [\#883](https://github.com/zammad/zammad/issues/883) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Changing "Product Name" breaks "Admin" menu [\#859](https://github.com/zammad/zammad/issues/859) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Follow up detection is broken for Ticket::Number::Date ticket number generator. [\#899](https://github.com/zammad/zammad/issues/899) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Sending emails fails sometimes because of wrong used channel/sender email address [\#889](https://github.com/zammad/zammad/issues/889) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Some notifications are marked as read initially [\#887](https://github.com/zammad/zammad/issues/887) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- activity stream or online notifications are sometimes empty [\#858](https://github.com/zammad/zammad/issues/858) [[bug](https://github.com/zammad/zammad/labels/bug)]


## [1.4.0](https://github.com/zammad/zammad/tree/1.4.0) (2017-03-16)
[Full Changelog](https://github.com/zammad/zammad/compare/1.3.0...1.4.0)

**Implemented enhancements:**

- Show images of incoming html inline images [\#343](https://github.com/zammad/zammad/issues/343) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- email filter issues - unable to set additional ticket attributes [\#394](https://github.com/zammad/zammad/issues/394) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Auto-assign ticket owner on first reply [\#395](https://github.com/zammad/zammad/issues/395) [[feature](https://github.com/zammad/zammad/labels/feature)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Stiked out text displayed as normal text [\#807](https://github.com/zammad/zammad/issues/807) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- New ticket object attributes won't disappear in Triggers and SLAs [\#436](https://github.com/zammad/zammad/issues/436) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]


**Fixed bugs:**

- Extended characters on AD users causes weird OTRS import issues [\#842](https://github.com/zammad/zammad/issues/842) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Customer names are sometimes wrapped with quotes [\#763](https://github.com/zammad/zammad/issues/763) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unprocessable emails [\#795](https://github.com/zammad/zammad/issues/795) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Overly exact gauge at re-opening rate [\#843](https://github.com/zammad/zammad/issues/843) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Wrong encoded string [\#438](https://github.com/zammad/zammad/issues/438) [[bug](https://github.com/zammad/zammad/labels/bug)]
- multiplication of the attachment-field in \#channels/form [\#833](https://github.com/zammad/zammad/issues/833) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Disabled macros are still shown in ticket screen [\#838](https://github.com/zammad/zammad/issues/838) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't select object with type date as filter for overviews [\#821](https://github.com/zammad/zammad/issues/821) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Simple triggers resulting in error condition [\#779](https://github.com/zammad/zammad/issues/779) [[bug](https://github.com/zammad/zammad/labels/bug)]
- trigger "set to public" requested [\#298](https://github.com/zammad/zammad/issues/298) [[bug](https://github.com/zammad/zammad/labels/bug)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- User password reset doesn't work - user not able to login [\#791](https://github.com/zammad/zammad/issues/791) [[bug](https://github.com/zammad/zammad/labels/bug)]
- admin interface -\> time accounting setting will not be saved [\#677](https://github.com/zammad/zammad/issues/677) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Checkboxes im merge dialog won't show until one clicks [\#786](https://github.com/zammad/zammad/issues/786) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)]
- Telegram: Open communication with only a picture [\#774](https://github.com/zammad/zammad/issues/774) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Some adjustments with regard to \#698 [\#783](https://github.com/zammad/zammad/pull/783) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] ([johan12345](https://github.com/johan12345))

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*