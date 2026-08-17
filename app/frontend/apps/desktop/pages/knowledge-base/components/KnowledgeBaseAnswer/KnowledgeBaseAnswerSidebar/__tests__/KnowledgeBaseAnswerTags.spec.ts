// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

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
  }) as KnowledgeBaseAnswerHeader

const renderTags = (tags: string[] | null) =>
  renderComponent(KnowledgeBaseAnswerTags, {
    props: { answer: answer(tags) },
    store: true,
    router: true,
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
})
