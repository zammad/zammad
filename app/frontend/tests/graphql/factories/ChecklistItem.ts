// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ChecklistItem } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<ChecklistItem> => {
  return {
    __typename: 'ChecklistItem',
    id: convertToGraphQLId('Checklist::Item', 999),
    text: 'Test checklist item',
    checked: false,
    ticketReference: null,
  }
}
