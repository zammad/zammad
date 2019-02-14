# Change Log

## [2.9.0](https://github.com/zammad/zammad/tree/2.9.0) (2019-02-14)
[Full Changelog](https://github.com/zammad/zammad/compare/2.8.0...2.9.0)

**Implemented enhancements:**
- Browser resize for pasted images is not resizing the image in edit view. [2422](https://github.com/zammad/zammad/issues/2422) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Unable to update already configured email channel, verify email will not arrive [2423](https://github.com/zammad/zammad/issues/2423) [[bug](https://github.com/zammad/zammad/labels/bug)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Option to switch the Full-Quote-Text on and off [2382](https://github.com/zammad/zammad/issues/2382) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)] [[noted](https://github.com/zammad/zammad/labels/noted)]
- Lock-symbol more distinguishable [945](https://github.com/zammad/zammad/issues/945) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[feature backlog](https://github.com/zammad/zammad/labels/feature backlog)]

**Fixed bugs:**
- No localised time displayed in trigger (autoreply/slack/...) notifications [1589](https://github.com/zammad/zammad/issues/1589) [[bug](https://github.com/zammad/zammad/labels/bug)] [[notification](https://github.com/zammad/zammad/labels/notification)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Attached images are broken on trigger reply with #{article.body_as_html} [2399](https://github.com/zammad/zammad/issues/2399) [[bug](https://github.com/zammad/zammad/labels/bug)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- mandatory fields can be empty (or "-") on ticket update [2242](https://github.com/zammad/zammad/issues/2242) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- UTF-8 encoded Email subjects like "=?UTF-8?Q? Personal=C3=A4nderung?=" not decoded [2456](https://github.com/zammad/zammad/issues/2456) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Zendesk ticket with 'On-hold' system status fails import [2439](https://github.com/zammad/zammad/issues/2439) [[bug](https://github.com/zammad/zammad/labels/bug)] [[import](https://github.com/zammad/zammad/labels/import)]
- Added Danish translations to Chat [2450](https://github.com/zammad/zammad/pull/2450) [[translation](https://github.com/zammad/zammad/labels/translation)]
- Missing validation for trigger.notification.* at Model/API/REST level. [2454](https://github.com/zammad/zammad/issues/2454) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Slow UI with over 150 ticket attributes [2452](https://github.com/zammad/zammad/issues/2452) [[bug](https://github.com/zammad/zammad/labels/bug)]
- square brackets are deleted in a link [2437](https://github.com/zammad/zammad/issues/2437) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Increased timeout for big attachments [2440](https://github.com/zammad/zammad/pull/2440)
- Unavailable ticket template attributes get applied [2424](https://github.com/zammad/zammad/issues/2424) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)]
- Unable to open customer chat widget via separate open button. [2435](https://github.com/zammad/zammad/issues/2435) [[bug](https://github.com/zammad/zammad/labels/bug)]
- HTML sanitizer blocks email processing because of an endless loop [2416](https://github.com/zammad/zammad/issues/2416) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Send all mails via sendmail - allow SMTP connection with no user/password (without auth) [224](https://github.com/zammad/zammad/issues/224) [[bug](https://github.com/zammad/zammad/labels/bug)] [[channel](https://github.com/zammad/zammad/labels/channel)]
- Zammad Icon (Bird) on page top left disappears and does not come back [2419](https://github.com/zammad/zammad/issues/2419) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[regression](https://github.com/zammad/zammad/labels/regression)]
- Unable to show ticket history [2420](https://github.com/zammad/zammad/issues/2420) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing table name quoting causes MySQL 8 incompatibility [2418](https://github.com/zammad/zammad/issues/2418) [[bug](https://github.com/zammad/zammad/labels/bug)]
- i-doit version >= 1.12 integration requests fail with 'Can’t fetch objects from...' [2412](https://github.com/zammad/zammad/issues/2412) [[bug](https://github.com/zammad/zammad/labels/bug)] [[integration](https://github.com/zammad/zammad/labels/integration)]
- Open Ticket List: Sort by "warten bis" - tickets containing a date show up within the middle [2367](https://github.com/zammad/zammad/issues/2367) [[bug](https://github.com/zammad/zammad/labels/bug)] [[overviews](https://github.com/zammad/zammad/labels/overviews)]
- Add a postmaster filter to not show emails with potential issue - Display a security message instead  [2390](https://github.com/zammad/zammad/issues/2390) [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Unable to load Zammad in web browser, because of online notification of ticket which was already deleted in the meantime [2405](https://github.com/zammad/zammad/issues/2405) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing custom object in database causes error on export in time_accounting [2398](https://github.com/zammad/zammad/issues/2398) [[bug](https://github.com/zammad/zammad/labels/bug)] [[time accounting](https://github.com/zammad/zammad/labels/time accounting)]
- Fix detection of local elasticsearch service [2404](https://github.com/zammad/zammad/pull/2404)
- Avatars' Alpha mask is removed by auto-conversion to JPG, leads to many graphical artifacts [1807](https://github.com/zammad/zammad/issues/1807) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[personal settings/menu](https://github.com/zammad/zammad/labels/personal settings/menu)]
- Unable to process emails without From (but with Sender) header. [2397](https://github.com/zammad/zammad/issues/2397) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Search term is deleted after I opened a object/ticket [2395](https://github.com/zammad/zammad/issues/2395) [[regression](https://github.com/zammad/zammad/labels/regression)]
- Jump to bottom after article has been created to show that the article has been saved. [2394](https://github.com/zammad/zammad/issues/2394)
- Wrong file size calculation in monitoring controller (postgres only) [2391](https://github.com/zammad/zammad/issues/2391) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Missing translation for Full-Quote-Text "on xy wrote" [2344](https://github.com/zammad/zammad/issues/2344) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[translation](https://github.com/zammad/zammad/labels/translation)]
