// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTicketArticleSenderName,
  type Ticket,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'

type FormUpdaterType = {
  __typename: 'FormUpdaterResult'
  fields: {
    form_id: { value: string }
    group_id: {
      value: number
      show: boolean
      hidden: boolean
      rejectNonExistentValues: boolean
      clearable: boolean
      disabled: boolean
      required: boolean
      options: { value: number; label: string }[]
    }
    owner_id: {
      show: boolean
      hidden: boolean
      rejectNonExistentValues: boolean
      clearable: boolean
      disabled: boolean
      required: boolean
      options: { value: number; label: string }[]
    }
    state_id: {
      value: number
      show: boolean
      hidden: boolean
      rejectNonExistentValues: boolean
      clearable: boolean
      disabled: boolean
      required: boolean
      options: { value: number; label: string }[]
    }
    priority_id: {
      value: number
      show: boolean
      hidden: boolean
      rejectNonExistentValues: boolean
      clearable: boolean
      disabled: boolean
      required: boolean
      options: { value: number; label: string }[]
    }
    articleType: { value: string }
    internal: { value: boolean }
    body: { value: string }
    number: {
      show: boolean
      hidden: boolean
      disabled: boolean
      required: boolean
    }
    title: {
      show: boolean
      hidden: boolean
      disabled: boolean
      required: boolean
    }
    customer_id: {
      show: boolean
      hidden: boolean
      disabled: boolean
      required: boolean
    }
    organization_id: {
      show: boolean
      hidden: boolean
      disabled: boolean
      required: boolean
    }
    pending_time: {
      show: boolean
      hidden: boolean
      disabled: boolean
      required: boolean
    }
    tags: {
      show: boolean
      hidden: boolean
      disabled: boolean
      required: boolean
    }
  }
}

export const setupMocks = async (setup?: {
  permission?: string
  allowInternalNote?: boolean
  articleArr?: { node: ReturnType<typeof createDummyArticle> }[]
  /**
   * @default ticketId = 1
   */
  ticket?: ReturnType<typeof createDummyTicket>
  formUpdaterFields?: FormUpdaterType // :TODO Cast parameter type to mockFormUpdaterQuery
}) => {
  const defaults = {
    permission: 'ticket.agent',
    allowInternalNote: true,
    ticket: createDummyTicket({
      state: {
        id: convertToGraphQLId('Ticket::State', 1),
        name: 'open',
        stateType: {
          id: convertToGraphQLId('TicketStateType', 1),
          name: 'open',
        },
      },
      articleType: 'email',
      defaultPolicy: {
        update: true,
        agentReadAccess: true,
      },
    }),
    articleArr: [
      {
        node: createDummyArticle({
          articleType: 'email',
          internal: false,
          senderName: EnumTicketArticleSenderName.Customer,
        }),
      },
    ],
    fields: {
      form_id: {
        value: 'd1bc4a2d-f894-4e91-8509-854f04008c4a',
      },
      group_id: {
        value: 3,
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: true,
        disabled: false,
        required: true,
        options: [
          {
            value: 1,
            label: 'Users',
          },
          {
            value: 2,
            label: 'test group',
          },
        ],
      },
      owner_id: {
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: true,
        disabled: false,
        required: false,
        options: [
          {
            value: 3,
            label: 'Test Admin Agent',
          },
        ],
      },
      state_id: {
        value: 2,
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: false,
        disabled: false,
        required: true,
        options: [
          {
            value: 4,
            label: 'closed',
          },
          {
            value: 2,
            label: 'open',
          },
          {
            value: 6,
            label: 'pending close',
          },
          {
            value: 3,
            label: 'pending reminder',
          },
        ],
      },
      priority_id: {
        value: 3,
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: false,
        disabled: false,
        required: true,
        options: [
          {
            value: 1,
            label: '1 low',
          },
          {
            value: 2,
            label: '2 normal',
          },
          {
            value: 3,
            label: '3 high',
          },
        ],
      },
      articleType: {
        value: 'note',
      },
      internal: {
        value: true,
      },
      body: {
        value: '',
      },
      number: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      title: {
        show: true,
        hidden: false,
        disabled: false,
        required: true,
      },
      customer_id: {
        show: true,
        hidden: false,
        disabled: false,
        required: true,
      },
      organization_id: {
        show: true,
        hidden: true,
        disabled: false,
        required: false,
      },
      pending_time: {
        show: false,
        hidden: false,
        disabled: false,
        required: false,
      },
      tags: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
    },
    ...setup,
  }

  mockPermissions([defaults.permission])

  if (defaults.allowInternalNote)
    await mockApplicationConfig({
      ui_ticket_zoom_article_note_new_internal: true,
    })

  mockTicketQuery({
    ticket: defaults.ticket as Ticket,
  })

  mockTicketArticlesQuery({
    articles: {
      totalCount: defaults.articleArr?.length || 1,
      edges: defaults.articleArr,
    },
  })

  mockFormUpdaterQuery({
    formUpdater: {
      __typename: 'FormUpdaterResult',
      fields: defaults.fields,
    },
  })

  mockUserCurrentTaskbarItemListQuery({
    userCurrentTaskbarItemList: [
      {
        formNewArticlePresent: false,
      },
    ],
  })
}
