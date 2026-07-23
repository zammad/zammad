// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { merge } from 'lodash-es'

import renderComponent from '#tests/support/components/renderComponent.ts'

import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslationFragment,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import TicketKnowledgeBaseAnswerPopover from '../TicketKnowledgeBaseAnswerPopover.vue'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 42)
const LOCALE = 'en-gb'

const buildTranslation = (
  overrides: DeepPartial<KnowledgeBaseAnswerTranslationFragment> = {},
): KnowledgeBaseAnswerTranslationFragment =>
  merge(
    {
      __typename: 'KnowledgeBaseAnswerTranslation',
      id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
      title: 'Reset your password',
      visibility: EnumKnowledgeBaseVisibility.Published,
      content: {
        __typename: 'KnowledgeBaseAnswerTranslationContent',
        bodyExcerpt: 'Steps to reset your password.',
      },
      answer: {
        __typename: 'KnowledgeBaseAnswer',
        id: convertToGraphQLId('KnowledgeBase::Answer', 1),
        archivedAt: null,
        publishedAt: '2024-01-01T00:00:00Z',
        category: {
          __typename: 'KnowledgeBaseCategory',
          id: CATEGORY_ID,
          title: 'Account',
          knowledgeBase: {
            __typename: 'KnowledgeBase',
            id: convertToGraphQLId('KnowledgeBase', 1),
          },
        },
      },
      kbLocale: {
        __typename: 'KnowledgeBaseLocale',
        systemLocale: { __typename: 'Locale', locale: LOCALE, name: 'English (GB)' },
      },
    } satisfies KnowledgeBaseAnswerTranslationFragment,
    overrides,
  )

const renderPopover = (translation = buildTranslation()) =>
  renderComponent(TicketKnowledgeBaseAnswerPopover, {
    props: { translation },
    router: true,
    routerRoutes: [
      { path: '/', name: 'Root', component: { template: '<div />' } },
      {
        path: '/knowledge-base/:localeCode/category/:categoryInternalId',
        name: 'KnowledgeBaseCategory',
        component: { template: '<div />' },
      },
    ],
    store: true,
  })

describe('TicketKnowledgeBaseAnswerPopover', () => {
  it('shows the answer title and its content excerpt', () => {
    const wrapper = renderPopover()

    expect(wrapper.getByText('Reset your password')).toBeInTheDocument()
    expect(wrapper.getByText('Steps to reset your password.')).toBeInTheDocument()
  })

  it('links the category to its knowledge base browse route', () => {
    const wrapper = renderPopover()

    expect(wrapper.getByRole('link', { name: 'Account' })).toHaveAttribute(
      'href',
      expect.stringContaining(
        `/knowledge-base/${LOCALE}/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
      ),
    )
  })

  it('shows the language of the answer', () => {
    const wrapper = renderPopover()

    expect(wrapper.getByText('Language')).toBeInTheDocument()
    expect(wrapper.getByText('English (GB)')).toBeInTheDocument()
  })

  it('shows the published date and hides the archived row when the answer is not archived', () => {
    const wrapper = renderPopover()

    expect(wrapper.getByText('Published at')).toBeInTheDocument()
    expect(wrapper.queryByText('Archived at')).not.toBeInTheDocument()
  })

  it('shows the archived date when the answer is archived', () => {
    const wrapper = renderPopover(
      buildTranslation({ answer: { archivedAt: '2024-06-01T00:00:00Z' } }),
    )

    expect(wrapper.getByText('Archived at')).toBeInTheDocument()
  })

  it('hides the category row when the category has no title in the requested locale', () => {
    const wrapper = renderPopover(buildTranslation({ answer: { category: { title: null } } }))

    expect(wrapper.queryByText('Category')).not.toBeInTheDocument()
  })
})
