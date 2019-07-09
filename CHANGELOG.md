# Change Log

## [3.0.1](https://github.com/zammad/zammad/tree/3.0.1) (2019-07-10)
[Full Changelog](https://github.com/zammad/zammad/compare/3.0.0...3.0.1)

**Implemented enhancements:**

**Fixed bugs:**
- Concern 'CanLatestChange' returns wrong updated_at  [2624](https://github.com/zammad/zammad/issues/2624) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tree Select shows empty value in ticket zoom after submit when value contains trailing spaces [2614](https://github.com/zammad/zammad/issues/2614) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- KB partly broken on IE11 - customer interface [2600](https://github.com/zammad/zammad/issues/2600) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge base)]
- Wrong date format in Excel Exports of reporting download [2594](https://github.com/zammad/zammad/issues/2594) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Edit-Buttons on customer interface (as agent) has wrong link (Blank-Page) [2604](https://github.com/zammad/zammad/issues/2604) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge base)]
- Activation of Knowledgebase is impossible on IE11 - agent interface [2599](https://github.com/zammad/zammad/issues/2599) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge base)]
- Existing scheduler email notification without `body` will raise an exception. [2541](https://github.com/zammad/zammad/issues/2541) [[bug](https://github.com/zammad/zammad/labels/bug)]
- trigger email notification UI defective on removal of recipient [2516](https://github.com/zammad/zammad/issues/2516) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)]

## [3.0.0](https://github.com/zammad/zammad/tree/3.0.0) (2019-06-06)
[Full Changelog](https://github.com/zammad/zammad/compare/2.9.0...3.0.0)

**Implemented enhancements:**
- Implemented Zammad Knowledge Base.
- Apply changes (updated or if channel is deleted) to email channel even if channel is already fetching emails. [2552](https://github.com/zammad/zammad/issues/2552) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Not used SQL index with postgresql in certain cases on very large setups. [2530](https://github.com/zammad/zammad/issues/2530) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Ensure Zammad only updates affected content (affects several) [2431](https://github.com/zammad/zammad/issues/2431) [[bug](https://github.com/zammad/zammad/labels/bug)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Add information "Ticket merged" to History [2469](https://github.com/zammad/zammad/issues/2469) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[ticket](https://github.com/zammad/zammad/labels/ticket)]

**Fixed bugs:**
- Attached textfiles break "RAW"-Link if last attachment in list [2518](https://github.com/zammad/zammad/issues/2518) [[bug](https://github.com/zammad/zammad/labels/bug)] [[ticket](https://github.com/zammad/zammad/labels/ticket)]
- Zammad Customers shown as Agents in IE [2510](https://github.com/zammad/zammad/issues/2510) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Double-click timeout in ticket zoom too short [2586](https://github.com/zammad/zammad/issues/2586) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- Every night tickets are updated (system need to use SLAs) [2574](https://github.com/zammad/zammad/issues/2574) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Agents should always be able to re-open closed tickets, regardless of group.follow_up_possible [2534](https://github.com/zammad/zammad/issues/2534) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Downloading of emails via IMAP takes longer as one minute. E-Mail seems to be lost. [2554](https://github.com/zammad/zammad/issues/2554) [[bug](https://github.com/zammad/zammad/labels/bug)]
- allow agents to always reopen tickets, regardless of group.follow_up_possible [2531](https://github.com/zammad/zammad/pull/2531)
- Incorrect display count of a report profile if tree_select is used [2059](https://github.com/zammad/zammad/issues/2059) [[bug](https://github.com/zammad/zammad/labels/bug)]
- users_controller.rb: search: pagination broken [2539](https://github.com/zammad/zammad/issues/2539) [[API](https://github.com/zammad/zammad/labels/API)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[regression](https://github.com/zammad/zammad/labels/regression)] [[search](https://github.com/zammad/zammad/labels/search)]
- Existing scheduler email notification without `body` will raise an exception. [2541](https://github.com/zammad/zammad/issues/2541) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Attached text files get prepended on e-mail reply instead of appended. [2362](https://github.com/zammad/zammad/issues/2362) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- timezone issue with report graphs not displaying or displaying $timezone hours out of step [2089](https://github.com/zammad/zammad/issues/2089) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Zammad Webcam-Avatar-Feature broken [2514](https://github.com/zammad/zammad/issues/2514) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)]
- Required field is not required on updating tickets [1259](https://github.com/zammad/zammad/issues/1259) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)] [[ticket](https://github.com/zammad/zammad/labels/ticket)]
- #{article.body_as_html} now includes attachments (e.g. PDFs) [2483](https://github.com/zammad/zammad/issues/2483) [[bug](https://github.com/zammad/zammad/labels/bug)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Missing business hours validation for calendars creates infinitive loop (also for background jobs) [2497](https://github.com/zammad/zammad/issues/2497) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Login into Zammad not possible, application server `puma` will raise 100% or more cpu  [2504](https://github.com/zammad/zammad/issues/2504) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Fixes #2491 - Email is not processed if filename of attachement is just a  "space" like `Content-Disposition: inline; filename="=?utf-8?b??="`. [2491](https://github.com/zammad/zammad/issues/2491) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process email on CentOS with large images but only 1px height [2486](https://github.com/zammad/zammad/issues/2486) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Mails send by older mailers with x-uuencode Content-Transfer-Encoding of attachments are not processable [2464](https://github.com/zammad/zammad/issues/2464) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Finnish translation to the chat [2480](https://github.com/zammad/zammad/pull/2480)
- Unable to update ticket with IE11 [2478](https://github.com/zammad/zammad/issues/2478) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)] [[regression](https://github.com/zammad/zammad/labels/regression)]





