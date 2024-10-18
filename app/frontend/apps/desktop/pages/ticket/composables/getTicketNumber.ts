// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const getTicketNumberWithHook = (
  ticketHook: string,
  ticketNumber: string,
) => {
  return `${ticketHook}${ticketNumber}`
}
