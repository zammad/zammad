// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { knowledgeBaseBreadcrumbItems } from '../knowledgeBaseBreadcrumbItems.ts'

import type { CategoryBreadcrumb } from '../../types.ts'

const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const categoryBreadcrumb: CategoryBreadcrumb = [
  {
    id: ROOT_CATEGORY_ID,
    translation: { title: 'Root Category' },
    categoryIcon: 'f115',
    iconSet: 'FontAwesome',
    visibility: EnumKnowledgeBaseVisibility.Published,
  },
  {
    id: CHILD_CATEGORY_ID,
    translation: { title: 'Child Category' },
    categoryIcon: 'f114',
    iconSet: 'FontAwesome',
    visibility: EnumKnowledgeBaseVisibility.Internal,
  },
]

describe('knowledgeBaseBreadcrumbItems', () => {
  it('renders only the knowledge base root, unlinked, at the root', () => {
    const items = knowledgeBaseBreadcrumbItems({ localeCode: 'en-us' })

    expect(items).toHaveLength(1)
    expect(items[0]).toMatchObject({
      label: 'Knowledge Base Home',
      icon: 'book',
      iconOnly: true,
      noOptionLabelTranslation: false,
    })
    expect(items[0].route).toBeUndefined()
  })

  it('links the root and every ancestor, leaving the opened category unlinked', () => {
    const items = knowledgeBaseBreadcrumbItems({ localeCode: 'en-us', categoryBreadcrumb })

    expect(items.map((item) => item.label)).toEqual([
      'Knowledge Base Home',
      'Root Category',
      'Child Category',
    ])
    expect(items[0].route).toBeDefined()
    expect(items[1].route).toMatchObject({
      name: 'KnowledgeBaseCategory',
      params: { localeCode: 'en-us', categoryInternalId: 1 },
    })
    expect(items.at(-1)!.route, 'the opened node is the page itself').toBeUndefined()
  })

  it('forwards the icon name and icon set for the category items', () => {
    const items = knowledgeBaseBreadcrumbItems({ localeCode: 'en-us', categoryBreadcrumb })

    expect(items[1].icon).toBe('f115')
    expect(items[1].iconSet).toBe('FontAwesome')
    expect(items[2].icon).toBe('f114')
    expect(items[2].iconSet).toBe('FontAwesome')
  })

  it('color-codes each category by its visibility', () => {
    const items = knowledgeBaseBreadcrumbItems({ localeCode: 'en-us', categoryBreadcrumb })

    expect(items[1].iconClass).toBe('text-green-400!')
    expect(items[2].iconClass).toBe('text-blue-800!')
  })

  it('links the last category too when a trailing item follows it', () => {
    const items = knowledgeBaseBreadcrumbItems({
      localeCode: 'en-us',
      categoryBreadcrumb,
      trailingItem: { label: 'Some Answer', noOptionLabelTranslation: true },
    })

    expect(items.map((item) => item.label)).toEqual([
      'Knowledge Base Home',
      'Root Category',
      'Child Category',
      'Some Answer',
    ])
    expect(items[2].route, 'the category is no longer the opened node').toMatchObject({
      name: 'KnowledgeBaseCategory',
      params: { localeCode: 'en-us', categoryInternalId: 2 },
    })
    expect(items.at(-1)!.route).toBeUndefined()
  })

  it('leaves every item unlinked without a locale', () => {
    const items = knowledgeBaseBreadcrumbItems({ categoryBreadcrumb })

    expect(items.every((item) => item.route === undefined)).toBe(true)
  })
})
