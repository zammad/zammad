# Change Log

## [2.8.0](https://github.com/zammad/zammad/tree/2.8.0) (2018-12-03)
[Full Changelog](https://github.com/zammad/zammad/compare/2.7.0...2.8.0)

**Implemented enhancements:**
- Twitter Account Activity API support [2023](https://github.com/zammad/zammad/issues/2023) [[channel](https://github.com/zammad/zammad/labels/channel)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- On large database indexes at missing [2368](https://github.com/zammad/zammad/issues/2368) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Elasticsearch payload is going to big if a ticket has more then 9000 articles [2345](https://github.com/zammad/zammad/issues/2345) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Logs flooded with article autosave data [2363](https://github.com/zammad/zammad/issues/2363) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Increased popup width for text modules or placeholder list [2335](https://github.com/zammad/zammad/pull/2335) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]

**Fixed bugs:**
- Unable to process html email with 2k links in an acceptable time [2374](https://github.com/zammad/zammad/issues/2374) [[bug](https://github.com/zammad/zammad/labels/bug)] [[needs verification](https://github.com/zammad/zammad/labels/needs verification)]
- Column width is resized to a non readable minimum [2031](https://github.com/zammad/zammad/issues/2031) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zendesk-Import fails for User & Organizations if Plan is below "Team" [2262](https://github.com/zammad/zammad/issues/2262) [[bug](https://github.com/zammad/zammad/labels/bug)] [[import](https://github.com/zammad/zammad/labels/import)]
- Update italian translations for chat messages [2359](https://github.com/zammad/zammad/pull/2359)
- Chat does not work due to errors in WebSocket (Database connection) [2353](https://github.com/zammad/zammad/issues/2353) [[bug](https://github.com/zammad/zammad/labels/bug)]
- selecting the overviews on the I Pad does not work [2330](https://github.com/zammad/zammad/issues/2330) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Update de.html.erb [2348](https://github.com/zammad/zammad/pull/2348)
- Lost DB connection causes jobs to not be processed anymore [2343](https://github.com/zammad/zammad/issues/2343) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Role-Filter shows inactive Roles [2332](https://github.com/zammad/zammad/issues/2332) [[admin area](https://github.com/zammad/zammad/labels/admin area)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- IMAP fetch stops because of request timeout [2321](https://github.com/zammad/zammad/issues/2321) [[bug](https://github.com/zammad/zammad/labels/bug)] [[channel](https://github.com/zammad/zammad/labels/channel)]
- Object country already exists [2333](https://github.com/zammad/zammad/issues/2333) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Upgrade to Zammad 2.7 was not possible (migration 20180220171219 CheckForObjectAttributes failed) [2318](https://github.com/zammad/zammad/issues/2318) [[bug](https://github.com/zammad/zammad/labels/bug)] [[migration](https://github.com/zammad/zammad/labels/migration)]
- Unable to import (update) users with email addresses als lookup index written in upper letters [2329](https://github.com/zammad/zammad/issues/2329) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Websocket messages are not working correctly via Ajax long polling (e. g. multiple browser tabs can get opened with one session). [2327](https://github.com/zammad/zammad/issues/2327) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Improved error handling of invalid tag for text modules and add current time format (to not use 2018-10-31T08:02:21.917Z format) [2324](https://github.com/zammad/zammad/issues/2324) [[bug](https://github.com/zammad/zammad/labels/bug)]
- incorrect notification when closing a tab after setting up an object [2042](https://github.com/zammad/zammad/issues/2042) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Ticket list in overview of customer and organisation random order [2296](https://github.com/zammad/zammad/issues/2296) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- ObjectManager Attribute Select used in trigger will show internal ID instead of value [1568](https://github.com/zammad/zammad/issues/1568) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)] [[trigger](https://github.com/zammad/zammad/labels/trigger)]
- Can't forward E-Mail in special cases within Firefox [2305](https://github.com/zammad/zammad/issues/2305) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
