// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { TagAssignmentUpdateDocument } from '@shared/entities/tags/graphql/mutations/assignment/update.api'
import { renderComponent } from '@tests/support/components'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import TicketTags from '../TicketTags.vue'

beforeAll(async () => {
  await import('@shared/components/Form/fields/FieldTags/FieldTagsDialog.vue')
})

describe('TicketTags', () => {
  it('renders tags field with given ticket', () => {
    const wrapper = renderComponent(TicketTags, {
      props: {
        ticket: {
          id: 1,
          tags: ['tag1', 'tag2'],
        },
      },
      form: true,
      dialog: true,
    })

    expect(wrapper.getByLabelText('Tags')).toBeInTheDocument()

    const tags = wrapper.getAllByRole('listitem')
    expect(tags).toHaveLength(2)
    expect(tags[0]).toHaveTextContent('tag1')
    expect(tags[1]).toHaveTextContent('tag2')
  })

  it('can update ticket tags', async () => {
    const mockTagAssignmentUpdateApi = mockGraphQLApi(
      TagAssignmentUpdateDocument,
    ).willResolve({
      tagAssignmentUpdate: {
        success: true,
        errors: null,
      },
    })

    const wrapper = renderComponent(TicketTags, {
      props: {
        ticket: {
          id: 1,
          tags: ['tag1', 'tag2'],
        },
      },
      form: true,
      dialog: true,
    })

    const tagsField = wrapper.getByLabelText('Tags')

    await wrapper.events.click(tagsField)

    const options = wrapper.getAllByRole('option')
    await wrapper.events.click(options[0])

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Done' }))

    await waitUntil(() => mockTagAssignmentUpdateApi.calls.resolve === 1)

    const tags = wrapper.getAllByRole('listitem')
    expect(tags).toHaveLength(1)
    expect(tags[0]).toHaveTextContent('tag2')
  })

  it('reset ticket tags again on update error', async () => {
    const mockTagAssignmentUpdateApi = mockGraphQLApi(
      TagAssignmentUpdateDocument,
    ).willFailWithError([
      { message: 'Ticket tags not updated.', extensions: {} },
    ])

    const wrapper = renderComponent(TicketTags, {
      props: {
        ticket: {
          id: 1,
          tags: ['tag1', 'tag2'],
        },
      },
      form: true,
      dialog: true,
    })

    const tagsField = wrapper.getByLabelText('Tags')

    await wrapper.events.click(tagsField)

    const options = wrapper.getAllByRole('option')
    await wrapper.events.click(options[0])

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Done' }))

    await waitUntil(() => mockTagAssignmentUpdateApi.calls.error === 1)

    const tags = wrapper.getAllByRole('listitem')
    expect(tags).toHaveLength(2)
    expect(tags[0]).toHaveTextContent('tag1')
    expect(tags[1]).toHaveTextContent('tag2')
  })
})
