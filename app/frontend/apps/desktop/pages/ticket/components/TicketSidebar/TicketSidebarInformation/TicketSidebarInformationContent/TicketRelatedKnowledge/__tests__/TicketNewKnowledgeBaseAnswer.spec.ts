// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockAutocompleteSearchKnowledgeBaseAnswerQuery,
  waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/autocompleteSearch.mocks.ts'
import TicketNewKnowledgeBaseAnswer from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/TicketNewKnowledgeBaseAnswer.vue'
import {
  mockLinkAddMutation,
  waitForLinkAddMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/linkAdd.mocks.ts'
import { mockLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'

const ticketId = convertToGraphQLId('Ticket', 1)
const answerId = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

const TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

const options = [
  {
    __typename: 'AutocompleteSearchKnowledgeBaseAnswerEntry' as const,
    value: answerId,
    label: 'Reset your password',
    heading: 'Account',
    visibility: EnumKnowledgeBaseVisibility.Published,
  },
]

const renderNewAnswer = () =>
  renderComponent(TicketNewKnowledgeBaseAnswer, {
    props: {
      linkedAnswerIds: [],
      ticketId,
      targetType: TARGET_TYPE,
      newKnowledgeBaseAnswer: true,
    },
    form: true,
    router: true,
    dialog: true,
    store: true,
  })

describe('TicketNewKnowledgeBaseAnswer', () => {
  beforeEach(() => {
    mockLinkListQuery({ linkList: [] })
  })

  it('links the picked answer and closes the picker', async () => {
    mockLinkAddMutation({ linkAdd: { link: null, errors: null } })

    const wrapper = renderNewAnswer()

    await wrapper.events.click(await wrapper.findByRole('combobox'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchKnowledgeBaseAnswerQuery({
      autocompleteSearchKnowledgeBaseAnswer: options,
    })

    await wrapper.events.type(filterElement, 'password')

    await waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls()

    await wrapper.events.click(await wrapper.findByRole('option', { name: /Reset your password/ }))

    const calls = await waitForLinkAddMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: answerId,
        targetId: ticketId,
        type: 'normal',
      },
    })

    // Committing a selection closes the picker.
    await waitFor(() => {
      expect(wrapper.emitted('update:newKnowledgeBaseAnswer')).toContainEqual([false])
    })
  })
})
