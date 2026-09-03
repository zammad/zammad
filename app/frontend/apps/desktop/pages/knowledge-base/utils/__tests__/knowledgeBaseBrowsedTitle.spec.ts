// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { knowledgeBaseBrowsedTitle } from '../knowledgeBaseBrowsedTitle.ts'

import type { CategoryBreadcrumb } from '../../types.ts'

const categoryBreadcrumb: CategoryBreadcrumb = [
  {
    id: convertToGraphQLId('KnowledgeBase::Category', 1),
    translation: { title: 'Root Category' },
    categoryIcon: 'f115',
    iconSet: 'FontAwesome',
    visibility: EnumKnowledgeBaseVisibility.Published,
  },
  {
    id: convertToGraphQLId('KnowledgeBase::Category', 2),
    translation: { title: 'Child Category' },
    categoryIcon: 'f114',
    iconSet: 'FontAwesome',
    visibility: EnumKnowledgeBaseVisibility.Internal,
  },
]

describe('knowledgeBaseBrowsedTitle', () => {
  it('names the opened category, the last of the breadcrumb', () => {
    expect(
      knowledgeBaseBrowsedTitle({ categoryBreadcrumb, knowledgeBaseTitle: 'My Knowledge Base' }),
    ).toBe('Child Category')
  })

  it('names the knowledge base at the root', () => {
    expect(knowledgeBaseBrowsedTitle({ knowledgeBaseTitle: 'My Knowledge Base' })).toBe(
      'My Knowledge Base',
    )
  })

  it('names the knowledge base while its title is still unknown', () => {
    expect(knowledgeBaseBrowsedTitle({})).toBe('Knowledge Base')
  })
})
