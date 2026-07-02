/** Internal type. DO NOT USE DIRECTLY. */
type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
/** Internal type. DO NOT USE DIRECTLY. */
export type Incremental<T> = T | { [P in keyof T]?: P extends ' $fragmentName' | '__typename' ? T[P] : never };
import type * as Types from './schema-types';

export * from './schema-types'
export type { Exact }
export type BetaUiSendFeedbackMutationVariables = Exact<{
  input: Types.BetaUiFeedbackInput;
}>;


export type BetaUiSendFeedbackMutation = { betaUiSendFeedback: { __typename: 'BetaUiSendFeedbackPayload', success: boolean } | null | undefined };

export type OrganizationInfoForPopoverQueryVariables = Exact<{
  organizationId: string | number;
  membersCount?: number | null | undefined;
}>;


export type OrganizationInfoForPopoverQuery = { organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, domain: string | null | undefined, domainAssignment: boolean | null | undefined, active: boolean | null | undefined, note: string | null | undefined, vip: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, allMembers: { __typename: 'UserConnection', totalCount: number, edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, internalId: number, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined } }> } | null | undefined } };

export type DetailSearchQueryVariables = Exact<{
  search: string;
  onlyIn: Types.EnumSearchableModels;
  filter?: Types.SelectorNodeInput | null | undefined;
  limit?: number | null | undefined;
  offset?: number | null | undefined;
  orderBy?: string | null | undefined;
  orderDirection?: Types.EnumOrderDirection | null | undefined;
}>;


export type DetailSearchQuery = { search: { __typename: 'SearchResult', totalCount: number, items: Array<
      | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, active: boolean | null | undefined }
      | { __typename: 'Ticket', id: string, internalId: number, title: string, number: string, stateColorCode: Types.EnumTicketStateColorCode, createdAt: string, customer: { __typename: 'User', id: string, fullname: string | null | undefined }, owner: { __typename: 'User', id: string, fullname: string | null | undefined }, group: { __typename: 'Group', id: string, name: string | null | undefined }, state: { __typename: 'TicketState', id: string, name: string }, priority: { __typename: 'TicketPriority', id: string, name: string, uiColor: string | null | undefined }, policy: { __typename: 'PolicyTicket', update: boolean } }
      | { __typename: 'User', id: string, internalId: number, login: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, active: boolean | null | undefined, organization: { __typename: 'Organization', id: string, name: string | null | undefined } | null | undefined, secondaryOrganizations: { __typename: 'OrganizationConnection', totalCount: number, edges: Array<{ __typename: 'OrganizationEdge', node: { __typename: 'Organization', id: string, name: string | null | undefined } }> } | null | undefined }
    > } };

export type QuickSearchQueryVariables = Exact<{
  search: string;
  limit?: number | null | undefined;
}>;


export type QuickSearchQuery = { quickSearchOrganizations: { __typename: 'SearchResult', totalCount: number, items: Array<
      | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
      | { __typename: 'Ticket' }
      | { __typename: 'User' }
    > }, quickSearchTickets: { __typename: 'SearchResult', totalCount: number, items: Array<
      | { __typename: 'Organization' }
      | { __typename: 'Ticket', id: string, internalId: number, title: string, number: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }
      | { __typename: 'User' }
    > }, quickSearchUsers: { __typename: 'SearchResult', totalCount: number, items: Array<
      | { __typename: 'Organization' }
      | { __typename: 'Ticket' }
      | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
    > } };

export type SearchCountsQueryVariables = Exact<{
  search: string;
  onlyIn: Array<Types.EnumSearchableModels> | Types.EnumSearchableModels;
  filters?: Array<Types.SelectorObjectInput> | Types.SelectorObjectInput | null | undefined;
}>;


export type SearchCountsQuery = { searchCounts: Array<{ __typename: 'SearchCountsResult', model: Types.EnumSearchableModels, totalCount: number }> };

export type SearchTaskbarItemStateUpdatesSubscriptionVariables = Exact<{
  taskbarItemId: string | number;
}>;


export type SearchTaskbarItemStateUpdatesSubscription = { userCurrentTaskbarItemStateUpdates: { __typename: 'UserCurrentTaskbarItemStateUpdatesPayload', stateUpdateType: Types.EnumTaskbarStateUpdate | null | undefined, taskbarItem: { __typename: 'UserTaskbarItem', id: string, entity:
        | { __typename: 'Organization' }
        | { __typename: 'Ticket' }
        | { __typename: 'User' }
        | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
        | { __typename: 'UserTaskbarItemEntityTicketCreate' }
       | null | undefined } | null | undefined } };

export type TicketInfoForPopoverQueryVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketInfoForPopoverQuery = { ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, stateColorCode: Types.EnumTicketStateColorCode, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string } } };

export type UserInfoForPopoverQueryVariables = Exact<{
  userId: string | number;
  secondaryOrganizationsCount?: number | null | undefined;
  after?: string | null | undefined;
}>;


export type UserInfoForPopoverQuery = { user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, image: string | null | undefined, email: string | null | undefined, web: string | null | undefined, vip: boolean | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, fax: string | null | undefined, note: string | null | undefined, source: string | null | undefined, verified: boolean | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined } | null | undefined, secondaryOrganizations: { __typename: 'OrganizationConnection', totalCount: number, edges: Array<{ __typename: 'OrganizationEdge', node: { __typename: 'Organization', id: string, internalId: number, active: boolean | null | undefined, name: string | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined } };

export type CalendarIcsFileEventsQueryVariables = Exact<{
  fileId: string | number;
}>;


export type CalendarIcsFileEventsQuery = { calendarIcsFileEvents: Array<{ __typename: 'CalendarIcsFileEvent', title: string | null | undefined, location: string | null | undefined, startDate: string | null | undefined, endDate: string | null | undefined, organizer: string | null | undefined, attendees: Array<string> | null | undefined, description: string | null | undefined }> };

export type ChannelEmailAddMutationVariables = Exact<{
  input: Types.ChannelEmailAddInput;
}>;


export type ChannelEmailAddMutation = { channelEmailAdd: { __typename: 'ChannelEmailAddPayload', channel: { __typename: 'Channel', options: any, group: { __typename: 'Group', id: string } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type ChannelEmailGuessConfigurationMutationVariables = Exact<{
  emailAddress: string;
  password: string;
}>;


export type ChannelEmailGuessConfigurationMutation = { channelEmailGuessConfiguration: { __typename: 'ChannelEmailGuessConfigurationPayload', result: { __typename: 'ChannelEmailGuessConfigurationResult', inboundConfiguration: { __typename: 'ChannelEmailInboundConfiguration', adapter: Types.EnumChannelEmailInboundAdapter, host: string | null | undefined, port: number | null | undefined, ssl: Types.EnumChannelEmailSsl | null | undefined, user: string | null | undefined, sslVerify: boolean | null | undefined, folder: string | null | undefined } | null | undefined, outboundConfiguration: { __typename: 'ChannelEmailOutboundConfiguration', adapter: Types.EnumChannelEmailOutboundAdapter, host: string | null | undefined, port: number | null | undefined, user: string | null | undefined, sslVerify: boolean | null | undefined } | null | undefined, mailboxStats: { __typename: 'ChannelEmailInboundMailboxStats', contentMessages: number | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type ChannelEmailSetNotificationConfigurationMutationVariables = Exact<{
  outboundConfiguration: Types.ChannelEmailOutboundConfigurationInput;
}>;


export type ChannelEmailSetNotificationConfigurationMutation = { channelEmailSetNotificationConfiguration: { __typename: 'ChannelEmailSetNotificationConfigurationPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type ChannelEmailValidateConfigurationInboundMutationVariables = Exact<{
  inboundConfiguration: Types.ChannelEmailInboundConfigurationInput;
}>;


export type ChannelEmailValidateConfigurationInboundMutation = { channelEmailValidateConfigurationInbound: { __typename: 'ChannelEmailValidateConfigurationInboundPayload', success: boolean | null | undefined, mailboxStats: { __typename: 'ChannelEmailInboundMailboxStats', contentMessages: number | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type ChannelEmailValidateConfigurationOutboundMutationVariables = Exact<{
  outboundConfiguration: Types.ChannelEmailOutboundConfigurationInput;
  emailAddress: string;
}>;


export type ChannelEmailValidateConfigurationOutboundMutation = { channelEmailValidateConfigurationOutbound: { __typename: 'ChannelEmailValidateConfigurationOutboundPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type ChannelEmailValidateConfigurationRoundtripMutationVariables = Exact<{
  inboundConfiguration: Types.ChannelEmailInboundConfigurationInput;
  outboundConfiguration: Types.ChannelEmailOutboundConfigurationInput;
  emailAddress: string;
}>;


export type ChannelEmailValidateConfigurationRoundtripMutation = { channelEmailValidateConfigurationRoundtrip: { __typename: 'ChannelEmailValidateConfigurationRoundtripPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type EmailAddressesQueryVariables = Exact<{
  onlyActive?: boolean | null | undefined;
}>;


export type EmailAddressesQuery = { emailAddresses: Array<{ __typename: 'EmailAddress', name: string, email: string, active: boolean }> };

export type OrganizationHistoryQueryVariables = Exact<{
  organizationId: string | number;
}>;


export type OrganizationHistoryQuery = { organizationHistory: Array<{ __typename: 'HistoryGroup', createdAt: string, records: Array<{ __typename: 'HistoryRecord', issuer:
        | { __typename: 'AIAgent', id: string, name: string }
        | { __typename: 'Job', id: string, name: string }
        | { __typename: 'Macro', id: string, name: string }
        | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
        | { __typename: 'PostmasterFilter', id: string, name: string }
        | { __typename: 'Trigger', id: string, name: string }
        | { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, email: string | null | undefined, image: string | null | undefined }
      , events: Array<{ __typename: 'HistoryRecordEvent', createdAt: string, action: string, attribute: string | null | undefined, changes: any, object:
          | { __typename: 'Checklist', id: string, name: string | null | undefined }
          | { __typename: 'ChecklistItem', id: string, text: string, checked: boolean }
          | { __typename: 'Group', id: string, name: string | null | undefined }
          | { __typename: 'Mention', id: string, user: { __typename: 'User', id: string, fullname: string | null | undefined } }
          | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
          | { __typename: 'Organization', id: string, name: string | null | undefined }
          | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string }
          | { __typename: 'TicketArticle', id: string, body: string }
          | { __typename: 'TicketSharedDraftZoom', id: string }
          | { __typename: 'User', id: string, fullname: string | null | undefined }
         }> }> }> };

export type TicketArticleHighlightedTextUpsertMutationVariables = Exact<{
  articleId: string | number;
  highlight?: Array<Types.TicketArticleHighlightedTextInput> | Types.TicketArticleHighlightedTextInput | null | undefined;
}>;


export type TicketArticleHighlightedTextUpsertMutation = { ticketArticleHighlightedTextUpsert: { __typename: 'TicketArticleHighlightedTextUpsertPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketUpdateBulkMutationVariables = Exact<{
  selector: Types.TicketBulkSelectorInput;
  perform: Types.TicketBulkPerformInput;
}>;


export type TicketUpdateBulkMutation = { ticketUpdateBulk: { __typename: 'TicketUpdateBulkPayload', async: boolean | null | undefined, total: number | null | undefined, failedCount: number | null | undefined, inaccessibleTicketIds: Array<string> | null | undefined, invalidTicketIds: Array<string> | null | undefined } | null | undefined };

export type UserCurrentOverviewUpdateLastUsedMutationVariables = Exact<{
  overviewsLastUsed: Array<Types.UserCurrentOverviewLastUsed> | Types.UserCurrentOverviewLastUsed;
}>;


export type UserCurrentOverviewUpdateLastUsedMutation = { userCurrentOverviewUpdateLastUsed: { __typename: 'UserCurrentOverviewUpdateLastUsedPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type OverviewsWithCachedCountQueryVariables = Exact<{
  ignoreUserConditions: boolean;
  filterOverviewIds?: Array<string | number> | string | number | null | undefined;
  cacheTtl: number;
}>;


export type OverviewsWithCachedCountQuery = { ticketOverviews: Array<{ __typename: 'Overview', id: string, cachedTicketCount: number }> };

export type TicketsByCustomerQueryVariables = Exact<{
  customerId: string | number;
  customerOrganizations?: boolean | null | undefined;
  stateTypeCategory?: Types.EnumTicketStateTypeCategory | null | undefined;
  pageSize?: number | null | undefined;
  cursor?: string | null | undefined;
}>;


export type TicketsByCustomerQuery = { ticketsByCustomer: { __typename: 'TicketConnection', totalCount: number, edges: Array<{ __typename: 'TicketEdge', node: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, createdAt: string, state: { __typename: 'TicketState', id: string, name: string } } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } };

export type TicketsByOrganizationQueryVariables = Exact<{
  organizationId: string | number;
  stateTypeCategory?: Types.EnumTicketStateTypeCategory | null | undefined;
  pageSize?: number | null | undefined;
  cursor?: string | null | undefined;
}>;


export type TicketsByOrganizationQuery = { ticketsByOrganization: { __typename: 'TicketConnection', totalCount: number, edges: Array<{ __typename: 'TicketEdge', node: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, createdAt: string, state: { __typename: 'TicketState', id: string, name: string } } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } };

export type TicketsCachedByOverviewQueryVariables = Exact<{
  overviewId: string | number;
  orderBy?: string | null | undefined;
  orderDirection?: Types.EnumOrderDirection | null | undefined;
  cursor?: string | null | undefined;
  pageSize?: number | null | undefined;
  cacheTtl: number;
  renewCache?: boolean | null | undefined;
  knownCollectionSignature?: string | null | undefined;
}>;


export type TicketsCachedByOverviewQuery = { ticketsCachedByOverview: { __typename: 'CachedTicketConnection', totalCount: number, collectionSignature: string, edges: Array<{ __typename: 'TicketEdge', cursor: string, node: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, updatedAt: string, aiAgentRunning: boolean | null | undefined, pendingTime: string | null | undefined, articleCount: number | null | undefined, stateColorCode: Types.EnumTicketStateColorCode, escalationAt: string | null | undefined, firstResponseEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, firstResponseAt: string | null | undefined, closeAt: string | null | undefined, timeUnit: number | null | undefined, lastCloseAt: string | null | undefined, lastContactAt: string | null | undefined, lastContactAgentAt: string | null | undefined, lastContactCustomerAt: string | null | undefined, createdBy: { __typename: 'User', id: string, fullname: string | null | undefined } | null | undefined, updatedBy: { __typename: 'User', id: string, fullname: string | null | undefined } | null | undefined, owner: { __typename: 'User', id: string, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, fullname: string | null | undefined }, organization: { __typename: 'Organization', id: string, name: string | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean } } }> | null | undefined, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined, hasNextPage: boolean } } };

export type TicketsStatsMonthlyByCustomerQueryVariables = Exact<{
  customerId: string | number;
}>;


export type TicketsStatsMonthlyByCustomerQuery = { ticketsStatsMonthlyByCustomer: Array<{ __typename: 'TicketStatsMonthly', monthLabel: string, monthNumber: string, ticketsClosed: number, ticketsCreated: number, year: string }> };

export type TicketsStatsMonthlyByOrganizationQueryVariables = Exact<{
  organizationId: string | number;
}>;


export type TicketsStatsMonthlyByOrganizationQuery = { ticketsStatsMonthlyByOrganization: Array<{ __typename: 'TicketStatsMonthly', monthLabel: string, monthNumber: string, ticketsClosed: number, ticketsCreated: number, year: string }> };

export type UserCurrentTicketOverviewsQueryVariables = Exact<{
  ignoreUserConditions: boolean;
  withTicketCount: boolean;
}>;


export type UserCurrentTicketOverviewsQuery = { userCurrentTicketOverviews: Array<{ __typename: 'Overview', viewColumnsRaw: Array<string>, id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number }> };

export type UserCurrentTicketOverviewsCountQueryVariables = Exact<{
  ignoreUserConditions: boolean;
  cacheTtl: number;
}>;


export type UserCurrentTicketOverviewsCountQuery = { userCurrentTicketOverviews: Array<{ __typename: 'Overview', id: string, cachedTicketCount: number }> };

export type UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentTicketBulkUpdateStatusUpdatesSubscription = { userCurrentTicketBulkUpdateStatusUpdates: { __typename: 'UserCurrentTicketBulkUpdateStatusUpdatesPayload', bulkUpdateStatus: { __typename: 'TicketBulkUpdateStatus', status: Types.EnumBulkUpdateStatusStatus, total: number | null | undefined, processedCount: number | null | undefined, failedCount: number | null | undefined } } };

export type TicketByCustomerUpdatesSubscriptionVariables = Exact<{
  customerId: string | number;
}>;


export type TicketByCustomerUpdatesSubscription = { ticketByCustomerUpdates: { __typename: 'TicketByCustomerUpdatesPayload', listChanged: boolean | null | undefined } };

export type TicketByOrganizationUpdatesSubscriptionVariables = Exact<{
  organizationId: string | number;
}>;


export type TicketByOrganizationUpdatesSubscription = { ticketByOrganizationUpdates: { __typename: 'TicketByOrganizationUpdatesPayload', listChanged: boolean | null | undefined } };

export type UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables = Exact<{
  ignoreUserConditions: boolean;
  withTicketCount?: boolean | null | undefined;
}>;


export type UserCurrentOverviewOrderingFullAttributesUpdatesSubscription = { userCurrentOverviewOrderingUpdates: { __typename: 'UserCurrentOverviewOrderingUpdatesPayload', overviews: Array<{ __typename: 'Overview', viewColumnsRaw: Array<string>, id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number }> | null | undefined } };

export type UserCurrentOverviewOrderingUpdatesSubscriptionVariables = Exact<{
  ignoreUserConditions: boolean;
}>;


export type UserCurrentOverviewOrderingUpdatesSubscription = { userCurrentOverviewOrderingUpdates: { __typename: 'UserCurrentOverviewOrderingUpdatesPayload', overviews: Array<{ __typename: 'Overview', id: string, name: string, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined }> | null | undefined } };

export type UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables = Exact<{
  ignoreUserConditions: boolean;
  withTicketCount?: boolean | null | undefined;
}>;


export type UserCurrentTicketOverviewFullAttributesUpdatesSubscription = { userCurrentTicketOverviewUpdates: { __typename: 'UserCurrentTicketOverviewUpdatesPayload', ticketOverviews: Array<{ __typename: 'Overview', viewColumnsRaw: Array<string>, id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number }> | null | undefined } };

export type UserCurrentTicketOverviewUpdatesSubscriptionVariables = Exact<{
  ignoreUserConditions: boolean;
}>;


export type UserCurrentTicketOverviewUpdatesSubscription = { userCurrentTicketOverviewUpdates: { __typename: 'UserCurrentTicketOverviewUpdatesPayload', ticketOverviews: Array<{ __typename: 'Overview', id: string, name: string }> | null | undefined } };

export type UserCurrentTaskbarItemAttributesFragment = { __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
    | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
    | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
    | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
    | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
    | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
   | null | undefined };

export type UserCurrentPasswordCheckMutationVariables = Exact<{
  password: string;
}>;


export type UserCurrentPasswordCheckMutation = { userCurrentPasswordCheck: { __typename: 'UserCurrentPasswordCheckPayload', success: boolean | null | undefined, token: string | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentRecentCloseResetMutationVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentRecentCloseResetMutation = { userCurrentRecentCloseReset: { __typename: 'UserCurrentRecentCloseResetPayload', success: boolean } | null | undefined };

export type UserCurrentTaskbarItemAddMutationVariables = Exact<{
  input: Types.UserTaskbarItemInput;
}>;


export type UserCurrentTaskbarItemAddMutation = { userCurrentTaskbarItemAdd: { __typename: 'UserCurrentTaskbarItemAddPayload', taskbarItem: { __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
        | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
        | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
        | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
       | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTaskbarItemDeleteMutationVariables = Exact<{
  id: string | number;
}>;


export type UserCurrentTaskbarItemDeleteMutation = { userCurrentTaskbarItemDelete: { __typename: 'UserCurrentTaskbarItemDeletePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTaskbarItemListPrioMutationVariables = Exact<{
  list: Array<Types.UserTaskbarItemListPrioInput> | Types.UserTaskbarItemListPrioInput;
}>;


export type UserCurrentTaskbarItemListPrioMutation = { userCurrentTaskbarItemListPrio: { __typename: 'UserCurrentTaskbarItemListPrioPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTaskbarItemTouchLastContactMutationVariables = Exact<{
  id: string | number;
}>;


export type UserCurrentTaskbarItemTouchLastContactMutation = { userCurrentTaskbarItemTouchLastContact: { __typename: 'UserCurrentTaskbarItemTouchLastContactPayload', taskbarItem: { __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
        | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
        | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
        | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
       | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTaskbarItemUpdateMutationVariables = Exact<{
  id: string | number;
  input: Types.UserTaskbarItemInput;
}>;


export type UserCurrentTaskbarItemUpdateMutation = { userCurrentTaskbarItemUpdate: { __typename: 'UserCurrentTaskbarItemUpdatePayload', taskbarItem: { __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
        | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
        | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
        | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
       | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTicketScreenBehaviorMutationVariables = Exact<{
  behavior: Types.EnumTicketScreenBehavior;
}>;


export type UserCurrentTicketScreenBehaviorMutation = { userCurrentTicketScreenBehavior: { __typename: 'UserCurrentTicketScreenBehaviorPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentRecentCloseListQueryVariables = Exact<{
  limit?: number | null | undefined;
}>;


export type UserCurrentRecentCloseListQuery = { userCurrentRecentCloseList: Array<
    | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
    | { __typename: 'Ticket', id: string, internalId: number, title: string, number: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined } }
    | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
  > };

export type UserCurrentTaskbarItemListQueryVariables = Exact<{
  app: Types.EnumTaskbarApp;
}>;


export type UserCurrentTaskbarItemListQuery = { userCurrentTaskbarItemList: Array<{ __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
      | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
      | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
      | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
      | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
      | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
     | null | undefined }> | null | undefined };

export type UserCurrentRecentCloseUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentRecentCloseUpdatesSubscription = { userCurrentRecentCloseUpdates: { __typename: 'UserCurrentRecentCloseUpdatesPayload', recentCloseUpdated: boolean | null | undefined } };

export type UserCurrentTaskbarItemListUpdatesSubscriptionVariables = Exact<{
  app: Types.EnumTaskbarApp;
}>;


export type UserCurrentTaskbarItemListUpdatesSubscription = { userCurrentTaskbarItemListUpdates: { __typename: 'UserCurrentTaskbarItemListUpdatesPayload', taskbarItemList: Array<{ __typename: 'UserTaskbarItem', id: string, prio: number }> | null | undefined } };

export type UserCurrentTaskbarItemStateUpdatesSubscriptionVariables = Exact<{
  taskbarItemId: string | number;
}>;


export type UserCurrentTaskbarItemStateUpdatesSubscription = { userCurrentTaskbarItemStateUpdates: { __typename: 'UserCurrentTaskbarItemStateUpdatesPayload', stateUpdateType: Types.EnumTaskbarStateUpdate | null | undefined } };

export type UserCurrentTaskbarItemUpdatesSubscriptionVariables = Exact<{
  app: Types.EnumTaskbarApp;
}>;


export type UserCurrentTaskbarItemUpdatesSubscription = { userCurrentTaskbarItemUpdates: { __typename: 'UserCurrentTaskbarItemUpdatesPayload', removeItem: string | null | undefined, addItem: { __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
        | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
        | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
        | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
       | null | undefined } | null | undefined, updateItem: { __typename: 'UserTaskbarItem', id: string, key: string, callback: Types.EnumTaskbarEntity, formId: string | null | undefined, formNewArticlePresent: boolean, entityAccess: Types.EnumTaskbarEntityAccess | null | undefined, prio: number, changed: boolean, dirty: boolean, notify: boolean, updatedAt: string, entity:
        | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } }
        | { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, active: boolean | null | undefined }
        | { __typename: 'UserTaskbarItemEntitySearch', query: string | null | undefined, model: string | null | undefined, filters: string | null | undefined, filterCount: number | null | undefined }
        | { __typename: 'UserTaskbarItemEntityTicketCreate', uid: string, title: string, createArticleTypeKey: string | null | undefined }
       | null | undefined } | null | undefined } };

export type UserCurrentTwoFactorUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentTwoFactorUpdatesSubscription = { userCurrentTwoFactorUpdates: { __typename: 'UserCurrentTwoFactorUpdatesPayload', configuration: { __typename: 'UserConfigurationTwoFactor', recoveryCodesExist: boolean, enabledAuthenticationMethods: Array<{ __typename: 'TwoFactorEnabledAuthenticationMethod', configured: boolean, authenticationMethod: Types.EnumTwoFactorAuthenticationMethod }> } | null | undefined } };

export type UserSignupResendMutationVariables = Exact<{
  email: string;
}>;


export type UserSignupResendMutation = { userSignupResend: { __typename: 'UserSignupResendPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserHistoryQueryVariables = Exact<{
  userId: string | number;
}>;


export type UserHistoryQuery = { userHistory: Array<{ __typename: 'HistoryGroup', createdAt: string, records: Array<{ __typename: 'HistoryRecord', issuer:
        | { __typename: 'AIAgent', id: string, name: string }
        | { __typename: 'Job', id: string, name: string }
        | { __typename: 'Macro', id: string, name: string }
        | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
        | { __typename: 'PostmasterFilter', id: string, name: string }
        | { __typename: 'Trigger', id: string, name: string }
        | { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, email: string | null | undefined, image: string | null | undefined }
      , events: Array<{ __typename: 'HistoryRecordEvent', createdAt: string, action: string, attribute: string | null | undefined, changes: any, object:
          | { __typename: 'Checklist', id: string, name: string | null | undefined }
          | { __typename: 'ChecklistItem', id: string, text: string, checked: boolean }
          | { __typename: 'Group', id: string, name: string | null | undefined }
          | { __typename: 'Mention', id: string, user: { __typename: 'User', id: string, fullname: string | null | undefined } }
          | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
          | { __typename: 'Organization', id: string, name: string | null | undefined }
          | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string }
          | { __typename: 'TicketArticle', id: string, body: string }
          | { __typename: 'TicketSharedDraftZoom', id: string }
          | { __typename: 'User', id: string, fullname: string | null | undefined }
         }> }> }> };

export type AdminPasswordAuthSendMutationVariables = Exact<{
  login: string;
}>;


export type AdminPasswordAuthSendMutation = { adminPasswordAuthSend: { __typename: 'AdminPasswordAuthSendPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type AdminPasswordAuthVerifyMutationVariables = Exact<{
  token: string;
}>;


export type AdminPasswordAuthVerifyMutation = { adminPasswordAuthVerify: { __typename: 'AdminPasswordAuthVerifyPayload', login: string | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserPasswordResetSendMutationVariables = Exact<{
  username: string;
}>;


export type UserPasswordResetSendMutation = { userPasswordResetSend: { __typename: 'UserPasswordResetSendPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserPasswordResetUpdateMutationVariables = Exact<{
  token: string;
  password: string;
}>;


export type UserPasswordResetUpdateMutation = { userPasswordResetUpdate: { __typename: 'UserPasswordResetUpdatePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserPasswordResetVerifyMutationVariables = Exact<{
  token: string;
}>;


export type UserPasswordResetVerifyMutation = { userPasswordResetVerify: { __typename: 'UserPasswordResetVerifyPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserSignupMutationVariables = Exact<{
  input: Types.UserSignupInput;
}>;


export type UserSignupMutation = { userSignup: { __typename: 'UserSignupPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserSignupVerifyMutationVariables = Exact<{
  token: string;
}>;


export type UserSignupVerifyMutation = { userSignupVerify: { __typename: 'UserSignupVerifyPayload', session: { __typename: 'Session', id: string, afterAuth: { __typename: 'SessionAfterAuth', type: Types.EnumAfterAuthType, data: any } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type GuidedSetupSetSystemInformationMutationVariables = Exact<{
  input: Types.SystemInformation;
}>;


export type GuidedSetupSetSystemInformationMutation = { guidedSetupSetSystemInformation: { __typename: 'GuidedSetupSetSystemInformationPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type SystemImportConfigurationMutationVariables = Exact<{
  configuration: Types.SystemImportConfigurationInput;
}>;


export type SystemImportConfigurationMutation = { systemImportConfiguration: { __typename: 'SystemImportConfigurationPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type SystemImportStartMutationVariables = Exact<{ [key: string]: never; }>;


export type SystemImportStartMutation = { systemImportStart: { __typename: 'SystemImportStartPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type SystemSetupLockMutationVariables = Exact<{
  ttl?: number | null | undefined;
}>;


export type SystemSetupLockMutation = { systemSetupLock: { __typename: 'SystemSetupLockPayload', resource: string | null | undefined, value: string | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type SystemSetupRunAutoWizardMutationVariables = Exact<{
  token?: string | null | undefined;
}>;


export type SystemSetupRunAutoWizardMutation = { systemSetupRunAutoWizard: { __typename: 'SystemSetupRunAutoWizardPayload', session: { __typename: 'Session', id: string, afterAuth: { __typename: 'SessionAfterAuth', type: Types.EnumAfterAuthType, data: any } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type SystemSetupUnlockMutationVariables = Exact<{
  value: string;
}>;


export type SystemSetupUnlockMutation = { systemSetupUnlock: { __typename: 'SystemSetupUnlockPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserAddFirstAdminMutationVariables = Exact<{
  input: Types.UserSignupInput;
}>;


export type UserAddFirstAdminMutation = { userAddFirstAdmin: { __typename: 'UserAddFirstAdminPayload', session: { __typename: 'Session', id: string, afterAuth: { __typename: 'SessionAfterAuth', type: Types.EnumAfterAuthType, data: any } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type SystemImportStateQueryVariables = Exact<{ [key: string]: never; }>;


export type SystemImportStateQuery = { systemImportState: { __typename: 'ImportJob', name: string, result: any, startedAt: string | null | undefined, finishedAt: string | null | undefined } | null | undefined };

export type SystemSetupInfoQueryVariables = Exact<{ [key: string]: never; }>;


export type SystemSetupInfoQuery = { systemSetupInfo: { __typename: 'SystemSetupInfo', status: Types.EnumSystemSetupInfoStatus, type: Types.EnumSystemSetupInfoType | null | undefined } };

export type UserCalendarSubscriptionAttributesFragment = { __typename: 'UserPersonalSettingsCalendarSubscriptionsConfig', combinedUrl: string | null | undefined, globalOptions: { __typename: 'UserPersonalSettingsCalendarSubscriptionGlobalOptions', alarm: boolean | null | undefined } | null | undefined, newOpen: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingle', url: string | null | undefined, options: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingleOptions', own: boolean | null | undefined, notAssigned: boolean | null | undefined } | null | undefined } | null | undefined, pending: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingle', url: string | null | undefined, options: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingleOptions', own: boolean | null | undefined, notAssigned: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingle', url: string | null | undefined, options: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingleOptions', own: boolean | null | undefined, notAssigned: boolean | null | undefined } | null | undefined } | null | undefined };

export type UserDeviceAttributesFragment = { __typename: 'UserDevice', id: string, userId: string, name: string, os: string | null | undefined, browser: string | null | undefined, location: string | null | undefined, deviceDetails: any, locationDetails: any, fingerprint: string | null | undefined, userAgent: string | null | undefined, ip: string | null | undefined, createdAt: string, updatedAt: string };

export type UserCurrentAppearanceMutationVariables = Exact<{
  theme: Types.EnumAppearanceTheme;
}>;


export type UserCurrentAppearanceMutation = { userCurrentAppearance: { __typename: 'UserCurrentAppearancePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentAvatarSelectMutationVariables = Exact<{
  id: string | number;
}>;


export type UserCurrentAvatarSelectMutation = { userCurrentAvatarSelect: { __typename: 'UserCurrentAvatarSelectPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentCalendarSubscriptionUpdateMutationVariables = Exact<{
  input: Types.UserCalendarSubscriptionsConfigInput;
}>;


export type UserCurrentCalendarSubscriptionUpdateMutation = { userCurrentCalendarSubscriptionUpdate: { __typename: 'UserCurrentCalendarSubscriptionUpdatePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentChangePasswordMutationVariables = Exact<{
  currentPassword: string;
  newPassword: string;
}>;


export type UserCurrentChangePasswordMutation = { userCurrentChangePassword: { __typename: 'UserCurrentChangePasswordPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentDeviceDeleteMutationVariables = Exact<{
  deviceId: string | number;
}>;


export type UserCurrentDeviceDeleteMutation = { userCurrentDeviceDelete: { __typename: 'UserCurrentDeviceDeletePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentRemoveLinkedAccountMutationVariables = Exact<{
  provider: Types.EnumAuthenticationProvider;
  uid: string;
}>;


export type UserCurrentRemoveLinkedAccountMutation = { userCurrentRemoveLinkedAccount: { __typename: 'UserCurrentRemoveLinkedAccountPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentNotificationPreferencesResetMutationVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentNotificationPreferencesResetMutation = { userCurrentNotificationPreferencesReset: { __typename: 'UserCurrentNotificationPreferencesResetPayload', user: { __typename: 'User', personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentNotificationPreferencesUpdateMutationVariables = Exact<{
  groupIds?: Array<string | number> | string | number | null | undefined;
  matrix: Types.UserNotificationMatrixInput;
  sound: Types.UserNotificationSoundInput;
}>;


export type UserCurrentNotificationPreferencesUpdateMutation = { userCurrentNotificationPreferencesUpdate: { __typename: 'UserCurrentNotificationPreferencesUpdatePayload', user: { __typename: 'User', personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentOutOfOfficeMutationVariables = Exact<{
  input: Types.OutOfOfficeInput;
}>;


export type UserCurrentOutOfOfficeMutation = { userCurrentOutOfOffice: { __typename: 'UserCurrentOutOfOfficePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentOverviewResetOrderMutationVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentOverviewResetOrderMutation = { userCurrentOverviewResetOrder: { __typename: 'UserCurrentOverviewResetOrderPayload', success: boolean, overviews: Array<{ __typename: 'Overview', id: string, name: string }> | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentOverviewUpdateOrderMutationVariables = Exact<{
  overviewIds: Array<string | number> | string | number;
}>;


export type UserCurrentOverviewUpdateOrderMutation = { userCurrentOverviewUpdateOrder: { __typename: 'UserCurrentOverviewUpdateOrderPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentAvatarListQueryVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentAvatarListQuery = { userCurrentAvatarList: Array<{ __typename: 'Avatar', id: string, default: boolean, deletable: boolean, initial: boolean, imageHash: string | null | undefined, createdAt: string, updatedAt: string }> | null | undefined };

export type UserCurrentCalendarSubscriptionListQueryVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentCalendarSubscriptionListQuery = { userCurrentCalendarSubscriptionList: { __typename: 'UserPersonalSettingsCalendarSubscriptionsConfig', combinedUrl: string | null | undefined, globalOptions: { __typename: 'UserPersonalSettingsCalendarSubscriptionGlobalOptions', alarm: boolean | null | undefined } | null | undefined, newOpen: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingle', url: string | null | undefined, options: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingleOptions', own: boolean | null | undefined, notAssigned: boolean | null | undefined } | null | undefined } | null | undefined, pending: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingle', url: string | null | undefined, options: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingleOptions', own: boolean | null | undefined, notAssigned: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingle', url: string | null | undefined, options: { __typename: 'UserPersonalSettingsCalendarSubscriptionSingleOptions', own: boolean | null | undefined, notAssigned: boolean | null | undefined } | null | undefined } | null | undefined } };

export type UserCurrentDeviceListQueryVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentDeviceListQuery = { userCurrentDeviceList: Array<{ __typename: 'UserDevice', id: string, userId: string, name: string, os: string | null | undefined, browser: string | null | undefined, location: string | null | undefined, deviceDetails: any, locationDetails: any, fingerprint: string | null | undefined, userAgent: string | null | undefined, ip: string | null | undefined, createdAt: string, updatedAt: string }> | null | undefined };

export type UserCurrentOverviewListQueryVariables = Exact<{
  ignoreUserConditions: boolean;
}>;


export type UserCurrentOverviewListQuery = { userCurrentTicketOverviews: Array<{ __typename: 'Overview', id: string, name: string, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined }> };

export type UserCurrentAccessTokenUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentAccessTokenUpdatesSubscription = { userCurrentAccessTokenUpdates: { __typename: 'UserCurrentAccessTokenUpdatesPayload', tokens: Array<{ __typename: 'Token', id: string, name: string | null | undefined, preferences: any, expiresAt: string | null | undefined, lastUsedAt: string | null | undefined, createdAt: string, user: { __typename: 'User', id: string } | null | undefined }> | null | undefined } };

export type UserCurrentAvatarUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentAvatarUpdatesSubscription = { userCurrentAvatarUpdates: { __typename: 'UserCurrentAvatarUpdatesPayload', avatars: Array<{ __typename: 'Avatar', id: string, default: boolean, deletable: boolean, initial: boolean, imageHash: string | null | undefined, createdAt: string, updatedAt: string }> | null | undefined } };

export type UserCurrentDevicesUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentDevicesUpdatesSubscription = { userCurrentDevicesUpdates: { __typename: 'UserCurrentDevicesUpdatesPayload', devices: Array<{ __typename: 'UserDevice', id: string, userId: string, name: string, os: string | null | undefined, browser: string | null | undefined, location: string | null | undefined, deviceDetails: any, locationDetails: any, fingerprint: string | null | undefined, userAgent: string | null | undefined, ip: string | null | undefined, createdAt: string, updatedAt: string }> | null | undefined } };

export type AiAssistantAnalyticsMetaFragment = { __typename: 'AIAnalyticsMetadata', run: { __typename: 'AIAnalyticsRun', id: string } | null | undefined, usage: { __typename: 'AIAnalyticsUsage', userHasProvidedFeedback: boolean | null | undefined } | null | undefined };

export type IdoitObjectAttributesFragment = { __typename: 'TicketExternalReferencesIdoitObject', idoitObjectId: number, link: string | null | undefined, title: string, type: string, status: string };

export type LinkAddMutationVariables = Exact<{
  input: Types.LinkInput;
}>;


export type LinkAddMutation = { linkAdd: { __typename: 'LinkAddPayload', link: { __typename: 'Link', type: Types.EnumLinkType, item:
        | { __typename: 'KnowledgeBaseAnswerTranslation', id: string }
        | { __typename: 'Ticket', id: string, internalId: number, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }
       } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, field: string | null | undefined }> | null | undefined } | null | undefined };

export type LinkRemoveMutationVariables = Exact<{
  input: Types.LinkInput;
}>;


export type LinkRemoveMutation = { linkRemove: { __typename: 'LinkRemovePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, field: string | null | undefined }> | null | undefined } | null | undefined };

export type TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation = { ticketAIAssistanceEnqueueKnowledgeBaseAnswer: { __typename: 'TicketAIAssistanceEnqueueKnowledgeBaseAnswerPayload', success: boolean | null | undefined } | null | undefined };

export type TicketAiAssistanceSummarizeMutationVariables = Exact<{
  ticketId: string | number;
  regenerationOfId?: string | number | null | undefined;
}>;


export type TicketAiAssistanceSummarizeMutation = { ticketAIAssistanceSummarize: { __typename: 'TicketAIAssistanceSummarizePayload', summary: { __typename: 'TicketAIAssistanceSummary', customerRequest: string | null | undefined, conversationSummary: Array<string> | null | undefined, openQuestions: Array<string> | null | undefined, upcomingEvents: Array<string> | null | undefined, customerMood: string | null | undefined, customerEmotion: string | null | undefined } | null | undefined, analytics: { __typename: 'AIAnalyticsMetadata', isUnread: boolean | null | undefined, run: { __typename: 'AIAnalyticsRun', id: string } | null | undefined, usage: { __typename: 'AIAnalyticsUsage', userHasProvidedFeedback: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined };

export type TicketChecklistAddMutationVariables = Exact<{
  ticketId: string | number;
  templateId?: string | number | null | undefined;
  createFirstItem?: boolean | null | undefined;
}>;


export type TicketChecklistAddMutation = { ticketChecklistAdd: { __typename: 'TicketChecklistAddPayload', checklist: { __typename: 'Checklist', id: string, name: string | null | undefined, items: Array<{ __typename: 'ChecklistItem', id: string, text: string, checked: boolean }> } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketChecklistDeleteMutationVariables = Exact<{
  checklistId: string | number;
}>;


export type TicketChecklistDeleteMutation = { ticketChecklistDelete: { __typename: 'TicketChecklistDeletePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketChecklistItemDeleteMutationVariables = Exact<{
  checklistId: string | number;
  checklistItemId: string | number;
}>;


export type TicketChecklistItemDeleteMutation = { ticketChecklistItemDelete: { __typename: 'TicketChecklistItemDeletePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketChecklistItemOrderUpdateMutationVariables = Exact<{
  checklistId: string | number;
  order: Array<string | number> | string | number;
}>;


export type TicketChecklistItemOrderUpdateMutation = { ticketChecklistItemOrderUpdate: { __typename: 'TicketChecklistItemOrderUpdatePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketChecklistItemUpsertMutationVariables = Exact<{
  checklistId: string | number;
  checklistItemId?: string | number | null | undefined;
  input: Types.TicketChecklistItemInput;
}>;


export type TicketChecklistItemUpsertMutation = { ticketChecklistItemUpsert: { __typename: 'TicketChecklistItemUpsertPayload', checklistItem: { __typename: 'ChecklistItem', id: string, text: string, checked: boolean, ticketReference: { __typename: 'TicketReference', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } } | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketChecklistItemsAddMutationVariables = Exact<{
  checklistId: string | number;
  input: Array<Types.TicketChecklistItemInput> | Types.TicketChecklistItemInput;
}>;


export type TicketChecklistItemsAddMutation = { ticketChecklistItemsAdd: { __typename: 'TicketChecklistItemsAddPayload', success: boolean } | null | undefined };

export type TicketChecklistTitleUpdateMutationVariables = Exact<{
  checklistId: string | number;
  title?: string | null | undefined;
}>;


export type TicketChecklistTitleUpdateMutation = { ticketChecklistTitleUpdate: { __typename: 'TicketChecklistTitleUpdatePayload', checklist: { __typename: 'Checklist', id: string, name: string | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketExternalReferencesIdoitObjectAddMutationVariables = Exact<{
  idoitObjectIds: Array<number> | number;
  ticketId?: string | number | null | undefined;
}>;


export type TicketExternalReferencesIdoitObjectAddMutation = { ticketExternalReferencesIdoitObjectAdd: { __typename: 'TicketExternalReferencesIdoitObjectAddPayload', idoitObjects: Array<{ __typename: 'TicketExternalReferencesIdoitObject', idoitObjectId: number, link: string | null | undefined, title: string, type: string, status: string }> | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketExternalReferencesIdoitObjectRemoveMutationVariables = Exact<{
  ticketId: string | number;
  idoitObjectId: number;
}>;


export type TicketExternalReferencesIdoitObjectRemoveMutation = { ticketExternalReferencesIdoitObjectRemove: { __typename: 'TicketExternalReferencesIdoitObjectRemovePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketExternalReferencesIssueTrackerItemAddMutationVariables = Exact<{
  issueTrackerLink: string;
  issueTrackerType: Types.EnumTicketExternalReferencesIssueTrackerType;
  ticketId?: string | number | null | undefined;
}>;


export type TicketExternalReferencesIssueTrackerItemAddMutation = { ticketExternalReferencesIssueTrackerItemAdd: { __typename: 'TicketExternalReferencesIssueTrackerItemAddPayload', issueTrackerItem: { __typename: 'TicketExternalReferencesIssueTrackerItem', assignees: Array<string> | null | undefined, issueId: number, milestone: string | null | undefined, state: Types.EnumTicketExternalReferencesIssueTrackerItemState, title: string, url: string, issueType: { __typename: 'TicketExternalReferencesIssueTrackerItemIssueType', color: string | null | undefined, name: string } | null | undefined, labels: Array<{ __typename: 'TicketExternalReferencesIssueTrackerItemLabel', color: string, textColor: string, title: string }> | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketExternalReferencesIssueTrackerItemRemoveMutationVariables = Exact<{
  issueTrackerLink: string;
  issueTrackerType: Types.EnumTicketExternalReferencesIssueTrackerType;
  ticketId: string | number;
}>;


export type TicketExternalReferencesIssueTrackerItemRemoveMutation = { ticketExternalReferencesIssueTrackerItemRemove: { __typename: 'TicketExternalReferencesIssueTrackerItemRemovePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type AutocompleteSearchIdoitObjectTypesQueryVariables = Exact<{
  input: Types.AutocompleteSearchInput;
}>;


export type AutocompleteSearchIdoitObjectTypesQuery = { autocompleteSearchIdoitObjectTypes: Array<{ __typename: 'AutocompleteSearchEntry', value: string, label: string }> };

export type ChecklistTemplatesQueryVariables = Exact<{
  onlyActive?: boolean | null | undefined;
}>;


export type ChecklistTemplatesQuery = { checklistTemplates: Array<{ __typename: 'ChecklistTemplate', id: string, name: string | null | undefined, active: boolean | null | undefined }> };

export type LinkListQueryVariables = Exact<{
  objectId: string | number;
  targetType: string;
}>;


export type LinkListQuery = { linkList: Array<{ __typename: 'Link', type: Types.EnumLinkType, item:
      | { __typename: 'KnowledgeBaseAnswerTranslation', id: string }
      | { __typename: 'Ticket', id: string, internalId: number, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }
     }> | null | undefined };

export type TemplatesQueryVariables = Exact<{
  onlyActive?: boolean | null | undefined;
}>;


export type TemplatesQuery = { templates: Array<{ __typename: 'Template', id: string, name: string }> };

export type TicketAiRelatedKnowledgeBaseAnswersQueryVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketAiRelatedKnowledgeBaseAnswersQuery = { ticketAIRelatedKnowledgeBaseAnswers: { __typename: 'TicketAIRelatedKnowledgeBaseAnswersResult', pending: boolean, answers: Array<{ __typename: 'TicketAIRelatedKnowledgeBaseAnswer', score: number, translation: { __typename: 'KnowledgeBaseAnswerTranslation', id: string, title: string, answer: { __typename: 'KnowledgeBaseAnswer', id: string, category: { __typename: 'KnowledgeBaseCategory', knowledgeBase: { __typename: 'KnowledgeBase', id: string } } }, kbLocale: { __typename: 'KnowledgeBaseLocale', systemLocale: { __typename: 'Locale', locale: string } } } }> | null | undefined } };

export type TicketAttachmentsQueryVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketAttachmentsQuery = { ticketAttachments: Array<{ __typename: 'StoredFile', id: string, internalId: number, name: string, size: number | null | undefined, type: string | null | undefined, preferences: any }> };

export type TicketChecklistQueryVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketChecklistQuery = { ticketChecklist: { __typename: 'Checklist', id: string, name: string | null | undefined, completed: boolean, incomplete: number, items: Array<{ __typename: 'ChecklistItem', id: string, text: string, checked: boolean, ticketReference: { __typename: 'TicketReference', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } } | null | undefined } | null | undefined }> } | null | undefined };

export type TicketExternalReferencesIdoitObjectListQueryVariables = Exact<{
  ticketId?: string | number | null | undefined;
  idoitObjectIds?: Array<number> | number | null | undefined;
}>;


export type TicketExternalReferencesIdoitObjectListQuery = { ticketExternalReferencesIdoitObjectList: Array<{ __typename: 'TicketExternalReferencesIdoitObject', idoitObjectId: number, link: string | null | undefined, title: string, type: string, status: string }> };

export type TicketExternalReferencesIdoitObjectSearchQueryVariables = Exact<{
  idoitTypeId?: string | null | undefined;
  limit: number;
  query?: string | null | undefined;
}>;


export type TicketExternalReferencesIdoitObjectSearchQuery = { ticketExternalReferencesIdoitObjectSearch: Array<{ __typename: 'TicketExternalReferencesIdoitObject', idoitObjectId: number, link: string | null | undefined, title: string, type: string, status: string }> };

export type TicketExternalReferencesIssueTrackerItemListQueryVariables = Exact<{
  issueTrackerType: Types.EnumTicketExternalReferencesIssueTrackerType;
  ticketId?: string | number | null | undefined;
  issueTrackerLinks?: Array<string> | string | null | undefined;
}>;


export type TicketExternalReferencesIssueTrackerItemListQuery = { ticketExternalReferencesIssueTrackerItemList: Array<{ __typename: 'TicketExternalReferencesIssueTrackerItem', assignees: Array<string> | null | undefined, issueId: number, milestone: string | null | undefined, state: Types.EnumTicketExternalReferencesIssueTrackerItemState, title: string, url: string, issueType: { __typename: 'TicketExternalReferencesIssueTrackerItemIssueType', color: string | null | undefined, name: string } | null | undefined, labels: Array<{ __typename: 'TicketExternalReferencesIssueTrackerItemLabel', color: string, textColor: string, title: string }> | null | undefined }> };

export type TicketHistoryQueryVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketHistoryQuery = { ticketHistory: Array<{ __typename: 'HistoryGroup', createdAt: string, records: Array<{ __typename: 'HistoryRecord', issuer:
        | { __typename: 'AIAgent', id: string, name: string }
        | { __typename: 'Job', id: string, name: string }
        | { __typename: 'Macro', id: string, name: string }
        | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
        | { __typename: 'PostmasterFilter', id: string, name: string }
        | { __typename: 'Trigger', id: string, name: string }
        | { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, email: string | null | undefined, image: string | null | undefined }
      , events: Array<{ __typename: 'HistoryRecordEvent', createdAt: string, action: string, attribute: string | null | undefined, changes: any, object:
          | { __typename: 'Checklist', id: string, name: string | null | undefined }
          | { __typename: 'ChecklistItem', id: string, text: string, checked: boolean }
          | { __typename: 'Group', id: string, name: string | null | undefined }
          | { __typename: 'Mention', id: string, user: { __typename: 'User', id: string, fullname: string | null | undefined } }
          | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
          | { __typename: 'Organization', id: string, name: string | null | undefined }
          | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string }
          | { __typename: 'TicketArticle', id: string, body: string }
          | { __typename: 'TicketSharedDraftZoom', id: string }
          | { __typename: 'User', id: string, fullname: string | null | undefined }
         }> }> }> };

export type TicketRelationAndRecentTicketListsQueryVariables = Exact<{
  ticketId: number;
  customerId: string | number;
  limit?: number | null | undefined;
}>;


export type TicketRelationAndRecentTicketListsQuery = { ticketsRecentByCustomer: Array<{ __typename: 'Ticket', number: string, internalId: number, id: string, title: string, createdAt: string, stateColorCode: Types.EnumTicketStateColorCode, customer: { __typename: 'User', id: string, fullname: string | null | undefined }, organization: { __typename: 'Organization', id: string, name: string | null | undefined } | null | undefined, group: { __typename: 'Group', id: string, name: string | null | undefined }, state: { __typename: 'TicketState', id: string, name: string } }>, ticketsRecentlyViewed: Array<{ __typename: 'Ticket', number: string, internalId: number, id: string, title: string, createdAt: string, stateColorCode: Types.EnumTicketStateColorCode, customer: { __typename: 'User', id: string, fullname: string | null | undefined }, organization: { __typename: 'Organization', id: string, name: string | null | undefined } | null | undefined, group: { __typename: 'Group', id: string, name: string | null | undefined }, state: { __typename: 'TicketState', id: string, name: string } }> };

export type ChecklistTemplateUpdatesSubscriptionVariables = Exact<{
  onlyActive?: boolean | null | undefined;
}>;


export type ChecklistTemplateUpdatesSubscription = { checklistTemplateUpdates: { __typename: 'ChecklistTemplateUpdatesPayload', checklistTemplates: Array<{ __typename: 'ChecklistTemplate', id: string, name: string | null | undefined, active: boolean | null | undefined }> | null | undefined } };

export type LinkUpdatesSubscriptionVariables = Exact<{
  objectId: string | number;
  targetType: string;
}>;


export type LinkUpdatesSubscription = { linkUpdates: { __typename: 'LinkUpdatesPayload', links: Array<{ __typename: 'Link', type: Types.EnumLinkType, item:
        | { __typename: 'KnowledgeBaseAnswerTranslation', id: string }
        | { __typename: 'Ticket', id: string, internalId: number, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }
       }> | null | undefined } };

export type TemplateUpdatesSubscriptionVariables = Exact<{
  onlyActive: boolean;
}>;


export type TemplateUpdatesSubscription = { templateUpdates: { __typename: 'TemplateUpdatesPayload', templates: Array<{ __typename: 'Template', id: string, name: string }> | null | undefined } };

export type TicketAiAssistanceSummaryUpdatesSubscriptionVariables = Exact<{
  ticketId: string | number;
  locale: string;
}>;


export type TicketAiAssistanceSummaryUpdatesSubscription = { ticketAIAssistanceSummaryUpdates: { __typename: 'TicketAIAssistanceSummaryUpdatesPayload', summary: { __typename: 'TicketAIAssistanceSummary', customerRequest: string | null | undefined, conversationSummary: Array<string> | null | undefined, openQuestions: Array<string> | null | undefined, upcomingEvents: Array<string> | null | undefined, customerMood: string | null | undefined, customerEmotion: string | null | undefined } | null | undefined, error: { __typename: 'AsyncExecutionError', message: string, exception: string } | null | undefined, analytics: { __typename: 'AIAnalyticsMetadata', isUnread: boolean | null | undefined, run: { __typename: 'AIAnalyticsRun', id: string } | null | undefined, usage: { __typename: 'AIAnalyticsUsage', userHasProvidedFeedback: boolean | null | undefined } | null | undefined } | null | undefined } };

export type TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription = { ticketAIRelatedKnowledgeBaseAnswersUpdates: { __typename: 'TicketAIRelatedKnowledgeBaseAnswersUpdatesPayload', ticketId: string | null | undefined, error: string | null | undefined } };

export type TicketChecklistUpdatesSubscriptionVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketChecklistUpdatesSubscription = { ticketChecklistUpdates: { __typename: 'TicketChecklistUpdatesPayload', removedTicketChecklist: boolean | null | undefined, ticketChecklist: { __typename: 'Checklist', id: string, name: string | null | undefined, completed: boolean, incomplete: number, items: Array<{ __typename: 'ChecklistItem', id: string, text: string, checked: boolean, ticketReference: { __typename: 'TicketReference', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } } | null | undefined } | null | undefined }> } | null | undefined } };

export type TicketOverviewOrderQueryVariables = Exact<{
  withTicketCount?: boolean | null | undefined;
}>;


export type TicketOverviewOrderQuery = { ticketOverviews: Array<{ __typename: 'Overview', id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number, viewColumns: Array<{ __typename: 'KeyValue', key: string, value: string | null | undefined }>, orderColumns: Array<{ __typename: 'KeyValue', key: string, value: string | null | undefined }> }> };

export type TicketOverviewTicketCountQueryVariables = Exact<{
  ignoreUserConditions: boolean;
}>;


export type TicketOverviewTicketCountQuery = { ticketOverviews: Array<{ __typename: 'Overview', id: string, ticketCount: number }> };

export type TicketOverviewsQueryVariables = Exact<{
  withTicketCount: boolean;
}>;


export type TicketOverviewsQuery = { ticketOverviews: Array<{ __typename: 'Overview', id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number, viewColumns: Array<{ __typename: 'KeyValue', key: string, value: string | null | undefined }>, orderColumns: Array<{ __typename: 'KeyValue', key: string, value: string | null | undefined }> }> };

export type TicketWithMentionLimitQueryVariables = Exact<{
  ticketId: string | number;
  mentionsCount?: number | null | undefined;
}>;


export type TicketWithMentionLimitQuery = { ticket: { __typename: 'Ticket', aiSummaryEnabled: boolean | null | undefined, id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, createArticleType: { __typename: 'TicketArticleType', id: string, name: string | null | undefined } | null | undefined, mentions: { __typename: 'MentionConnection', totalCount: number, edges: Array<{ __typename: 'MentionEdge', cursor: string, node: { __typename: 'Mention', user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined }, userTicketAccess: { __typename: 'PolicyMentionUserTicketAccess', agentReadAccess: boolean } } }> } | null | undefined, checklist: { __typename: 'Checklist', id: string, completed: boolean, incomplete: number, total: number, complete: number } | null | undefined, referencingChecklistTickets: Array<{ __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }> | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } };

export type TicketOverviewUpdatesSubscriptionVariables = Exact<{
  ignoreUserConditions?: boolean | null | undefined;
  withTicketCount: boolean;
}>;


export type TicketOverviewUpdatesSubscription = { ticketOverviewUpdates: { __typename: 'TicketOverviewUpdatesPayload', ticketOverviews: Array<{ __typename: 'Overview', id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number, viewColumns: Array<{ __typename: 'KeyValue', key: string, value: string | null | undefined }>, orderColumns: Array<{ __typename: 'KeyValue', key: string, value: string | null | undefined }> }> | null | undefined } };

export type UserCurrentAvatarActiveQueryVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentAvatarActiveQuery = { userCurrentAvatarActive: { __typename: 'Avatar', id: string, default: boolean, deletable: boolean, initial: boolean, imageFull: string | null | undefined, imageResize: string | null | undefined, createdAt: string, updatedAt: string } | null | undefined };

export type SearchQueryVariables = Exact<{
  search: string;
  onlyIn: Types.EnumSearchableModels;
  limit?: number | null | undefined;
}>;


export type SearchQuery = { search: { __typename: 'SearchResult', totalCount: number, items: Array<
      | { __typename: 'Organization', id: string, internalId: number, active: boolean | null | undefined, name: string | null | undefined, vip: boolean | null | undefined, updatedAt: string, members: { __typename: 'UserConnection', totalCount: number, edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, fullname: string | null | undefined } }> } | null | undefined, updatedBy: { __typename: 'User', id: string, fullname: string | null | undefined } | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined }
      | { __typename: 'Ticket', id: string, internalId: number, title: string, number: string, updatedAt: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string }, priority: { __typename: 'TicketPriority', name: string, defaultCreate: boolean, uiColor: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, fullname: string | null | undefined }, updatedBy: { __typename: 'User', id: string, fullname: string | null | undefined } | null | undefined }
      | { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, image: string | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, vip: boolean | null | undefined, updatedAt: string, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined } | null | undefined, updatedBy: { __typename: 'User', id: string, fullname: string | null | undefined } | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined }
    > } };

export type TicketLiveUserDeleteMutationVariables = Exact<{
  id: string | number;
  app: Types.EnumTaskbarApp;
}>;


export type TicketLiveUserDeleteMutation = { ticketLiveUserDelete: { __typename: 'TicketLiveUserDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketLiveUserUpsertMutationVariables = Exact<{
  id: string | number;
  app: Types.EnumTaskbarApp;
  editing: boolean;
}>;


export type TicketLiveUserUpsertMutation = { ticketLiveUserUpsert: { __typename: 'TicketLiveUserUpsertPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketsByOverviewSlimQueryVariables = Exact<{
  overviewId: string | number;
  orderBy?: string | null | undefined;
  orderDirection?: Types.EnumOrderDirection | null | undefined;
  cursor?: string | null | undefined;
  showPriority: boolean;
  showUpdatedBy: boolean;
  pageSize?: number | null | undefined;
  withObjectAttributes?: boolean | null | undefined;
}>;


export type TicketsByOverviewSlimQuery = { ticketsByOverview: { __typename: 'TicketConnection', totalCount: number, edges: Array<{ __typename: 'TicketEdge', cursor: string, node: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, updatedAt: string, aiAgentRunning: boolean | null | undefined, stateColorCode: Types.EnumTicketStateColorCode, updatedBy?: { __typename: 'User', id: string, fullname: string | null | undefined } | null | undefined, customer: { __typename: 'User', id: string, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, organization: { __typename: 'Organization', id: string, name: string | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined }, priority?: { __typename: 'TicketPriority', id: string, name: string, uiColor: string | null | undefined, defaultCreate: boolean }, objectAttributeValues?: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined, hasNextPage: boolean } } };

export type AutocompleteSearchAgentQueryVariables = Exact<{
  input: Types.AutocompleteSearchUserInput;
}>;


export type AutocompleteSearchAgentQuery = { autocompleteSearchAgent: Array<{ __typename: 'AutocompleteSearchUserEntry', value: number, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined, disabled: boolean | null | undefined, icon: string | null | undefined, user: { __typename: 'User', vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined } }> };

export type AutocompleteSearchGenericQueryVariables = Exact<{
  input: Types.AutocompleteSearchGenericInput;
  membersCount?: number | null | undefined;
}>;


export type AutocompleteSearchGenericQuery = { autocompleteSearchGeneric: Array<{ __typename: 'AutocompleteSearchGenericEntry', value: number, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined, disabled: boolean | null | undefined, object:
      | { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, allMembers: { __typename: 'UserConnection', edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, internalId: number, login: string | null | undefined, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, hasSecondaryOrganizations: boolean | null | undefined } }> } | null | undefined }
      | { __typename: 'Ticket' }
      | { __typename: 'User', id: string, internalId: number, login: string | null | undefined, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined } | null | undefined }
     }> };

export type AutocompleteSearchUserQueryVariables = Exact<{
  input: Types.AutocompleteSearchUserInput;
}>;


export type AutocompleteSearchUserQuery = { autocompleteSearchUser: Array<{ __typename: 'AutocompleteSearchUserEntry', value: number, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined, disabled: boolean | null | undefined, icon: string | null | undefined, user: { __typename: 'User', vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined } }> };

export type KnowledgeBaseAnswerSuggestionContentTransformMutationVariables = Exact<{
  translationId: string | number;
  formId: string;
}>;


export type KnowledgeBaseAnswerSuggestionContentTransformMutation = { knowledgeBaseAnswerSuggestionContentTransform: { __typename: 'KnowledgeBaseAnswerSuggestionContentTransformPayload', body: string | null | undefined, attachments: Array<{ __typename: 'StoredFile', id: string, name: string, size: number | null | undefined, type: string | null | undefined, preferences: any }> | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type AiAssistanceTextToolsListQueryVariables = Exact<{
  groupId?: string | number | null | undefined;
  ticketId?: string | number | null | undefined;
  limit?: number | null | undefined;
}>;


export type AiAssistanceTextToolsListQuery = { aiAssistanceTextToolsList: Array<{ __typename: 'AITextTool', id: string, name: string, active: boolean }> };

export type KnowledgeBaseAnswerSuggestionsQueryVariables = Exact<{
  query: string;
}>;


export type KnowledgeBaseAnswerSuggestionsQuery = { knowledgeBaseAnswerSuggestions: Array<{ __typename: 'KnowledgeBaseAnswerTranslation', id: string, title: string, maybeLocale: string | null | undefined, categoryTreeTranslation: Array<{ __typename: 'KnowledgeBaseCategoryTranslation', id: string, title: string }> }> | null | undefined };

export type MentionSuggestionsQueryVariables = Exact<{
  query: string;
  groupId: string | number;
}>;


export type MentionSuggestionsQuery = { mentionSuggestions: Array<{ __typename: 'User', id: string, internalId: number, fullname: string | null | undefined, email: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined }> | null | undefined };

export type TextModuleSuggestionsQueryVariables = Exact<{
  query: string;
  limit?: number | null | undefined;
  ticketId?: string | number | null | undefined;
  customerId?: string | number | null | undefined;
  groupId?: string | number | null | undefined;
}>;


export type TextModuleSuggestionsQuery = { textModuleSuggestions: Array<{ __typename: 'TextModule', id: string, name: string, keywords: string | null | undefined, renderedContent: string | null | undefined }> };

export type AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables = Exact<{
  input: Types.AutocompleteSearchObjectAttributeExternalDataSourceInput;
}>;


export type AutocompleteSearchObjectAttributeExternalDataSourceQuery = { autocompleteSearchObjectAttributeExternalDataSource: Array<{ __typename: 'AutocompleteSearchExternalDataSourceEntry', value: any, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined }> };

export type FormUploadCacheAddMutationVariables = Exact<{
  formId: string;
  files: Array<Types.UploadFileInput> | Types.UploadFileInput;
}>;


export type FormUploadCacheAddMutation = { formUploadCacheAdd: { __typename: 'FormUploadCacheAddPayload', uploadedFiles: Array<{ __typename: 'StoredFile', id: string, name: string, size: number | null | undefined, type: string | null | undefined }> } | null | undefined };

export type FormUploadCacheRemoveMutationVariables = Exact<{
  formId: string;
  fileIds: Array<string | number> | string | number;
}>;


export type FormUploadCacheRemoveMutation = { formUploadCacheRemove: { __typename: 'FormUploadCacheRemovePayload', success: boolean } | null | undefined };

export type AutocompleteSearchOrganizationQueryVariables = Exact<{
  input: Types.AutocompleteSearchOrganizationInput;
}>;


export type AutocompleteSearchOrganizationQuery = { autocompleteSearchOrganization: Array<{ __typename: 'AutocompleteSearchOrganizationEntry', value: number, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined, disabled: boolean | null | undefined, icon: string | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, domain: string | null | undefined, domainAssignment: boolean | null | undefined, active: boolean | null | undefined, note: string | null | undefined, vip: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } }> };

export type AutocompleteSearchRecipientQueryVariables = Exact<{
  input: Types.AutocompleteSearchRecipientInput;
}>;


export type AutocompleteSearchRecipientQuery = { autocompleteSearchRecipient: Array<{ __typename: 'AutocompleteSearchRecipientEntry', value: string, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined, disabled: boolean | null | undefined, icon: string | null | undefined }> };

export type FormUpdaterQueryVariables = Exact<{
  formUpdaterId: Types.EnumFormUpdaterId;
  meta: Types.FormUpdaterMetaInput;
  data: any;
  relationFields: Array<Types.FormUpdaterRelationField> | Types.FormUpdaterRelationField;
  id?: string | number | null | undefined;
}>;


export type FormUpdaterQuery = { formUpdater: { __typename: 'FormUpdaterResult', fields: any, flags: any } };

export type ObjectManagerFrontendAttributesQueryVariables = Exact<{
  object: Types.EnumObjectManagerObjects;
}>;


export type ObjectManagerFrontendAttributesQuery = { objectManagerFrontendAttributes: { __typename: 'ObjectManagerFrontendAttributesPayload', attributes: Array<{ __typename: 'ObjectManagerFrontendAttribute', name: string, display: string, dataType: string, dataOption: any, isInternal: boolean, screens: any }>, screens: Array<{ __typename: 'ObjectManagerScreenAttributes', name: string, attributes: Array<string> }> } | null | undefined };

export type OnlineNotificationDeleteMutationVariables = Exact<{
  onlineNotificationId: string | number;
}>;


export type OnlineNotificationDeleteMutation = { onlineNotificationDelete: { __typename: 'OnlineNotificationDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type OnlineNotificationMarkAllAsSeenMutationVariables = Exact<{
  onlineNotificationIds: Array<string | number> | string | number;
}>;


export type OnlineNotificationMarkAllAsSeenMutation = { onlineNotificationMarkAllAsSeen: { __typename: 'OnlineNotificationMarkAllAsSeenPayload', onlineNotifications: Array<{ __typename: 'OnlineNotification', id: string, seen: boolean }> | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type OnlineNotificationSeenMutationVariables = Exact<{
  objectId: string | number;
}>;


export type OnlineNotificationSeenMutation = { onlineNotificationSeen: { __typename: 'OnlineNotificationSeenPayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type OnlineNotificationsQueryVariables = Exact<{ [key: string]: never; }>;


export type OnlineNotificationsQuery = { onlineNotifications: { __typename: 'OnlineNotificationConnection', edges: Array<{ __typename: 'OnlineNotificationEdge', cursor: string, node: { __typename: 'OnlineNotification', id: string, seen: boolean, createdAt: string, typeName: string, objectName: string, createdBy: { __typename: 'User', id: string, fullname: string | null | undefined, lastname: string | null | undefined, firstname: string | null | undefined, email: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined } | null | undefined, meta: { __typename: 'OnlineNotificationMeta', createdByAi: boolean }, metaObject:
          | { __typename: 'DataPrivacyTask' }
          | { __typename: 'Group' }
          | { __typename: 'KnowledgeBaseAnswerTranslation', id: string, title: string, kbLocale: { __typename: 'KnowledgeBaseLocale', systemLocale: { __typename: 'Locale', locale: string } }, answer: { __typename: 'KnowledgeBaseAnswer', id: string } }
          | { __typename: 'OnlineNotificationStandalone', id: string, internalId: number, data:
              | { __typename: 'OnlineNotificationStandaloneBulkJobData', total: number, failedCount: number }
              | { __typename: 'OnlineNotificationStandaloneKbAnswerGenerationFailedData', errorMessage: string, ticketTitle: string }
             }
          | { __typename: 'Organization' }
          | { __typename: 'Role' }
          | { __typename: 'Ticket', id: string, internalId: number, title: string }
          | { __typename: 'TicketArticle', id: string, internalId: number, bodyWithUrls: string, preferences: any, ticket: { __typename: 'Ticket', id: string, internalId: number, title: string }, to: { __typename: 'AddressesField', raw: string } | null | undefined }
          | { __typename: 'User' }
         | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined, hasNextPage: boolean } } };

export type OnlineNotificationsCountSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type OnlineNotificationsCountSubscription = { onlineNotificationsCount: { __typename: 'OnlineNotificationsCountPayload', unseenCount: number } };

export type OrganizationAttributesFragment = { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, domain: string | null | undefined, domainAssignment: boolean | null | undefined, active: boolean | null | undefined, note: string | null | undefined, vip: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined };

export type OrganizationMembersFragment = { __typename: 'Organization', allMembers: { __typename: 'UserConnection', totalCount: number, edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, internalId: number, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined } }> } | null | undefined };

export type OrganizationMembersWithFetchMoreFragment = { __typename: 'Organization', allMembers: { __typename: 'UserConnection', totalCount: number, edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, internalId: number, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined };

export type OrganizationTaskbarTabAttributesFragment = { __typename: 'Organization', id: string, name: string | null | undefined, active: boolean | null | undefined };

export type OrganizationNoteUpdateMutationVariables = Exact<{
  id: string | number;
  note: string;
}>;


export type OrganizationNoteUpdateMutation = { organizationNoteUpdate: { __typename: 'OrganizationNoteUpdatePayload', organization: { __typename: 'Organization', note: string | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type OrganizationUpdateMutationVariables = Exact<{
  id: string | number;
  input: Types.OrganizationInput;
}>;


export type OrganizationUpdateMutation = { organizationUpdate: { __typename: 'OrganizationUpdatePayload', organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, domain: string | null | undefined, domainAssignment: boolean | null | undefined, active: boolean | null | undefined, note: string | null | undefined, vip: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type OrganizationQueryVariables = Exact<{
  organizationId: string | number;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;


export type OrganizationQuery = { organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, domain: string | null | undefined, domainAssignment: boolean | null | undefined, active: boolean | null | undefined, note: string | null | undefined, vip: boolean | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean }, ticketsCount: { __typename: 'TicketCount', open: number, closed: number, openSearchQuery: string | null | undefined, closedSearchQuery: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, allMembers: { __typename: 'UserConnection', totalCount: number, edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, internalId: number, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined } };

export type OrganizationUpdatesSubscriptionVariables = Exact<{
  organizationId: string | number;
  first?: number | null | undefined;
  after?: string | null | undefined;
  initial?: boolean | null | undefined;
}>;


export type OrganizationUpdatesSubscription = { organizationUpdates: { __typename: 'OrganizationUpdatesPayload', organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, shared: boolean | null | undefined, domain: string | null | undefined, domainAssignment: boolean | null | undefined, active: boolean | null | undefined, note: string | null | undefined, vip: boolean | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean }, ticketsCount: { __typename: 'TicketCount', open: number, closed: number, openSearchQuery: string | null | undefined, closedSearchQuery: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, allMembers: { __typename: 'UserConnection', totalCount: number, edges: Array<{ __typename: 'UserEdge', node: { __typename: 'User', id: string, internalId: number, image: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined } | null | undefined } };

export type PublicLinksQueryVariables = Exact<{
  screen: Types.EnumPublicLinksScreen;
}>;


export type PublicLinksQuery = { publicLinks: Array<{ __typename: 'PublicLink', id: string, link: string, title: string, description: string | null | undefined, newTab: boolean }> | null | undefined };

export type PublicLinkUpdatesSubscriptionVariables = Exact<{
  screen: Types.EnumPublicLinksScreen;
}>;


export type PublicLinkUpdatesSubscription = { publicLinkUpdates: { __typename: 'PublicLinkUpdatesPayload', publicLinks: Array<{ __typename: 'PublicLink', id: string, link: string, title: string, description: string | null | undefined, newTab: boolean }> | null | undefined } };

export type TagAssignmentAddMutationVariables = Exact<{
  objectId: string | number;
  tag: string;
}>;


export type TagAssignmentAddMutation = { tagAssignmentAdd: { __typename: 'TagAssignmentAddPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TagAssignmentRemoveMutationVariables = Exact<{
  objectId: string | number;
  tag: string;
}>;


export type TagAssignmentRemoveMutation = { tagAssignmentRemove: { __typename: 'TagAssignmentRemovePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TagAssignmentUpdateMutationVariables = Exact<{
  objectId: string | number;
  tags: Array<string> | string;
}>;


export type TagAssignmentUpdateMutation = { tagAssignmentUpdate: { __typename: 'TagAssignmentUpdatePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type AutocompleteSearchTagQueryVariables = Exact<{
  input: Types.AutocompleteSearchTagInput;
}>;


export type AutocompleteSearchTagQuery = { autocompleteSearchTag: Array<{ __typename: 'AutocompleteSearchEntry', value: string, label: string }> };

export type SecurityStateFragment = { __typename: 'TicketArticleSecurityState', type: Types.EnumSecurityStateType | null | undefined, signingSuccess: boolean | null | undefined, signingMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, encryptionMessage: string | null | undefined };

export type TicketArticleChangeVisibilityMutationVariables = Exact<{
  articleId: string | number;
  internal: boolean;
}>;


export type TicketArticleChangeVisibilityMutation = { ticketArticleChangeVisibility: { __typename: 'TicketArticleChangeVisibilityPayload', article: { __typename: 'TicketArticle', id: string, internal: boolean } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketArticleDeleteMutationVariables = Exact<{
  articleId: string | number;
}>;


export type TicketArticleDeleteMutation = { ticketArticleDelete: { __typename: 'TicketArticleDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketArticleEmailForwardReplyMutationVariables = Exact<{
  articleId: string | number;
  formId: string;
}>;


export type TicketArticleEmailForwardReplyMutation = { ticketArticleEmailForwardReply: { __typename: 'TicketArticleEmailForwardReplyPayload', quotableFrom: string | null | undefined, quotableTo: string | null | undefined, quotableCc: string | null | undefined, attachments: Array<{ __typename: 'StoredFile', id: string, internalId: number, name: string, size: number | null | undefined, type: string | null | undefined }>, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketArticleRetryMediaDownloadMutationVariables = Exact<{
  articleId: string | number;
}>;


export type TicketArticleRetryMediaDownloadMutation = { ticketArticleRetryMediaDownload: { __typename: 'TicketArticleRetryMediaDownloadPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketArticleRetrySecurityProcessMutationVariables = Exact<{
  articleId: string | number;
}>;


export type TicketArticleRetrySecurityProcessMutation = { ticketArticleRetrySecurityProcess: { __typename: 'TicketArticleRetrySecurityProcessPayload', retryResult: { __typename: 'TicketArticleSecurityState', type: Types.EnumSecurityStateType | null | undefined, signingSuccess: boolean | null | undefined, signingMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, encryptionMessage: string | null | undefined } | null | undefined, article: { __typename: 'TicketArticle', id: string, securityState: { __typename: 'TicketArticleSecurityState', type: Types.EnumSecurityStateType | null | undefined, signingSuccess: boolean | null | undefined, signingMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, encryptionMessage: string | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftStartAttributesFragment = { __typename: 'TicketSharedDraftStart', id: string, name: string | null | undefined, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined };

export type TicketSharedDraftStartCreateMutationVariables = Exact<{
  name: string;
  input: Types.TicketSharedDraftStartInput;
}>;


export type TicketSharedDraftStartCreateMutation = { ticketSharedDraftStartCreate: { __typename: 'TicketSharedDraftStartCreatePayload', sharedDraft: { __typename: 'TicketSharedDraftStart', id: string, name: string | null | undefined, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftStartDeleteMutationVariables = Exact<{
  sharedDraftId: string | number;
}>;


export type TicketSharedDraftStartDeleteMutation = { ticketSharedDraftStartDelete: { __typename: 'TicketSharedDraftStartDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftStartUpdateMutationVariables = Exact<{
  sharedDraftId: string | number;
  input: Types.TicketSharedDraftStartInput;
}>;


export type TicketSharedDraftStartUpdateMutation = { ticketSharedDraftStartUpdate: { __typename: 'TicketSharedDraftStartUpdatePayload', sharedDraft: { __typename: 'TicketSharedDraftStart', id: string, name: string | null | undefined, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftStartListQueryVariables = Exact<{
  groupId: string | number;
}>;


export type TicketSharedDraftStartListQuery = { ticketSharedDraftStartList: Array<{ __typename: 'TicketSharedDraftStart', id: string, name: string | null | undefined, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined }> };

export type TicketSharedDraftStartSingleQueryVariables = Exact<{
  sharedDraftId: string | number;
}>;


export type TicketSharedDraftStartSingleQuery = { ticketSharedDraftStartSingle: { __typename: 'TicketSharedDraftStart', content: any, id: string, name: string | null | undefined, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined } };

export type TicketSharedDraftStartUpdateByGroupSubscriptionVariables = Exact<{
  groupId: string | number;
}>;


export type TicketSharedDraftStartUpdateByGroupSubscription = { ticketSharedDraftStartUpdateByGroup: { __typename: 'TicketSharedDraftStartUpdateByGroupPayload', sharedDraftStarts: Array<{ __typename: 'TicketSharedDraftStart', id: string, name: string | null | undefined, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined }> | null | undefined } };

export type TicketSharedDraftZoomAttributesFragment = { __typename: 'TicketSharedDraftZoom', id: string, ticketId: string | null | undefined, newArticle: any, ticketAttributes: any, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined };

export type TicketSharedDraftZoomCreateMutationVariables = Exact<{
  input: Types.TicketSharedDraftZoomInput;
}>;


export type TicketSharedDraftZoomCreateMutation = { ticketSharedDraftZoomCreate: { __typename: 'TicketSharedDraftZoomCreatePayload', sharedDraft: { __typename: 'TicketSharedDraftZoom', id: string, ticketId: string | null | undefined, newArticle: any, ticketAttributes: any, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftZoomDeleteMutationVariables = Exact<{
  sharedDraftId: string | number;
}>;


export type TicketSharedDraftZoomDeleteMutation = { ticketSharedDraftZoomDelete: { __typename: 'TicketSharedDraftZoomDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftZoomUpdateMutationVariables = Exact<{
  sharedDraftId: string | number;
  input: Types.TicketSharedDraftZoomInput;
}>;


export type TicketSharedDraftZoomUpdateMutation = { ticketSharedDraftZoomUpdate: { __typename: 'TicketSharedDraftZoomUpdatePayload', sharedDraft: { __typename: 'TicketSharedDraftZoom', id: string, ticketId: string | null | undefined, newArticle: any, ticketAttributes: any, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined }, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketSharedDraftZoomShowQueryVariables = Exact<{
  sharedDraftId: string | number;
}>;


export type TicketSharedDraftZoomShowQuery = { ticketSharedDraftZoomShow: { __typename: 'TicketSharedDraftZoom', id: string, ticketId: string | null | undefined, newArticle: any, ticketAttributes: any, updatedAt: string, updatedBy: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, phone: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined } | null | undefined } };

export type OverviewAttributesFragment = { __typename: 'Overview', id: string, internalId: number, name: string, link: string, prio: number, groupBy: string | null | undefined, orderBy: string, orderDirection: Types.EnumOrderDirection, organizationShared: boolean | null | undefined, outOfOffice: boolean | null | undefined, active: boolean, ticketCount?: number };

export type ReferencingTicketFragment = { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } };

export type TicketArticleAttributesFragment = { __typename: 'TicketArticle', id: string, internalId: number, messageId: string | null | undefined, subject: string | null | undefined, messageIdMd5: string | null | undefined, inReplyTo: string | null | undefined, contentType: string, preferences: any, bodyWithUrls: string, bodyRenderingError: boolean, internal: boolean, createdAt: string, detectedLanguage: string | null | undefined, from: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, to: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, cc: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, replyTo: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, attachmentsWithoutInline: Array<{ __typename: 'StoredFile', id: string, internalId: number, name: string, size: number | null | undefined, type: string | null | undefined, preferences: any }>, author: { __typename: 'User', id: string, fullname: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, email: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, authorizations: Array<{ __typename: 'Authorization', provider: string, uid: string, username: string | null | undefined }> | null | undefined }, type: { __typename: 'TicketArticleType', name: string | null | undefined, communication: boolean | null | undefined } | null | undefined, sender: { __typename: 'TicketArticleSender', name: Types.EnumTicketArticleSenderName | null | undefined } | null | undefined, securityState: { __typename: 'TicketArticleSecurityState', encryptionMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, signingMessage: string | null | undefined, signingSuccess: boolean | null | undefined, type: Types.EnumSecurityStateType | null | undefined } | null | undefined, mediaErrorState: { __typename: 'TicketArticleMediaErrorState', error: boolean | null | undefined } | null | undefined, highlightedTexts: Array<{ __typename: 'TicketArticleHighlightedText', startIndex: number, endIndex: number, colorClass: string }> | null | undefined };

export type TicketAttributesFragment = { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined };

export type TicketLiveUserAttributesFragment = { __typename: 'TicketLiveUser', user: { __typename: 'User', id: string, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined }, apps: Array<{ __typename: 'TicketLiveUserApp', name: Types.EnumTaskbarApp, editing: boolean, lastInteraction: string }> };

export type TicketMentionFragment = { __typename: 'Mention', user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined }, userTicketAccess: { __typename: 'PolicyMentionUserTicketAccess', agentReadAccess: boolean } };

export type TicketTaskbarTabAttributesFragment = { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, updatedAt: string, state: { __typename: 'TicketState', id: string, name: string } };

export type TicketCreateMutationVariables = Exact<{
  input: Types.TicketCreateInput;
}>;


export type TicketCreateMutation = { ticketCreate: { __typename: 'TicketCreatePayload', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketCustomerUpdateMutationVariables = Exact<{
  ticketId: string | number;
  input: Types.TicketCustomerUpdateInput;
}>;


export type TicketCustomerUpdateMutation = { ticketCustomerUpdate: { __typename: 'TicketCustomerUpdatePayload', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketMergeMutationVariables = Exact<{
  sourceTicketId: string | number;
  targetTicketId: string | number;
}>;


export type TicketMergeMutation = { ticketMerge: { __typename: 'TicketMergePayload', errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type MentionSubscribeMutationVariables = Exact<{
  ticketId: string | number;
}>;


export type MentionSubscribeMutation = { mentionSubscribe: { __typename: 'MentionSubscribePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketTitleUpdateMutationVariables = Exact<{
  ticketId: string | number;
  title: string;
}>;


export type TicketTitleUpdateMutation = { ticketTitleUpdate: { __typename: 'TicketTitleUpdatePayload', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type MentionUnsubscribeMutationVariables = Exact<{
  ticketId: string | number;
}>;


export type MentionUnsubscribeMutation = { mentionUnsubscribe: { __typename: 'MentionUnsubscribePayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type TicketUpdateMutationVariables = Exact<{
  ticketId: string | number;
  input: Types.TicketUpdateInput;
  meta: Types.TicketUpdateMetaInput;
}>;


export type TicketUpdateMutation = { ticketUpdate: { __typename: 'TicketUpdatePayload', ticket: { __typename: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type AutocompleteSearchTicketQueryVariables = Exact<{
  input: Types.AutocompleteSearchTicketInput;
}>;


export type AutocompleteSearchTicketQuery = { autocompleteSearchTicket: Array<{ __typename: 'AutocompleteSearchTicketEntry', value: string, label: string, labelPlaceholder: Array<string> | null | undefined, heading: string | null | undefined, headingPlaceholder: Array<string> | null | undefined, disabled: boolean | null | undefined, icon: string | null | undefined, ticket: { __typename: 'Ticket', id: string, number: string, internalId: number, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } } }> };

export type TicketQueryVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketQuery = { ticket: { __typename: 'Ticket', aiSummaryEnabled: boolean | null | undefined, id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, createArticleType: { __typename: 'TicketArticleType', id: string, name: string | null | undefined } | null | undefined, mentions: { __typename: 'MentionConnection', totalCount: number, edges: Array<{ __typename: 'MentionEdge', cursor: string, node: { __typename: 'Mention', user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined }, userTicketAccess: { __typename: 'PolicyMentionUserTicketAccess', agentReadAccess: boolean } } }> } | null | undefined, checklist: { __typename: 'Checklist', id: string, completed: boolean, incomplete: number, total: number, complete: number } | null | undefined, referencingChecklistTickets: Array<{ __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }> | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } };

export type TicketArticlesQueryVariables = Exact<{
  ticketId: string | number;
  beforeCursor?: string | null | undefined;
  afterCursor?: string | null | undefined;
  pageSize?: number | null | undefined;
  loadFirstArticles?: boolean | null | undefined;
  firstArticlesCount?: number | null | undefined;
}>;


export type TicketArticlesQuery = { firstArticles?: { __typename: 'TicketArticleConnection', edges: Array<{ __typename: 'TicketArticleEdge', node: { __typename: 'TicketArticle', id: string, internalId: number, messageId: string | null | undefined, subject: string | null | undefined, messageIdMd5: string | null | undefined, inReplyTo: string | null | undefined, contentType: string, preferences: any, bodyWithUrls: string, bodyRenderingError: boolean, internal: boolean, createdAt: string, detectedLanguage: string | null | undefined, from: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, to: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, cc: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, replyTo: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, attachmentsWithoutInline: Array<{ __typename: 'StoredFile', id: string, internalId: number, name: string, size: number | null | undefined, type: string | null | undefined, preferences: any }>, author: { __typename: 'User', id: string, fullname: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, email: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, authorizations: Array<{ __typename: 'Authorization', provider: string, uid: string, username: string | null | undefined }> | null | undefined }, type: { __typename: 'TicketArticleType', name: string | null | undefined, communication: boolean | null | undefined } | null | undefined, sender: { __typename: 'TicketArticleSender', name: Types.EnumTicketArticleSenderName | null | undefined } | null | undefined, securityState: { __typename: 'TicketArticleSecurityState', encryptionMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, signingMessage: string | null | undefined, signingSuccess: boolean | null | undefined, type: Types.EnumSecurityStateType | null | undefined } | null | undefined, mediaErrorState: { __typename: 'TicketArticleMediaErrorState', error: boolean | null | undefined } | null | undefined, highlightedTexts: Array<{ __typename: 'TicketArticleHighlightedText', startIndex: number, endIndex: number, colorClass: string }> | null | undefined } }> }, articles: { __typename: 'TicketArticleConnection', totalCount: number, edges: Array<{ __typename: 'TicketArticleEdge', cursor: string, node: { __typename: 'TicketArticle', id: string, internalId: number, messageId: string | null | undefined, subject: string | null | undefined, messageIdMd5: string | null | undefined, inReplyTo: string | null | undefined, contentType: string, preferences: any, bodyWithUrls: string, bodyRenderingError: boolean, internal: boolean, createdAt: string, detectedLanguage: string | null | undefined, from: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, to: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, cc: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, replyTo: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, attachmentsWithoutInline: Array<{ __typename: 'StoredFile', id: string, internalId: number, name: string, size: number | null | undefined, type: string | null | undefined, preferences: any }>, author: { __typename: 'User', id: string, fullname: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, email: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, authorizations: Array<{ __typename: 'Authorization', provider: string, uid: string, username: string | null | undefined }> | null | undefined }, type: { __typename: 'TicketArticleType', name: string | null | undefined, communication: boolean | null | undefined } | null | undefined, sender: { __typename: 'TicketArticleSender', name: Types.EnumTicketArticleSenderName | null | undefined } | null | undefined, securityState: { __typename: 'TicketArticleSecurityState', encryptionMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, signingMessage: string | null | undefined, signingSuccess: boolean | null | undefined, type: Types.EnumSecurityStateType | null | undefined } | null | undefined, mediaErrorState: { __typename: 'TicketArticleMediaErrorState', error: boolean | null | undefined } | null | undefined, highlightedTexts: Array<{ __typename: 'TicketArticleHighlightedText', startIndex: number, endIndex: number, colorClass: string }> | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined, startCursor: string | null | undefined, hasPreviousPage: boolean } } };

export type TicketArticleUpdatesSubscriptionVariables = Exact<{
  ticketId: string | number;
}>;


export type TicketArticleUpdatesSubscription = { ticketArticleUpdates: { __typename: 'TicketArticleUpdatesPayload', removeArticleId: string | null | undefined, addArticle: { __typename: 'TicketArticle', id: string, createdAt: string, sender: { __typename: 'TicketArticleSender', name: Types.EnumTicketArticleSenderName | null | undefined } | null | undefined } | null | undefined, updateArticle: { __typename: 'TicketArticle', id: string, internalId: number, messageId: string | null | undefined, subject: string | null | undefined, messageIdMd5: string | null | undefined, inReplyTo: string | null | undefined, contentType: string, preferences: any, bodyWithUrls: string, bodyRenderingError: boolean, internal: boolean, createdAt: string, detectedLanguage: string | null | undefined, from: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, to: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, cc: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, replyTo: { __typename: 'AddressesField', raw: string, parsed: Array<{ __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined, isSystemAddress: boolean }> | null | undefined } | null | undefined, attachmentsWithoutInline: Array<{ __typename: 'StoredFile', id: string, internalId: number, name: string, size: number | null | undefined, type: string | null | undefined, preferences: any }>, author: { __typename: 'User', id: string, fullname: string | null | undefined, firstname: string | null | undefined, lastname: string | null | undefined, email: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, authorizations: Array<{ __typename: 'Authorization', provider: string, uid: string, username: string | null | undefined }> | null | undefined }, type: { __typename: 'TicketArticleType', name: string | null | undefined, communication: boolean | null | undefined } | null | undefined, sender: { __typename: 'TicketArticleSender', name: Types.EnumTicketArticleSenderName | null | undefined } | null | undefined, securityState: { __typename: 'TicketArticleSecurityState', encryptionMessage: string | null | undefined, encryptionSuccess: boolean | null | undefined, signingMessage: string | null | undefined, signingSuccess: boolean | null | undefined, type: Types.EnumSecurityStateType | null | undefined } | null | undefined, mediaErrorState: { __typename: 'TicketArticleMediaErrorState', error: boolean | null | undefined } | null | undefined, highlightedTexts: Array<{ __typename: 'TicketArticleHighlightedText', startIndex: number, endIndex: number, colorClass: string }> | null | undefined } | null | undefined } };

export type TicketLiveUserUpdatesSubscriptionVariables = Exact<{
  key: string;
  app: Types.EnumTaskbarApp;
}>;


export type TicketLiveUserUpdatesSubscription = { ticketLiveUserUpdates: { __typename: 'TicketLiveUserUpdatesPayload', liveUsers: Array<{ __typename: 'TicketLiveUser', user: { __typename: 'User', id: string, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, email: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined }, apps: Array<{ __typename: 'TicketLiveUserApp', name: Types.EnumTaskbarApp, editing: boolean, lastInteraction: string }> }> | null | undefined } };

export type TicketUpdatesSubscriptionVariables = Exact<{
  ticketId: string | number;
  initial?: boolean | null | undefined;
}>;


export type TicketUpdatesSubscription = { ticketUpdates: { __typename: 'TicketUpdatesPayload', ticket: { __typename: 'Ticket', aiSummaryEnabled: boolean | null | undefined, id: string, internalId: number, number: string, title: string, createdAt: string, escalationAt: string | null | undefined, aiAgentRunning: boolean | null | undefined, updatedAt: string, pendingTime: string | null | undefined, tags: Array<string> | null | undefined, timeUnit: number | null | undefined, articleCount: number | null | undefined, subscribed: boolean | null | undefined, preferences: any, stateColorCode: Types.EnumTicketStateColorCode, sharedDraftZoomId: string | null | undefined, firstResponseEscalationAt: string | null | undefined, closeEscalationAt: string | null | undefined, updateEscalationAt: string | null | undefined, initialChannel: Types.EnumChannelArea | null | undefined, createArticleType: { __typename: 'TicketArticleType', id: string, name: string | null | undefined } | null | undefined, mentions: { __typename: 'MentionConnection', totalCount: number, edges: Array<{ __typename: 'MentionEdge', cursor: string, node: { __typename: 'Mention', user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, vip: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, active: boolean | null | undefined, image: string | null | undefined }, userTicketAccess: { __typename: 'PolicyMentionUserTicketAccess', agentReadAccess: boolean } } }> } | null | undefined, checklist: { __typename: 'Checklist', id: string, completed: boolean, incomplete: number, total: number, complete: number } | null | undefined, referencingChecklistTickets: Array<{ __typename: 'Ticket', id: string, internalId: number, number: string, title: string, stateColorCode: Types.EnumTicketStateColorCode, state: { __typename: 'TicketState', id: string, name: string } }> | null | undefined, updatedBy: { __typename: 'User', id: string } | null | undefined, owner: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined }, customer: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, image: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, email: string | null | undefined, hasSecondaryOrganizations: boolean | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean } }, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, vip: boolean | null | undefined, active: boolean | null | undefined } | null | undefined, state: { __typename: 'TicketState', id: string, name: string, stateType: { __typename: 'TicketStateType', id: string, name: string } }, group: { __typename: 'Group', id: string, name: string | null | undefined, summaryGeneration: Types.EnumTicketSummaryGeneration | null | undefined, emailAddress: { __typename: 'EmailAddressParsed', name: string | null | undefined, emailAddress: string | null | undefined } | null | undefined }, priority: { __typename: 'TicketPriority', id: string, name: string, defaultCreate: boolean, uiColor: string | null | undefined }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, policy: { __typename: 'PolicyTicket', update: boolean, agentReadAccess: boolean }, timeUnitsPerType: Array<{ __typename: 'TicketTimeAccountingTypeSum', name: string, timeUnit: number }> | null | undefined, externalReferences: { __typename: 'TicketExternalReferences', github: Array<string> | null | undefined, gitlab: Array<string> | null | undefined } | null | undefined } | null | undefined } };

export type TokenAttributesFragment = { __typename: 'Token', id: string, name: string | null | undefined, preferences: any, expiresAt: string | null | undefined, lastUsedAt: string | null | undefined, createdAt: string, user: { __typename: 'User', id: string } | null | undefined };

export type UserCurrentTwoFactorGetMethodConfigurationQueryVariables = Exact<{
  methodName: string;
  token: string;
}>;


export type UserCurrentTwoFactorGetMethodConfigurationQuery = { userCurrentTwoFactorGetMethodConfiguration: any };

export type UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables = Exact<{
  token: string;
}>;


export type UserCurrentTwoFactorRecoveryCodesGenerateMutation = { userCurrentTwoFactorRecoveryCodesGenerate: { __typename: 'UserCurrentTwoFactorRecoveryCodesGeneratePayload', recoveryCodes: Array<string> | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTwoFactorRemoveMethodMutationVariables = Exact<{
  methodName: string;
  token: string;
}>;


export type UserCurrentTwoFactorRemoveMethodMutation = { userCurrentTwoFactorRemoveMethod: { __typename: 'UserCurrentTwoFactorRemoveMethodPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTwoFactorRemoveMethodCredentialsMutationVariables = Exact<{
  methodName: string;
  token: string;
  credentialId: string;
}>;


export type UserCurrentTwoFactorRemoveMethodCredentialsMutation = { userCurrentTwoFactorRemoveMethodCredentials: { __typename: 'UserCurrentTwoFactorRemoveMethodCredentialsPayload', success: boolean | null | undefined } | null | undefined };

export type UserCurrentTwoFactorSetDefaultMethodMutationVariables = Exact<{
  methodName: string;
}>;


export type UserCurrentTwoFactorSetDefaultMethodMutation = { userCurrentTwoFactorSetDefaultMethod: { __typename: 'UserCurrentTwoFactorSetDefaultMethodPayload', success: boolean | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables = Exact<{
  methodName: Types.EnumTwoFactorAuthenticationMethod;
  token: string;
  payload: any;
  configuration: any;
}>;


export type UserCurrentTwoFactorVerifyMethodConfigurationMutation = { userCurrentTwoFactorVerifyMethodConfiguration: { __typename: 'UserCurrentTwoFactorVerifyMethodConfigurationPayload', recoveryCodes: Array<string> | null | undefined, errors: Array<{ __typename: 'UserError', message: string, field: string | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentAccessTokenAddMutationVariables = Exact<{
  input: Types.UserAccessTokenInput;
}>;


export type UserCurrentAccessTokenAddMutation = { userCurrentAccessTokenAdd: { __typename: 'UserCurrentAccessTokenAddPayload', tokenValue: string, token: { __typename: 'Token', id: string, name: string | null | undefined, preferences: any, expiresAt: string | null | undefined, lastUsedAt: string | null | undefined, createdAt: string, user: { __typename: 'User', id: string } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentAccessTokenDeleteMutationVariables = Exact<{
  tokenId: string | number;
}>;


export type UserCurrentAccessTokenDeleteMutation = { userCurrentAccessTokenDelete: { __typename: 'UserCurrentAccessTokenDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentAvatarAddMutationVariables = Exact<{
  images: Types.AvatarInput;
}>;


export type UserCurrentAvatarAddMutation = { userCurrentAvatarAdd: { __typename: 'UserCurrentAvatarAddPayload', avatar: { __typename: 'Avatar', id: string, default: boolean, deletable: boolean, initial: boolean, imageFull: string | null | undefined, imageResize: string | null | undefined, imageHash: string | null | undefined, createdAt: string, updatedAt: string } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentAvatarDeleteMutationVariables = Exact<{
  id: string | number;
}>;


export type UserCurrentAvatarDeleteMutation = { userCurrentAvatarDelete: { __typename: 'UserCurrentAvatarDeletePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentLocaleMutationVariables = Exact<{
  locale: string;
}>;


export type UserCurrentLocaleMutation = { userCurrentLocale: { __typename: 'UserCurrentLocalePayload', success: boolean, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserCurrentTwoFactorConfigurationQueryVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentTwoFactorConfigurationQuery = { userCurrentTwoFactorConfiguration: { __typename: 'UserConfigurationTwoFactor', recoveryCodesExist: boolean, enabledAuthenticationMethods: Array<{ __typename: 'TwoFactorEnabledAuthenticationMethod', configured: boolean, default: boolean, authenticationMethod: Types.EnumTwoFactorAuthenticationMethod }> } };

export type UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables = Exact<{
  methodName: Types.EnumTwoFactorAuthenticationMethod;
  token: string;
}>;


export type UserCurrentTwoFactorInitiateMethodConfigurationQuery = { userCurrentTwoFactorInitiateMethodConfiguration: any };

export type UserCurrentAccessTokenListQueryVariables = Exact<{ [key: string]: never; }>;


export type UserCurrentAccessTokenListQuery = { userCurrentAccessTokenList: Array<{ __typename: 'Token', id: string, name: string | null | undefined, preferences: any, expiresAt: string | null | undefined, lastUsedAt: string | null | undefined, createdAt: string, user: { __typename: 'User', id: string } | null | undefined }> | null | undefined };

export type UserTaskbarTabAttributesFragment = { __typename: 'User', id: string, fullname: string | null | undefined, active: boolean | null | undefined };

export type UserAddMutationVariables = Exact<{
  input: Types.UserInput;
  sendInvite?: boolean | null | undefined;
}>;


export type UserAddMutation = { userAdd: { __typename: 'UserAddPayload', user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserNoteUpdateMutationVariables = Exact<{
  id: string | number;
  note: string;
}>;


export type UserNoteUpdateMutation = { userNoteUpdate: { __typename: 'UserNoteUpdatePayload', user: { __typename: 'User', note: string | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserUpdateMutationVariables = Exact<{
  id: string | number;
  input: Types.UserInput;
}>;


export type UserUpdateMutation = { userUpdate: { __typename: 'UserUpdatePayload', user: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type UserQueryVariables = Exact<{
  userId: string | number;
  secondaryOrganizationsCount?: number | null | undefined;
  after?: string | null | undefined;
  hasOrganizationCounts?: boolean;
}>;


export type UserQuery = { user: { __typename: 'User', hasSecondaryOrganizations: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, image: string | null | undefined, email: string | null | undefined, web: string | null | undefined, vip: boolean | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, fax: string | null | undefined, note: string | null | undefined, source: string | null | undefined, verified: boolean | null | undefined, active: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, openSearchQuery: string | null | undefined, closed: number, closedSearchQuery: string | null | undefined, organizationOpen?: number | null | undefined, organizationOpenSearchQuery?: string | null | undefined, organizationClosed?: number | null | undefined, organizationClosedSearchQuery?: string | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined } | null | undefined, secondaryOrganizations: { __typename: 'OrganizationConnection', totalCount: number, edges: Array<{ __typename: 'OrganizationEdge', node: { __typename: 'Organization', id: string, internalId: number, active: boolean | null | undefined, name: string | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined } };

export type CurrentUserAttributesFragment = { __typename: 'User', email: string | null | undefined, hasBetaUiSwitchAvailable: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, authorizations: Array<{ __typename: 'Authorization', id: string, provider: string, uid: string, username: string | null | undefined }> | null | undefined, permissions: { __typename: 'UserPermission', names: Array<string> } | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined };

export type ErrorsFragment = { __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined };

type HistoryIssuer_AiAgent_Fragment = { __typename: 'AIAgent', id: string, name: string };

type HistoryIssuer_Job_Fragment = { __typename: 'Job', id: string, name: string };

type HistoryIssuer_Macro_Fragment = { __typename: 'Macro', id: string, name: string };

type HistoryIssuer_ObjectClass_Fragment = { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined };

type HistoryIssuer_PostmasterFilter_Fragment = { __typename: 'PostmasterFilter', id: string, name: string };

type HistoryIssuer_Trigger_Fragment = { __typename: 'Trigger', id: string, name: string };

type HistoryIssuer_User_Fragment = { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, email: string | null | undefined, image: string | null | undefined };

export type HistoryIssuerFragment =
  | HistoryIssuer_AiAgent_Fragment
  | HistoryIssuer_Job_Fragment
  | HistoryIssuer_Macro_Fragment
  | HistoryIssuer_ObjectClass_Fragment
  | HistoryIssuer_PostmasterFilter_Fragment
  | HistoryIssuer_Trigger_Fragment
  | HistoryIssuer_User_Fragment
;

type HistoryEventObject_Checklist_Fragment = { __typename: 'Checklist', id: string, name: string | null | undefined };

type HistoryEventObject_ChecklistItem_Fragment = { __typename: 'ChecklistItem', id: string, text: string, checked: boolean };

type HistoryEventObject_Group_Fragment = { __typename: 'Group', id: string, name: string | null | undefined };

type HistoryEventObject_Mention_Fragment = { __typename: 'Mention', id: string, user: { __typename: 'User', id: string, fullname: string | null | undefined } };

type HistoryEventObject_ObjectClass_Fragment = { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined };

type HistoryEventObject_Organization_Fragment = { __typename: 'Organization', id: string, name: string | null | undefined };

type HistoryEventObject_Ticket_Fragment = { __typename: 'Ticket', id: string, internalId: number, number: string, title: string };

type HistoryEventObject_TicketArticle_Fragment = { __typename: 'TicketArticle', id: string, body: string };

type HistoryEventObject_TicketSharedDraftZoom_Fragment = { __typename: 'TicketSharedDraftZoom', id: string };

type HistoryEventObject_User_Fragment = { __typename: 'User', id: string, fullname: string | null | undefined };

export type HistoryEventObjectFragment =
  | HistoryEventObject_Checklist_Fragment
  | HistoryEventObject_ChecklistItem_Fragment
  | HistoryEventObject_Group_Fragment
  | HistoryEventObject_Mention_Fragment
  | HistoryEventObject_ObjectClass_Fragment
  | HistoryEventObject_Organization_Fragment
  | HistoryEventObject_Ticket_Fragment
  | HistoryEventObject_TicketArticle_Fragment
  | HistoryEventObject_TicketSharedDraftZoom_Fragment
  | HistoryEventObject_User_Fragment
;

export type HistoryEventFragment = { __typename: 'HistoryRecordEvent', createdAt: string, action: string, attribute: string | null | undefined, changes: any, object:
    | { __typename: 'Checklist', id: string, name: string | null | undefined }
    | { __typename: 'ChecklistItem', id: string, text: string, checked: boolean }
    | { __typename: 'Group', id: string, name: string | null | undefined }
    | { __typename: 'Mention', id: string, user: { __typename: 'User', id: string, fullname: string | null | undefined } }
    | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
    | { __typename: 'Organization', id: string, name: string | null | undefined }
    | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string }
    | { __typename: 'TicketArticle', id: string, body: string }
    | { __typename: 'TicketSharedDraftZoom', id: string }
    | { __typename: 'User', id: string, fullname: string | null | undefined }
   };

export type HistoryGroupFragment = { __typename: 'HistoryGroup', createdAt: string, records: Array<{ __typename: 'HistoryRecord', issuer:
      | { __typename: 'AIAgent', id: string, name: string }
      | { __typename: 'Job', id: string, name: string }
      | { __typename: 'Macro', id: string, name: string }
      | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
      | { __typename: 'PostmasterFilter', id: string, name: string }
      | { __typename: 'Trigger', id: string, name: string }
      | { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, phone: string | null | undefined, email: string | null | undefined, image: string | null | undefined }
    , events: Array<{ __typename: 'HistoryRecordEvent', createdAt: string, action: string, attribute: string | null | undefined, changes: any, object:
        | { __typename: 'Checklist', id: string, name: string | null | undefined }
        | { __typename: 'ChecklistItem', id: string, text: string, checked: boolean }
        | { __typename: 'Group', id: string, name: string | null | undefined }
        | { __typename: 'Mention', id: string, user: { __typename: 'User', id: string, fullname: string | null | undefined } }
        | { __typename: 'ObjectClass', klass: string | null | undefined, info: string | null | undefined }
        | { __typename: 'Organization', id: string, name: string | null | undefined }
        | { __typename: 'Ticket', id: string, internalId: number, number: string, title: string }
        | { __typename: 'TicketArticle', id: string, body: string }
        | { __typename: 'TicketSharedDraftZoom', id: string }
        | { __typename: 'User', id: string, fullname: string | null | undefined }
       }> }> };

export type ObjectAttributeValuesFragment = { __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } };

export type PublicLinkAttributesFragment = { __typename: 'PublicLink', id: string, link: string, title: string, description: string | null | undefined, newTab: boolean };

export type SessionFragment = { __typename: 'Session', id: string, afterAuth: { __typename: 'SessionAfterAuth', type: Types.EnumAfterAuthType, data: any } | null | undefined };

export type SimpleTicketAttributeFragment = { __typename: 'Ticket', number: string, internalId: number, id: string, title: string, createdAt: string, stateColorCode: Types.EnumTicketStateColorCode, customer: { __typename: 'User', id: string, fullname: string | null | undefined }, organization: { __typename: 'Organization', id: string, name: string | null | undefined } | null | undefined, group: { __typename: 'Group', id: string, name: string | null | undefined }, state: { __typename: 'TicketState', id: string, name: string } };

export type UserAttributesFragment = { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined };

export type UserDetailAttributesFragment = { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, image: string | null | undefined, email: string | null | undefined, web: string | null | undefined, vip: boolean | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, fax: string | null | undefined, note: string | null | undefined, source: string | null | undefined, verified: boolean | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined } | null | undefined, secondaryOrganizations: { __typename: 'OrganizationConnection', totalCount: number, edges: Array<{ __typename: 'OrganizationEdge', node: { __typename: 'Organization', id: string, internalId: number, active: boolean | null | undefined, name: string | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined };

export type UserPersonalSettingsFragment = { __typename: 'User', personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined };

export type AiAnalyticsUsageMutationVariables = Exact<{
  aiAnalyticsRunId: string | number;
  input: Types.AiAnalyticsUsageInput;
}>;


export type AiAnalyticsUsageMutation = { aiAnalyticsUsage: { __typename: 'AIAnalyticsUsagePayload', usage: { __typename: 'AIAnalyticsUsage', id: string } | null | undefined } | null | undefined };

export type AiAssistanceTextToolsRunMutationVariables = Exact<{
  input: string;
  textToolId: string | number;
  templateRenderContext: Types.TemplateRenderContextInput;
}>;


export type AiAssistanceTextToolsRunMutation = { aiAssistanceTextToolsRun: { __typename: 'AIAssistanceTextToolsRunPayload', output: string | null | undefined } | null | undefined };

export type LoginMutationVariables = Exact<{
  input: Types.LoginInput;
}>;


export type LoginMutation = { login: { __typename: 'LoginPayload', session: { __typename: 'Session', id: string, afterAuth: { __typename: 'SessionAfterAuth', type: Types.EnumAfterAuthType, data: any } | null | undefined } | null | undefined, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined, twoFactorRequired: { __typename: 'UserLoginTwoFactorMethods', availableTwoFactorAuthenticationMethods: Array<Types.EnumTwoFactorAuthenticationMethod>, defaultTwoFactorAuthenticationMethod: Types.EnumTwoFactorAuthenticationMethod | null | undefined, recoveryCodesAvailable: boolean } | null | undefined } | null | undefined };

export type LogoutMutationVariables = Exact<{ [key: string]: never; }>;


export type LogoutMutation = { logout: { __typename: 'LogoutPayload', success: boolean, externalLogoutUrl: string | null | undefined } | null | undefined };

export type TwoFactorMethodInitiateAuthenticationMutationVariables = Exact<{
  login: string;
  password: string;
  twoFactorMethod: Types.EnumTwoFactorAuthenticationMethod;
}>;


export type TwoFactorMethodInitiateAuthenticationMutation = { twoFactorMethodInitiateAuthentication: { __typename: 'TwoFactorMethodInitiateAuthenticationPayload', initiationData: any, errors: Array<{ __typename: 'UserError', message: string, messagePlaceholder: Array<string> | null | undefined, field: string | null | undefined, exception: Types.EnumUserErrorException | null | undefined }> | null | undefined } | null | undefined };

export type ProductAboutQueryVariables = Exact<{ [key: string]: never; }>;


export type ProductAboutQuery = { productAbout: string };

export type ApplicationBuildChecksumQueryVariables = Exact<{ [key: string]: never; }>;


export type ApplicationBuildChecksumQuery = { applicationBuildChecksum: string };

export type ApplicationConfigQueryVariables = Exact<{ [key: string]: never; }>;


export type ApplicationConfigQuery = { applicationConfig: Array<{ __typename: 'KeyComplexValue', key: string, value: any }> };

export type CurrentUserQueryVariables = Exact<{ [key: string]: never; }>;


export type CurrentUserQuery = { currentUser: { __typename: 'User', email: string | null | undefined, hasBetaUiSwitchAvailable: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, authorizations: Array<{ __typename: 'Authorization', id: string, provider: string, uid: string, username: string | null | undefined }> | null | undefined, permissions: { __typename: 'UserPermission', names: Array<string> } | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined } };

export type LocalesQueryVariables = Exact<{
  onlyActive?: boolean | null | undefined;
}>;


export type LocalesQuery = { locales: Array<{ __typename: 'Locale', locale: string, alias: string | null | undefined, name: string, dir: Types.EnumTextDirection, active: boolean }> };

export type MacrosQueryVariables = Exact<{
  selector: Types.TicketMacrosSelectorInput;
}>;


export type MacrosQuery = { macros: Array<{ __typename: 'Macro', id: string, internalId: number, active: boolean, name: string, uxFlowNextUp: string }> };

export type SessionQueryVariables = Exact<{ [key: string]: never; }>;


export type SessionQuery = { session: { __typename: 'Session', id: string, afterAuth: { __typename: 'SessionAfterAuth', type: Types.EnumAfterAuthType, data: any } | null | undefined } };

export type TranslationsQueryVariables = Exact<{
  locale: string;
  cacheKey?: string | null | undefined;
}>;


export type TranslationsQuery = { translations: { __typename: 'TranslationsPayload', isCacheStillValid: boolean, cacheKey: string | null | undefined, translations: any } | null | undefined };

export type AiTextToolUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type AiTextToolUpdatesSubscription = { aiTextToolUpdates: { __typename: 'AITextToolUpdatesPayload', textToolId: string | null | undefined, groupIds: Array<string> | null | undefined, removeTextToolId: string | null | undefined } };

export type AppMaintenanceSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type AppMaintenanceSubscription = { appMaintenance: { __typename: 'AppMaintenancePayload', type: Types.EnumAppMaintenanceType | null | undefined } };

export type ConfigUpdatesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type ConfigUpdatesSubscription = { configUpdates: { __typename: 'ConfigUpdatesPayload', setting: { __typename: 'KeyComplexValue', key: string, value: any } | null | undefined } };

export type CurrentUserUpdatesSubscriptionVariables = Exact<{
  userId: string | number;
}>;


export type CurrentUserUpdatesSubscription = { userUpdates: { __typename: 'UserUpdatesPayload', user: { __typename: 'User', email: string | null | undefined, hasBetaUiSwitchAvailable: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, image: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, preferences: any, hasSecondaryOrganizations: boolean | null | undefined, authorizations: Array<{ __typename: 'Authorization', id: string, provider: string, uid: string, username: string | null | undefined }> | null | undefined, permissions: { __typename: 'UserPermission', names: Array<string> } | null | undefined, outOfOfficeReplacement: { __typename: 'User', id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, login: string | null | undefined, phone: string | null | undefined, email: string | null | undefined } | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined } | null | undefined, personalSettings: { __typename: 'UserPersonalSettings', notificationConfig: { __typename: 'UserPersonalSettingsNotificationConfig', groupIds: Array<number> | null | undefined, matrix: { __typename: 'UserPersonalSettingsNotificationMatrix', create: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, escalation: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, reminderReached: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined, update: { __typename: 'UserPersonalSettingsNotificationMatrixRow', channel: { __typename: 'UserPersonalSettingsNotificationMatrixChannel', email: boolean | null | undefined, online: boolean | null | undefined } | null | undefined, criteria: { __typename: 'UserPersonalSettingsNotificationMatrixCriteria', no: boolean | null | undefined, ownedByMe: boolean | null | undefined, ownedByNobody: boolean | null | undefined, subscribed: boolean | null | undefined } | null | undefined } | null | undefined } | null | undefined } | null | undefined, notificationSound: { __typename: 'UserPersonalSettingsNotificationSound', enabled: boolean | null | undefined, file: Types.EnumNotificationSoundFile | null | undefined } | null | undefined } | null | undefined } | null | undefined } };

export type MacrosUpdateSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type MacrosUpdateSubscription = { macrosUpdate: { __typename: 'MacrosUpdatePayload', macroId: string | null | undefined, groupIds: Array<string> | null | undefined, removeMacroId: string | null | undefined } };

export type PushMessagesSubscriptionVariables = Exact<{ [key: string]: never; }>;


export type PushMessagesSubscription = { pushMessages: { __typename: 'PushMessagesPayload', title: string | null | undefined, text: string | null | undefined } };

export type UserUpdatesSubscriptionVariables = Exact<{
  userId: string | number;
  secondaryOrganizationsCount?: number | null | undefined;
  after?: string | null | undefined;
  hasOrganizationCounts?: boolean;
  initial?: boolean | null | undefined;
}>;


export type UserUpdatesSubscription = { userUpdates: { __typename: 'UserUpdatesPayload', user: { __typename: 'User', hasSecondaryOrganizations: boolean | null | undefined, id: string, internalId: number, firstname: string | null | undefined, lastname: string | null | undefined, fullname: string | null | undefined, outOfOffice: boolean | null | undefined, outOfOfficeStartAt: string | null | undefined, outOfOfficeEndAt: string | null | undefined, image: string | null | undefined, email: string | null | undefined, web: string | null | undefined, vip: boolean | null | undefined, phone: string | null | undefined, mobile: string | null | undefined, fax: string | null | undefined, note: string | null | undefined, source: string | null | undefined, verified: boolean | null | undefined, active: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, openSearchQuery: string | null | undefined, closed: number, closedSearchQuery: string | null | undefined, organizationOpen?: number | null | undefined, organizationOpenSearchQuery?: string | null | undefined, organizationClosed?: number | null | undefined, organizationClosedSearchQuery?: string | null | undefined } | null | undefined, policy: { __typename: 'PolicyDefault', update: boolean }, objectAttributeValues: Array<{ __typename: 'ObjectAttributeValue', value: any, renderedLink: string | null | undefined, attribute: { __typename: 'ObjectManagerFrontendAttribute', name: string, display: string } }> | null | undefined, organization: { __typename: 'Organization', id: string, internalId: number, name: string | null | undefined, active: boolean | null | undefined, vip: boolean | null | undefined, ticketsCount: { __typename: 'TicketCount', open: number, closed: number } | null | undefined } | null | undefined, secondaryOrganizations: { __typename: 'OrganizationConnection', totalCount: number, edges: Array<{ __typename: 'OrganizationEdge', node: { __typename: 'Organization', id: string, internalId: number, active: boolean | null | undefined, name: string | null | undefined } }>, pageInfo: { __typename: 'PageInfo', endCursor: string | null | undefined } } | null | undefined } | null | undefined } };
