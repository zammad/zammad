// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { TagAssignmentUpdateDocument } from '#shared/entities/tags/graphql/mutations/assignment/update.api.ts'

import TicketTags from '../TicketTags.vue'

beforeAll(async () => {
  await import('#mobile/components/Form/fields/FieldTags/FieldTagsDialog.vue')
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

  it('can not add new ticket tags when it is allowed', async () => {
    mockApplicationConfig({
      tag_new: false,
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

    const filterInput = wrapper.getByPlaceholderText('Tag name…')
    await wrapper.events.type(filterInput, 'pay')

    expect(
      wrapper.queryByRole('button', { name: 'Create tag' }),
    ).not.toBeInTheDocument()
  })

  it('can add new ticket tags when it is allowed', async () => {
    mockApplicationConfig({
      tag_new: true,
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

    const filterInput = wrapper.getByPlaceholderText('Tag name…')
    await wrapper.events.type(filterInput, 'pay')

    expect(
      wrapper.getByRole('button', { name: 'Create tag' }),
    ).toBeInTheDocument()
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
