// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'

import KnowledgeBaseAnswerList from '../KnowledgeBaseAnswerList.vue'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

// One page of answers, with or without a further one behind it.
const mockAnswers = (hasNextPage: boolean) =>
  mockKnowledgeBaseAnswersQuery({
    knowledgeBaseAnswers: {
      totalCount: hasNextPage ? 60 : 1,
      edges: [
        {
          node: {
            id: convertToGraphQLId('KnowledgeBase::Answer', 1),
            visibility: EnumKnowledgeBaseVisibility.Published,
            position: 1,
            translation: {
              id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
              title: 'Answer One',
            },
          },
        },
      ],
      pageInfo: { endCursor: hasNextPage ? 'CURSOR' : null, hasNextPage },
    },
  })

const renderList = () =>
  renderComponent(KnowledgeBaseAnswerList, {
    router: true,
    props: {
      categoryId: CATEGORY_ID,
      locale: 'en-us',
      canAddAnswer: true,
    },
  })

describe('KnowledgeBaseAnswerList', () => {
  // The page keys this list by the category and the locale it shows, so switching either remounts
  //   it - and the page holds on to the visibility flag of the previous list meanwhile. Reporting
  //   at mount is what clears a stale `true`, which would otherwise cost the toolbar its
  //   add-answer shortcut until the new card scrolls into view.
  it('reports the state of its add card when it mounts', async () => {
    const view = renderComponent(KnowledgeBaseAnswerList, {
      router: true,
      props: {
        categoryId: CATEGORY_ID,
        locale: 'en-us',
        canAddAnswer: true,
        // What the previously browsed category left behind.
        addAnswerCardVisible: true,
      },
    })

    await flushPromises()

    expect(view.emitted()['update:addAnswerCardVisible']).toEqual([[false]])
  })

  // The card closes the list, so it must not show up between the answers and the skeletons of the
  //   page being fetched - there it reads as the end of a list that then keeps growing.
  it('hides its add card while further pages are still to come', async () => {
    mockAnswers(true)

    const view = renderList()

    expect(await view.findByText('Answer One')).toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Add answer' })).not.toBeInTheDocument()
  })

  it('shows its add card once the whole list is loaded', async () => {
    mockAnswers(false)

    const view = renderList()

    expect(await view.findByText('Answer One')).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Add answer' })).toBeInTheDocument()
  })
})
