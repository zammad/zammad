# Change Log

## [3.2.0](https://github.com/zammad/zammad/tree/3.2.0) (2019-xx-xx)
[Full Changelog](https://github.com/zammad/zammad/compare/3.1.0...3.2.0)

**Implemented enhancements:**
- Enhance tag search to use fulltext search [2569](https://github.com/zammad/zammad/issues/2569) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[ticket](https://github.com/zammad/zammad/labels/ticket)]
- translation strings wrong [1561](https://github.com/zammad/zammad/issues/1561) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[translation](https://github.com/zammad/zammad/labels/translation)]
- Misleading 'Escalation' ticket attribute name in SLAs, Scheduler and Trigger should be named 'Escalation_at' [2615](https://github.com/zammad/zammad/issues/2615) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Add scroll bar to tag list if not enough room is available [2570](https://github.com/zammad/zammad/issues/2570) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Elasticsearch 6.x & 7.x support [1688](https://github.com/zammad/zammad/issues/1688) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- SearchIndexBackend.remove() (ES) is not working correctly [2611](https://github.com/zammad/zammad/issues/2611) [[bug](https://github.com/zammad/zammad/labels/bug)] [[search](https://github.com/zammad/zammad/labels/search)]
- Add Rails 5 log to STDOUT env variable support [2637](https://github.com/zammad/zammad/pull/2637)
- Removed duplicate `Mailing-List` tag from postmaster match ui element [2639](https://github.com/zammad/zammad/pull/2639) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Integer minimal is ignored [2339](https://github.com/zammad/zammad/issues/2339) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Setup asks for FQDN, but doesn't write to DB [462](https://github.com/zammad/zammad/issues/462) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Concern 'CanLatestChange' returns wrong updated_at  [2624](https://github.com/zammad/zammad/issues/2624) [[bug](https://github.com/zammad/zammad/labels/bug)]
- KB partly broken on IE11 - customer interface [2600](https://github.com/zammad/zammad/issues/2600) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge base)]
- missing OTRS.png asset in Import Wizard [2593](https://github.com/zammad/zammad/issues/2593) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)] [[import](https://github.com/zammad/zammad/labels/import)]
- Wrong date format in Excel Exports of reporting download [2594](https://github.com/zammad/zammad/issues/2594) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Tree Select shows empty value in ticket zoom after submit when value contains trailing spaces [2614](https://github.com/zammad/zammad/issues/2614) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Edit-Buttons on customer interface (as agent) has wrong link (Blank-Page) [2604](https://github.com/zammad/zammad/issues/2604) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge base)]
- Activation of Knowledgebase is impossible on IE11 - agent interface [2599](https://github.com/zammad/zammad/issues/2599) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge base)]
- Existing scheduler email notification without `body` will raise an exception. [2541](https://github.com/zammad/zammad/issues/2541) [[bug](https://github.com/zammad/zammad/labels/bug)]
- trigger email notification UI defective on removal of recipient [2516](https://github.com/zammad/zammad/issues/2516) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend / JS app](https://github.com/zammad/zammad/labels/frontend / JS app)]
