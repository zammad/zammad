// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { InputMaybe } from '#shared/graphql/types.ts'

export type AddNewChecklistInput = {
  ticketId?: InputMaybe<string>
  ticketInternalId?: InputMaybe<number>
  ticketNumber?: InputMaybe<string>
  templateId?: InputMaybe<string>
}
