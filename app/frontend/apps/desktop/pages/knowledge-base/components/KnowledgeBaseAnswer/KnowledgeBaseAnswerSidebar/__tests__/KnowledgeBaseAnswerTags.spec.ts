// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

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
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerTags from '../KnowledgeBaseAnswerTags.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../../types.ts'

const answer = (tags: string[] | null): KnowledgeBaseAnswerHeader =>
  ({
    __typename: 'KnowledgeBaseAnswer',
    id: convertToGraphQLId('KnowledgeBase::Answer', 1),
    title: 'Some Answer',
    visibility: EnumKnowledgeBaseVisibility.Published,
    visibilitySchedules: [],
    translationId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
    translationMissing: false,
    internalAt: null,
    publishedAt: null,
    archivedAt: null,
    editedAt: null,
    editedBy: null,
    navigation: null,
    content: {
      __typename: 'KnowledgeBaseAnswerTranslationContent',
      bodyWithUrls: 'Et non omnis. Iste rerum ut. Reiciendis officia cumque.',
      id: convertToGraphQLId('KnowledgeBase::AnswerTranslationContent', 1),
    },
    category: {
      __typename: 'KnowledgeBaseCategory',
      id: convertToGraphQLId('KnowledgeBase::Category', 1),
      breadcrumb: [],
    },
    tags,
    attachments: [],
    policy: { __typename: 'PolicyDefault', update: true, destroy: true },
  }) as KnowledgeBaseAnswerHeader

// `form: true` for the FormKit plugin: the "add tag" field below is a FormKit one, and Vue resolves
//   every component a template names regardless of the `v-if` that guards it.
const renderTags = (tags: string[] | null, editable = false) =>
  renderComponent(KnowledgeBaseAnswerTags, {
    props: { answer: answer(tags), editable },
    store: true,
    router: true,
    form: true,
  })

describe('KnowledgeBaseAnswerTags', () => {
  it('lists every tag of the answer', () => {
    const view = renderTags(['vip', 'billing', 'second level'])

    expect(view.getAllByRole('listitem')).toHaveLength(3)
    expect(view.getByText('vip')).toBeInTheDocument()
    expect(view.getByText('billing')).toBeInTheDocument()
    expect(view.getByText('second level')).toBeInTheDocument()
  })

  it('states that no tags are assigned yet', () => {
    const view = renderTags([])

    expect(view.getByText('No tags added yet.')).toBeInTheDocument()
    expect(view.queryByRole('list')).not.toBeInTheDocument()
  })

  // The field is nullable in the query, so an absent list must not differ from
  //   an empty one.
  it('treats a missing tag list like an empty one', () => {
    const view = renderTags(null)

    expect(view.getByText('No tags added yet.')).toBeInTheDocument()
  })

  it.each([
    ['with tags', ['vip']],
    ['without tags', []],
  ])('keeps the attribute label %s', (_, tags) => {
    const view = renderTags(tags as string[])

    expect(view.getByText('Tags')).toBeInTheDocument()
  })

  // The reader's sidebar shows the same section, so nothing may be editable unless asked for.
  describe('when it is not editable', () => {
    it('offers no way to add or remove a tag', () => {
      const view = renderTags(['vip'])

      expect(view.queryByRole('button', { name: 'Add tag' })).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Remove this tag' })).not.toBeInTheDocument()
    })
  })

  // Written straight onto the answer, the moment the editor clicks - not submitted with the edit
  //   form, the same as the ticket detail view's own tag section.
  describe('when it is editable', () => {
    it('removes a tag right away', async () => {
      mockTagAssignmentRemoveMutation({ tagAssignmentRemove: { success: true } })

      const view = renderTags(['vip', 'billing'], true)

      await view.events.click(view.getAllByRole('button', { name: 'Remove this tag' })[0])

      const calls = await waitForTagAssignmentRemoveMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        objectId: convertToGraphQLId('KnowledgeBase::Answer', 1),
        tag: 'vip',
      })

      const { notify } = useNotifications()

      expect(notify).toHaveBeenCalledWith({
        id: 'knowledge-base-answer-tag-removed',
        message: 'Tag removed successfully.',
        type: NotificationTypes.Success,
      })
    })

    it('adds a picked tag right away', async () => {
      mockAutocompleteSearchTagQuery({
        autocompleteSearchTag: [
          { __typename: 'AutocompleteSearchEntry', value: 'billing', label: 'billing' },
        ],
      })

      const view = renderTags(['vip'], true)

      await view.events.click(view.getByRole('button', { name: 'Add tag' }))
      await waitForAutocompleteSearchTagQueryCalls()

      mockTagAssignmentAddMutation({ tagAssignmentAdd: { success: true, errors: null } })

      await view.events.click(view.getByRole('option', { name: 'billing' }))

      const calls = await waitForTagAssignmentAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        objectId: convertToGraphQLId('KnowledgeBase::Answer', 1),
        tag: 'billing',
      })

      const { notify } = useNotifications()

      expect(notify).toHaveBeenCalledWith({
        id: 'knowledge-base-answer-tag-added',
        message: 'Tag added successfully.',
        type: NotificationTypes.Success,
      })
    })
  })
})
