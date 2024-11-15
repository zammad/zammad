// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// TODO: Think about a better way to avoid duplication.

export const eventEntityNames: Record<string, string> = {
  TicketArticle: __('Article'),
  'Ticket::Article': __('Article'),
  TicketSharedDraftZoom: __('Shared Draft'),
  'Ticket::SharedDraftZoom': __('Shared Draft'),
  ChecklistItem: __('Checklist Item'),
  'Checklist::Item': __('Checklist Item'),
}
