// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import createCache from '#shared/server/apollo/cache.ts'

import { KnowledgeBaseCategorySubcategoriesDocument } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.api.ts'

// A category is one record for every locale, and two different things resolve from one: its name,
//   which is its translation's own (a record per locale, so the cache keeps them apart by id), and
//   the state and counts of its content, which stay on the category and are therefore kept apart
//   by their `locale` argument (Gql::Types::KnowledgeBase::CategoryType). Without either half the
//   grid would show one locale the data of whichever was fetched last.
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 7)

const data = (
  internalId: number,
  localeCode: string,
  title: string,
  visibility: string,
  answerCount: number,
) => ({
  knowledgeBaseCategorySubcategories: {
    __typename: 'KnowledgeBaseCategorySubcategoriesPayload',
    category: null,
    subcategories: [
      {
        __typename: 'KnowledgeBaseCategory',
        id: CATEGORY_ID,
        translation: {
          __typename: 'KnowledgeBaseCategoryTranslation',
          id: convertToGraphQLId('KnowledgeBase::Category::Translation', internalId),
          title,
          kbLocale: {
            __typename: 'KnowledgeBaseLocale',
            id: convertToGraphQLId('KnowledgeBase::Locale', internalId),
            systemLocale: { __typename: 'Locale', locale: localeCode },
          },
        },
        visibility,
        answerCount,
        subcategoryCount: 0,
        categoryIcon: 'folder',
        position: 0,
        isDeletable: true,
        directSubcategoryCount: 0,
        breadcrumb: [],
        policy: {
          __typename: 'PolicyDefault',
          update: true,
          destroy: true,
          createSubcategory: true,
          createAnswer: true,
          updateAnswer: true,
          permissions: [],
        },
      },
    ],
  },
})

describe('a category read in two locales', () => {
  it('keeps the name, the state and the counts of each locale', () => {
    const cache = createCache()

    cache.writeQuery({
      query: KnowledgeBaseCategorySubcategoriesDocument,
      variables: { categoryId: null, locale: 'en-us' },
      data: data(1, 'en-us', 'Hardware', 'published', 3),
    })
    cache.writeQuery({
      query: KnowledgeBaseCategorySubcategoriesDocument,
      variables: { categoryId: null, locale: 'de-de' },
      data: data(2, 'de-de', 'Hardware DE', 'internal', 1),
    })

    const read = (locale: string) =>
      (
        cache.readQuery({
          query: KnowledgeBaseCategorySubcategoriesDocument,
          variables: { categoryId: null, locale },
          returnPartialData: true,
        }) as {
          knowledgeBaseCategorySubcategories?: {
            subcategories?: {
              translation?: { title?: string }
              visibility?: string
              answerCount?: number
            }[]
          }
        } | null
      )?.knowledgeBaseCategorySubcategories?.subcategories?.[0]

    expect(read('en-us')).toEqual(
      expect.objectContaining({
        translation: expect.objectContaining({ title: 'Hardware' }),
        visibility: 'published',
        answerCount: 3,
      }),
    )
    expect(read('de-de')).toEqual(
      expect.objectContaining({
        translation: expect.objectContaining({ title: 'Hardware DE' }),
        visibility: 'internal',
        answerCount: 1,
      }),
    )
  })
})
