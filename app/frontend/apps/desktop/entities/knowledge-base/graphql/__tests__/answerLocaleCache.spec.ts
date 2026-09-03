// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import createCache from '#shared/server/apollo/cache.ts'

import { UserCurrentTaskbarItemListDocument } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.api.ts'

// One answer with a tab per locale, which is the one place the locale cannot be an argument: a tab
//   list carries tabs of many locales and one query can pass only one value. So the tabs are kept
//   apart by what they render - the translation of their own locale, a record each (Gql::Types
//   ::User::TaskbarItemType#answer_translation) - and this is what that has to buy.
//
// The views' own case (the same answer read in two locales) is covered where a reader meets it,
//   in knowledge-base-answer-header.spec.ts.
const translationId = (internalId: number) =>
  convertToGraphQLId('KnowledgeBase::Answer::Translation', internalId)

describe('the taskbar tabs of one answer in two locales', () => {
  it('keeps a label per tab instead of one for both', () => {
    const cache = createCache()
    const variables = { app: 'desktop' }

    const item = (internalId: number, locale: string, title: string) => ({
      __typename: 'UserTaskbarItem',
      id: convertToGraphQLId('Taskbar', internalId),
      key: `KnowledgeBase__Answer-42-${locale}`,
      callback: 'KnowledgeBaseAnswerEdit',
      entityAccess: 'Granted',
      prio: internalId,
      changed: false,
      dirty: false,
      updatedAt: '2026-09-02T10:00:00Z',
      formId: null,
      formNewArticlePresent: false,
      entity: {
        __typename: 'KnowledgeBaseAnswerTranslation',
        id: translationId(internalId),
        title,
        visibility: 'published',
        kbLocale: {
          __typename: 'KnowledgeBaseLocale',
          id: convertToGraphQLId('KnowledgeBase::Locale', internalId),
          systemLocale: { __typename: 'Locale', locale },
        },
      },
    })

    cache.writeQuery({
      query: UserCurrentTaskbarItemListDocument,
      variables,
      data: {
        userCurrentTaskbarItemList: [
          item(1, 'en-us', 'English title'),
          item(2, 'de-de', 'Deutscher Titel'),
        ],
      },
    })

    // Partial, because the list selects more of an item than a label needs.
    const result = cache.readQuery({
      query: UserCurrentTaskbarItemListDocument,
      variables,
      returnPartialData: true,
    }) as { userCurrentTaskbarItemList?: { key: string; entity?: { title?: string } }[] } | null

    expect(
      result?.userCurrentTaskbarItemList?.map((entry) => [entry.key, entry.entity?.title]),
    ).toEqual([
      ['KnowledgeBase__Answer-42-en-us', 'English title'],
      ['KnowledgeBase__Answer-42-de-de', 'Deutscher Titel'],
    ])
  })
})
