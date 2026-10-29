// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export const getTicketPriorityLinkColorClasses = (uiColor?: Maybe<string>) => {
  switch (uiColor) {
    case 'high-priority':
      return 'text-red-500'
    case 'low-priority':
      return 'text-muted'
    default:
      return ''
  }
}
