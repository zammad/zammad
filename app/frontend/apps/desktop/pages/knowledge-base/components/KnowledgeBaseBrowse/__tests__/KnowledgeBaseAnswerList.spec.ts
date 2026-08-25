// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerList from '../KnowledgeBaseAnswerList.vue'

describe('KnowledgeBaseAnswerList', () => {
  // The page keys this list by the category and the locale it shows, so switching either remounts
  //   it - and the page holds on to the visibility flag of the previous list meanwhile. Reporting
  //   at mount is what clears a stale `true`, which would otherwise cost the toolbar its
  //   add-answer shortcut until the new card scrolls into view.
  it('reports the state of its add card when it mounts', async () => {
    const view = renderComponent(KnowledgeBaseAnswerList, {
      router: true,
      props: {
        categoryId: convertToGraphQLId('KnowledgeBase::Category', 1),
        locale: 'en-us',
        canAddAnswer: true,
        // What the previously browsed category left behind.
        addAnswerCardVisible: true,
      },
    })

    await flushPromises()

    expect(view.emitted()['update:addAnswerCardVisible']).toEqual([[false]])
  })
})
