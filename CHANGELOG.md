# Change Log

## [2.7.1](https://github.com/zammad/zammad/tree/2.7.1) (2018-12-03)
[Full Changelog](https://github.com/zammad/zammad/compare/2.7.0...2.7.1)

**Implemented enhancements:**
- Logs flooded with article autosave data [2363](https://github.com/zammad/zammad/issues/2363) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Unable to process html email with 2k links in an acceptable time [2374](https://github.com/zammad/zammad/issues/2374) [[bug](https://github.com/zammad/zammad/labels/bug)] [[needs verification](https://github.com/zammad/zammad/labels/needs verification)]
- Zendesk-Import fails for User & Organizations if Plan is below "Team" [2262](https://github.com/zammad/zammad/issues/2262) [[bug](https://github.com/zammad/zammad/labels/bug)] [[import](https://github.com/zammad/zammad/labels/import)]
- Chat does not work due to errors in WebSocket (Database connection) [2353](https://github.com/zammad/zammad/issues/2353) [[bug](https://github.com/zammad/zammad/labels/bug)]
- selecting the overviews on the I Pad does not work [2330](https://github.com/zammad/zammad/issues/2330) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Lost DB connection causes jobs to not be processed anymore [2343](https://github.com/zammad/zammad/issues/2343) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Role-Filter shows inactive Roles [2332](https://github.com/zammad/zammad/issues/2332) [[admin area](https://github.com/zammad/zammad/labels/admin area)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- IMAP fetch stops because of request timeout [2321](https://github.com/zammad/zammad/issues/2321) [[bug](https://github.com/zammad/zammad/labels/bug)] [[channel](https://github.com/zammad/zammad/labels/channel)]
- Unable to import (update) users with email addresses als lookup index written in upper letters [2329](https://github.com/zammad/zammad/issues/2329) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Websocket messages are not working correctly via Ajax long polling (e. g. multiple browser tabs can get opened with one session). [2327](https://github.com/zammad/zammad/issues/2327) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Improved error handling of invalid tag for text modules and add current time format (to not use 2018-10-31T08:02:21.917Z format) [2324](https://github.com/zammad/zammad/issues/2324) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket list in overview of customer and organisation random order [2296](https://github.com/zammad/zammad/issues/2296) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Can't forward E-Mail in special cases within Firefox [2305](https://github.com/zammad/zammad/issues/2305) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]


## [2.7.0](https://github.com/zammad/zammad/tree/2.7.0) (2018-10-25)
[Full Changelog](https://github.com/zammad/zammad/compare/2.6.0...2.7.0)

**Implemented enhancements:**
- O365/Office365 authentication missing given- and surname [2281](https://github.com/zammad/zammad/issues/2281) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Callback issue when Zammad if internal and external FQDN differ [2223](https://github.com/zammad/zammad/issues/2223) [[CTI](https://github.com/zammad/zammad/labels/CTI)] [[admin area](https://github.com/zammad/zammad/labels/admin area)] [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Italian and Spanish translations for notifications. [2270](https://github.com/zammad/zammad/issues/2270) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Make stats store and cti log searchable via elastichsearch & destroy stats store if user got deleted [2261](https://github.com/zammad/zammad/issues/2261) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Global Bcc for all outgoing emails for external archive options. [2228](https://github.com/zammad/zammad/issues/2228) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Added custom notification templates to make changes update save [2081](https://github.com/zammad/zammad/pull/2081) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[notification](https://github.com/zammad/zammad/labels/notification)]
- WebApp (monitoring section) claims scheduler not running, if delayed jobs get too many [2188](https://github.com/zammad/zammad/issues/2188) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Reindex elastic search not possible because of <null>/Twitter::NullObject [1394](https://github.com/zammad/zammad/issues/1394) [[bug](https://github.com/zammad/zammad/labels/bug)]
- `rake searchindex:rebuild` is not working after Elasticsearch 2.4 upgrade to Elasticsearch 5.6 "Limit of total fields [1000] in index" [2297](https://github.com/zammad/zammad/issues/2297) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Update bot_add.jst.eco [2295](https://github.com/zammad/zammad/pull/2295)
- CTI Log: duration_talking_time is incorrect and after update initialized_at is a string (not timestamp) [2292](https://github.com/zammad/zammad/issues/2292) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Performance issue in bulk action selection in overview [2279](https://github.com/zammad/zammad/issues/2279) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)] [[overviews](https://github.com/zammad/zammad/labels/overviews)] [[regression](https://github.com/zammad/zammad/labels/regression)]
- Note is not shown for customer / organisations if it's empty. [2277](https://github.com/zammad/zammad/issues/2277) [[bug](https://github.com/zammad/zammad/labels/bug)] [[regression](https://github.com/zammad/zammad/labels/regression)]
- Permission issue: response templates only usable when admin is also agent [2285](https://github.com/zammad/zammad/issues/2285) [[admin area](https://github.com/zammad/zammad/labels/admin area)] [[bug](https://github.com/zammad/zammad/labels/bug)]
- Bulk Form javascript error when checking item [2273](https://github.com/zammad/zammad/issues/2273) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)] [[needs verification](https://github.com/zammad/zammad/labels/needs verification)] [[overviews](https://github.com/zammad/zammad/labels/overviews)] [[regression](https://github.com/zammad/zammad/labels/regression)]
- Records in Reporting not updated when single ActiveRecord can not be found [2246](https://github.com/zammad/zammad/issues/2246) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Users deactivated by the LDAP sync get updated on every run [2256](https://github.com/zammad/zammad/issues/2256) [[LDAP](https://github.com/zammad/zammad/labels/LDAP)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[integration](https://github.com/zammad/zammad/labels/integration)]
- Search with id:123 does not work anymore [2195](https://github.com/zammad/zammad/issues/2195) [[bug](https://github.com/zammad/zammad/labels/bug)] [[search](https://github.com/zammad/zammad/labels/search)]
- Update zammad_ssl.conf [2269](https://github.com/zammad/zammad/pull/2269)
- Fix failing Travis CI build [2268](https://github.com/zammad/zammad/pull/2268)
- Every session comes from 127.0.0.1 [742](https://github.com/zammad/zammad/issues/742) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Reply does not work as expected [2184](https://github.com/zammad/zammad/issues/2184) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Invalid date causes errors [2173](https://github.com/zammad/zammad/issues/2173) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Check the correct hash array if the agent is present [2243](https://github.com/zammad/zammad/pull/2243) [[bug](https://github.com/zammad/zammad/labels/bug)] [[needs verification](https://github.com/zammad/zammad/labels/needs verification)]
- CTI: Limit used caller log states and prevent race conditions (if callback comes later) [2255](https://github.com/zammad/zammad/issues/2255) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Boolean object set to false is not visible [2233](https://github.com/zammad/zammad/issues/2233) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Unable to process spam email `"ERROR: #<Exceptions::UnprocessableEntity: Invalid email>"` [2254](https://github.com/zammad/zammad/issues/2254) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to index elasticsearch if article.preferences[:delivery_status_message] has no uf8 charset [2253](https://github.com/zammad/zammad/issues/2253) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process email `"ERROR: #<NoMethodError: undefined method `match' for nil:NilClass>"` [2252](https://github.com/zammad/zammad/issues/2252) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Fixed typo in 404: Ressource -> resource [2251](https://github.com/zammad/zammad/pull/2251)
- Unable to process spam mail with invalid date field [2245](https://github.com/zammad/zammad/issues/2245) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Bulk action should not be shown if user has no change permissions [2026](https://github.com/zammad/zammad/issues/2026) [[bug](https://github.com/zammad/zammad/labels/bug)] [[bulk](https://github.com/zammad/zammad/labels/bulk)] [[frontend](https://github.com/zammad/zammad/labels/frontend)] [[overviews](https://github.com/zammad/zammad/labels/overviews)]
- Naming an attribute "attribute" causes ActiveRecord failure [2236](https://github.com/zammad/zammad/issues/2236) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Overview setting isn't applied on submit [2235](https://github.com/zammad/zammad/issues/2235) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Also not active report profiles are shown in #report screen [2232](https://github.com/zammad/zammad/issues/2232) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP/Exchange UTF-8 Status Code 500 [2140](https://github.com/zammad/zammad/issues/2140) [[LDAP](https://github.com/zammad/zammad/labels/LDAP)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[import](https://github.com/zammad/zammad/labels/import)]
- In overviews conditions the tag name (not the tag id) is stored. Renaming tags will break overviews condition [1690](https://github.com/zammad/zammad/issues/1690) [[bug](https://github.com/zammad/zammad/labels/bug)] [[overviews](https://github.com/zammad/zammad/labels/overviews)]
- Wrong Recent viewed tickets list [2194](https://github.com/zammad/zammad/issues/2194) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Unprocessable email ERROR: #<ArgumentError: invalid byte sequence in UTF-8> [2227](https://github.com/zammad/zammad/issues/2227) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process email (Encoding::ConverterNotFoundError: code converter not found (Windows-1258 to UTF-8)) [2224](https://github.com/zammad/zammad/issues/2224) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Printed documents do not contain the whole ticket content, if it gets too much [2162](https://github.com/zammad/zammad/issues/2162) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Email IMAP fetch stops working if mailserver is once unreachable [1861](https://github.com/zammad/zammad/issues/1861) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to use exchange sync (stack level too deep (SystemStackError)) [2220](https://github.com/zammad/zammad/issues/2220) [[bug](https://github.com/zammad/zammad/labels/bug)] [[integration](https://github.com/zammad/zammad/labels/integration)]
- Exchange import fails if folder names can't be converted to Unicode [2152](https://github.com/zammad/zammad/issues/2152) [[bug](https://github.com/zammad/zammad/labels/bug)] [[import](https://github.com/zammad/zammad/labels/import)] [[waiting for feedback](https://github.com/zammad/zammad/labels/waiting for feedback)]
- CTI Caller Log blocks user deletion/destroy and fails [2218](https://github.com/zammad/zammad/issues/2218) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Can't process email with space in email [2198](https://github.com/zammad/zammad/issues/2198) [[bug](https://github.com/zammad/zammad/labels/bug)] [[mail processing](https://github.com/zammad/zammad/labels/mail processing)]
- Unprocessable Mail if sender contains http.net@ [2199](https://github.com/zammad/zammad/issues/2199) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Call log shows only orga infos on event, not on site load [2075](https://github.com/zammad/zammad/issues/2075) [[CTI](https://github.com/zammad/zammad/labels/CTI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)] [[needs verification](https://github.com/zammad/zammad/labels/needs verification)]
- Chat-Widget disappears after close [2197](https://github.com/zammad/zammad/issues/2197) [[bug](https://github.com/zammad/zammad/labels/bug)] [[chat](https://github.com/zammad/zammad/labels/chat)]
- work around for outlook feature that breaks email address standard [2154](https://github.com/zammad/zammad/issues/2154) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Upgrade from 2.0 to 2.5 db migrations canceled [2159](https://github.com/zammad/zammad/issues/2159) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)] [[update](https://github.com/zammad/zammad/labels/update)] [[waiting for feedback](https://github.com/zammad/zammad/labels/waiting for feedback)]
- Order of relation select fields (Group, State etc.) values is broken [2209](https://github.com/zammad/zammad/issues/2209) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Unable to modify tree_select attributes with fresh 2.6 [2206](https://github.com/zammad/zammad/issues/2206) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Max size of tabs is not recognised [2204](https://github.com/zammad/zammad/issues/2204) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to process email `EncodingError: could not find a valid input encoding` [2200](https://github.com/zammad/zammad/issues/2200) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Email - full quote time specification [1426](https://github.com/zammad/zammad/issues/1426) [[feature backlog](https://github.com/zammad/zammad/labels/feature backlog)] [[ticket](https://github.com/zammad/zammad/labels/ticket)]
- Bulk-Action: Not possible to change owner [1864](https://github.com/zammad/zammad/issues/1864) [[UX/UI](https://github.com/zammad/zammad/labels/UX/UI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
- Incorrect reset after deleting single object-selection [2020](https://github.com/zammad/zammad/issues/2020) [[bug](https://github.com/zammad/zammad/labels/bug)] [[object manager attribute](https://github.com/zammad/zammad/labels/object manager attribute)]
- Puma performance is going worst if users with phone attribute are updated or new tickets are created. [2193](https://github.com/zammad/zammad/issues/2193) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Sometimes automatisation is not executed [2191](https://github.com/zammad/zammad/issues/2191) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Problem while updating to 2.6: Mysql2::Error: Invalid default value for 'start_at' [2183](https://github.com/zammad/zammad/issues/2183) [[bug](https://github.com/zammad/zammad/labels/bug)] [[update](https://github.com/zammad/zammad/labels/update)]
- LDAP / Exchange update (save!) records unnecessarily [2187](https://github.com/zammad/zammad/issues/2187) [[bug](https://github.com/zammad/zammad/labels/bug)] [[import](https://github.com/zammad/zammad/labels/import)]
- Overview not showing unassigned tickets "if not defined" (e. g. for owner but also for select or input fields) [2171](https://github.com/zammad/zammad/issues/2171) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Incorrect encoding of email messages in HTML format (Windows-1250) [2167](https://github.com/zammad/zammad/issues/2167) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Call-Log shows inactive users [2096](https://github.com/zammad/zammad/issues/2096) [[CTI](https://github.com/zammad/zammad/labels/CTI)] [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)]
