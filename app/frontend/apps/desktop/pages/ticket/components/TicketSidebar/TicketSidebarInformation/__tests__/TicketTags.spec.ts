// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import {
  mockTagAssignmentAddMutation,
  waitForTagAssignmentAddMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/add.mocks.ts'
import {
  mockTagAssignmentRemoveMutation,
  waitForTagAssignmentRemoveMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/remove.mocks.ts'
import {
  mockAutocompleteSearchTagQuery,
  waitForAutocompleteSearchTagQueryCalls,
} from '#shared/entities/tags/graphql/queries/autocompleteTags.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { type AutocompleteSearchEntry } from '#shared/graphql/types.ts'

import TicketTags, {
  type Props,
} from '../TicketSidebarInformationContent/TicketTags.vue'

vi.mock('vue-router', async () => {
  const mod = await vi.importActual<typeof import('vue-router')>('vue-router')

  return {
    ...mod,
    onBeforeRouteUpdate: vi.fn(),
  }
})

const testTags = ['tag 1', 'tag 2', 'tag 3']

const testTicket = createDummyTicket({
  tags: testTags,
})

const testOptions: AutocompleteSearchEntry[] = [
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 1',
    label: 'tag 1',
  },
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 2',
    label: 'tag 2',
  },
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 3',
    label: 'tag 3',
  },
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 4',
    label: 'tag 4',
  },
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 5',
    label: 'tag 5',
  },
]

const renderTicketTags = (props: Partial<Props> = {}) =>
  renderComponent(TicketTags, {
    props: {
      ticket: testTicket,
      isTicketEditable: true,
      ...props,
    },
    router: true,
    form: true,
  })

describe('TicketTags', () => {
  it('shows current ticket tags', () => {
    const view = renderTicketTags()

    const tags = view.getAllByRole('link')

    tags.forEach((tag, index) => {
      expect(tag).toHaveTextContent(testTags[index])
    })
  })

  it('supports empty state', () => {
    const view = renderTicketTags({
      ticket: createDummyTicket(),
    })

    expect(view.queryByRole('link')).not.toBeInTheDocument()
    expect(view.getByText('No tags added yet.')).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Add tag' })).toBeInTheDocument()
  })

  it('supports readonly mode', () => {
    const view = renderTicketTags({
      isTicketEditable: false,
    })

    const tags = view.getAllByRole('link')

    tags.forEach((tag, index) => {
      expect(tag).toHaveTextContent(testTags[index])
    })

    expect(
      view.queryByRole('button', { name: 'Remove this tag' }),
    ).not.toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Add tag' }),
    ).not.toBeInTheDocument()
  })

  it('supports adding new tags', async () => {
    const view = renderTicketTags()

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: testOptions,
    })

    await view.events.click(view.getByRole('button', { name: 'Add tag' }))

    await waitForAutocompleteSearchTagQueryCalls()

    expect(
      view.queryByRole('button', { name: 'Add tag' }),
    ).not.toBeInTheDocument()

    const autocomplete = await view.findByLabelText('Add tag')

    expect(within(autocomplete).getByRole('searchbox')).toHaveFocus()

    mockTagAssignmentAddMutation({
      tagAssignmentAdd: {
        success: true,
        errors: null,
      },
    })

    await view.events.click(view.getByRole('option', { name: 'tag 4' }))

    const calls = await waitForTagAssignmentAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      objectId: testTicket.id,
      tag: 'tag 4',
    })

    expect(autocomplete).not.toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Add tag' })).toBeInTheDocument()

    const { notify } = useNotifications()

    expect(notify).toHaveBeenCalledWith({
      id: 'ticket-tag-added-successfully',
      message: 'Ticket tag added successfully.',
      type: NotificationTypes.Success,
    })
  })

  it('supports creating new tags when adding', async () => {
    mockApplicationConfig({
      tag_new: true,
    })

    const view = renderTicketTags()

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [],
    })

    await view.events.click(view.getByRole('button', { name: 'Add tag' }))

    await waitForAutocompleteSearchTagQueryCalls()

    vi.useFakeTimers()

    await view.events.type(view.getByRole('searchbox'), 'tag new')

    await vi.runAllTimersAsync()
    vi.useRealTimers()

    mockTagAssignmentAddMutation({
      tagAssignmentAdd: {
        success: true,
        errors: null,
      },
    })

    await view.events.click(view.getByRole('button', { name: 'add new tag' }))

    const calls = await waitForTagAssignmentAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      objectId: testTicket.id,
      tag: 'tag new',
    })
  })

  it('supports excluding existing tags', async () => {
    const view = renderTicketTags()

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [],
    })

    await view.events.click(view.getByRole('button', { name: 'Add tag' }))

    const calls = await waitForAutocompleteSearchTagQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        exceptTags: testTags,
      }),
    })
  })

  it('supports removing existing tags', async () => {
    const view = renderTicketTags()

    const removeButtons = view.getAllByRole('button', {
      name: 'Remove this tag',
    })

    mockTagAssignmentRemoveMutation({
      tagAssignmentRemove: {
        success: true,
        errors: null,
      },
    })

    await view.events.click(removeButtons[2])

    const calls = await waitForTagAssignmentRemoveMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      objectId: testTicket.id,
      tag: 'tag 3',
    })

    const { notify } = useNotifications()

    expect(notify).toHaveBeenCalledWith({
      id: 'ticket-tag-removed-successfully',
      message: 'Ticket tag removed successfully.',
      type: NotificationTypes.Success,
    })
  })

  it('supports truncating list of tags', async () => {
    const view = renderTicketTags({
      ticket: createDummyTicket({
        tags: ['tag 1', 'tag 2', 'tag 3', 'tag 4', 'tag 5', 'tag 6'],
      }),
    })

    expect(view.queryByRole('link', { name: 'tag 6' })).not.toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Show 1 more' }))

    expect(view.getByRole('link', { name: 'tag 6' })).toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Show 1 more' }),
    ).not.toBeInTheDocument()
  })
})
