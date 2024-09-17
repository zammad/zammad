// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'

export const behaviorOptions = [
  {
    key: EnumTicketScreenBehavior.StayOnTab,
    label: __('Stay on tab'),
  },
  {
    key: EnumTicketScreenBehavior.CloseTab,
    label: __('Close tab'),
  },
  {
    key: EnumTicketScreenBehavior.CloseTabOnTicketClose,
    label: __('Close tab on ticket close'),
  },
  // :TODO Add this option as soon as overview is implemented
  // {
  //   key: EnumTicketScreenBehavior.CloseNextInOverview,
  //   label: __('Next in overview'),
  // },
]

export const behaviorOptionLookup = behaviorOptions.reduce(
  (acc, option) => {
    acc[option.key] = option
    return acc
  },
  {} as Record<EnumTicketScreenBehavior, (typeof behaviorOptions)[0]>,
)
