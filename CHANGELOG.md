# Change Log

## [6.3.1](https://github.com/zammad/zammad/tree/6.3.1) (2024-05-15)

[Full Changelog](https://github.com/zammad/zammad/compare/6.3.0...6.3.1)

**Implemented enhancements:**

- User login flow is interrupted when two-factor authentication method security keys is used [5156](https://github.com/zammad/zammad/issues/5156) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)] [[UX/UI](https://github.com/zammad/zammad/labels/UX%2FUI)] [[authentication](https://github.com/zammad/zammad/labels/authentication)]

**Fixed bugs:**

- Ticket history shows html when updating articles [5168](https://github.com/zammad/zammad/issues/5168) [[bug](https://github.com/zammad/zammad/labels/bug)]
- contrib/packager.io/preinstall.sh does not check the db adapter setting and fails if both psql and mysql are installed [5142](https://github.com/zammad/zammad/issues/5142) [[needs verification](https://github.com/zammad/zammad/labels/needs%20verification)]
- fixes #5142| fix db check in preinstall.sh [5143](https://github.com/zammad/zammad/pull/5143)
- Public Knowledge Base Bread crumbs unexpectly translated [5145](https://github.com/zammad/zammad/issues/5145) [[bug](https://github.com/zammad/zammad/labels/bug)] [[translation](https://github.com/zammad/zammad/labels/translation)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge%20base)]
- Ticket templates creation interface is broken if a Ticket attribute has a lengthy name. [5000](https://github.com/zammad/zammad/issues/5000) [[bug](https://github.com/zammad/zammad/labels/bug)]
- IllegalArgumentException on reports with time range in report profile and time selection in the report UI [5105](https://github.com/zammad/zammad/issues/5105) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- [CTI] Caller is not identified if the caller has only entered a telephone number (no firstname, lastname, email). [5117](https://github.com/zammad/zammad/issues/5117) [[bug](https://github.com/zammad/zammad/labels/bug)]
- ".value" in text modules for external data sources breaks ticket zoom [5115](https://github.com/zammad/zammad/issues/5115) [[bug](https://github.com/zammad/zammad/labels/bug)] [[frontend](https://github.com/zammad/zammad/labels/frontend)] [[variable processing](https://github.com/zammad/zammad/labels/variable%20processing)]
- Wrong background color for ticket creation links in light mode [5144](https://github.com/zammad/zammad/issues/5144) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX%2FUI)]
- Fetching LdapSource for unknown users fails [5101](https://github.com/zammad/zammad/issues/5101) [[bug](https://github.com/zammad/zammad/labels/bug)] [[LDAP](https://github.com/zammad/zammad/labels/LDAP)]
- Unable to send WhatsApp automatic reminders after 23 hours [5139](https://github.com/zammad/zammad/issues/5139) [[bug](https://github.com/zammad/zammad/labels/bug)] [[translation](https://github.com/zammad/zammad/labels/translation)] [[localization](https://github.com/zammad/zammad/labels/localization)]
- Reporting: Worse performance because UI always request all aggregation data instead of the selection [5138](https://github.com/zammad/zammad/issues/5138) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)] [[performance](https://github.com/zammad/zammad/labels/performance)]
- Reporting: No button and output when no tickets found in a time range [5137](https://github.com/zammad/zammad/issues/5137) [[bug](https://github.com/zammad/zammad/labels/bug)] [[UX/UI](https://github.com/zammad/zammad/labels/UX%2FUI)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Once applied kb editor permissions cannot be revoked [5123](https://github.com/zammad/zammad/issues/5123) [[bug](https://github.com/zammad/zammad/labels/bug)] [[knowledge base](https://github.com/zammad/zammad/labels/knowledge%20base)]
- Duplicates in calendar [5076](https://github.com/zammad/zammad/issues/5076) [[bug](https://github.com/zammad/zammad/labels/bug)] [[calendar](https://github.com/zammad/zammad/labels/calendar)]
