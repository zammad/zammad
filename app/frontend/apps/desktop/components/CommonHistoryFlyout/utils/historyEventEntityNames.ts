// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// TODO: Think about a better way to avoid duplication.

export const eventEntityNames: Record<string, string> = {
  TicketArticle: __('Article'),
  'Ticket::Article': __('Article'),
  TicketSharedDraftZoom: __('Shared draft'),
  'Ticket::SharedDraftZoom': __('Shared draft'),
  ChecklistItem: __('Checklist item'),
  'Checklist::Item': __('Checklist item'),
}
