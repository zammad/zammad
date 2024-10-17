// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type Checklist } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<Checklist> => {
  return {
    __typename: 'Checklist',
    id: convertToGraphQLId('Checklist', 999),
    name: 'Test checklist',
    complete: 0,
    completed: false,
    incomplete: 1,
    total: 1,
    // items: [
    //   {
    //     __typename: 'ChecklistItem',
    //     id: convertToGraphQLId('Checklist::Item', 999),
    //     text: 'Test checklist item',
    //     checked: false,
    //     ticketReference: null,
    //   },
    // ],
  }
}
