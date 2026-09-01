// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls, mockedApolloClient } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import type { KnowledgeBaseAnswerQuery, KnowledgeBaseAnswersQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { KnowledgeBaseAnswerDeleteDocument } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerDelete.api.ts'
import {
  mockKnowledgeBaseAnswerDeleteMutation,
  mockKnowledgeBaseAnswerDeleteMutationError,
  waitForKnowledgeBaseAnswerDeleteMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerDelete.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import {
  mockKnowledgeBaseAnswerQuery,
  mockKnowledgeBaseAnswerQueryError,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import { KnowledgeBaseAnswersDocument } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.api.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import { getKnowledgeBaseContentUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseContentUpdates.mocks.ts'

const KNOWLEDGE_BASE_ID = convertToGraphQLId('KnowledgeBase', 1)
const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 5)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)
const SIBLING_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 3)

const ANSWER_TITLE = 'Some Knowledge Base Answer'

const ANSWER_PATH: `/${string}` = `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(ANSWER_ID)}`
const CATEGORY_PATH: `/${string}` = `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`

const mockAnswer = (policy: { update: boolean; destroy: boolean }) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      title: ANSWER_TITLE,
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
      policy: { __typename: 'PolicyDefault', ...policy },
      category: {
        id: CATEGORY_ID,
        breadcrumb: [
          {
            id: CATEGORY_ID,
            title: 'Child Category',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
        ],
      },
    },
  } as KnowledgeBaseAnswerQuery)

describe('knowledge base delete answer', () => {
  let listedAnswers: { node: { id: string; title: string; position: number } }[]

  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })
    mockPermissions(['knowledge_base.editor'])

    listedAnswers = [{ node: { id: ANSWER_ID, title: ANSWER_TITLE, position: 1 } }]

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: KNOWLEDGE_BASE_ID,
        title: 'My Knowledge Base',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        // Pinned rather than left to the automocker: it decides whether the header menu holds a
        //   feed entry besides the ones under test.
        showFeedIcon: false,
        kbLocales: [
          {
            id: convertToGraphQLId('KnowledgeBase::Locale', 1),
            primary: true,
            systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
          },
        ],
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseAnswersQuery(() => ({
      knowledgeBaseAnswers: {
        totalCount: listedAnswers.length,
        edges: listedAnswers,
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    }))
  })

  // Asked of the open category once for the whole list, so this gates every card's delete entry.
  const mockCategory = (destroyAnswer: boolean) => {
    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: {
          id: CATEGORY_ID,
          breadcrumb: [{ id: CATEGORY_ID, title: 'Child Category', categoryIcon: 'folder' }],
          policy: {
            __typename: 'PolicyKnowledgeBaseCategory',
            update: true,
            destroy: true,
            createSubcategory: true,
            createAnswer: true,
            updateAnswer: true,
            destroyAnswer,
          },
        },
        subcategories: [],
      },
    })
  }

  // The backend from the delete onwards: the answer is gone from the listing, and asking for the
  //   record again is answered with a not-found - which the reader turns into the error page.
  const mockSuccessfulDelete = () =>
    mockKnowledgeBaseAnswerDeleteMutation(() => {
      listedAnswers = []

      mockKnowledgeBaseAnswerQueryError('Record not found', {
        type: GraphQLErrorTypes.RecordNotFound,
      })

      return { knowledgeBaseAnswerDelete: { success: true, errors: null } }
    })

  const triggerContentUpdate = () =>
    getKnowledgeBaseContentUpdatesSubscriptionHandler().trigger({
      knowledgeBaseContentUpdates: {
        knowledgeBase: { id: KNOWLEDGE_BASE_ID },
        affectedCategoryIds: [CATEGORY_ID],
      },
    })

  const confirmDeletion = async (view: Awaited<ReturnType<typeof visitView>>) => {
    await view.events.click(
      within(await view.findByRole('dialog')).getByRole('button', { name: 'Delete object' }),
    )
  }

  describe('from the answer view', () => {
    const openHeaderMenu = async (view: Awaited<ReturnType<typeof visitView>>) => {
      // Awaited through something else the header renders, so the menu is looked for on a
      //   settled view rather than on one that has not got there yet.
      await view.findAllByText('Published')

      const header = view.getByTestId('knowledge-base-header-full')

      await view.events.click(within(header).getByRole('button', { name: 'Additional actions' }))

      return within(await view.findByRole('menu'))
    }

    it('deletes the opened answer after confirmation and navigates to its category', async () => {
      mockAnswer({ update: true, destroy: true })
      mockCategory(true)

      const view = await visitView(ANSWER_PATH)

      mockSuccessfulDelete()

      const menu = await openHeaderMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      expect(
        await view.findByText(`Do you really want to delete "${ANSWER_TITLE}"?`),
      ).toBeInTheDocument()

      await confirmDeletion(view)

      const calls = await waitForKnowledgeBaseAnswerDeleteMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({ answerId: ANSWER_ID })

      expect(
        await view.findByText('Knowledge base answer deleted successfully.'),
      ).toBeInTheDocument()

      // Whoever still watches the answer refetches on this and lands on the error page, so by
      //   now the reader must have left it behind.
      await triggerContentUpdate()

      await waitFor(() => {
        expect(view).toHaveCurrentUrl(CATEGORY_PATH)
      })
    })

    it('sends nothing when the confirmation is cancelled', async () => {
      mockAnswer({ update: true, destroy: true })

      const view = await visitView(ANSWER_PATH)

      const menu = await openHeaderMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      await view.events.click(
        within(await view.findByRole('dialog')).getByRole('button', { name: 'Cancel & go back' }),
      )

      await waitFor(() => {
        expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      })

      expect(getGraphQLMockCalls(KnowledgeBaseAnswerDeleteDocument)).toHaveLength(0)
    })

    // The view is left *before* the delete is sent, so a failure cannot be undone by staying put -
    //   which makes the notification the only thing telling the two apart. The handler raises the
    //   backend's message; what must not follow it is the success one, claiming an answer is gone
    //   that is still there.
    it('claims no success when the delete fails', async () => {
      mockAnswer({ update: true, destroy: true })
      mockCategory(true)

      const view = await visitView(ANSWER_PATH)

      mockKnowledgeBaseAnswerDeleteMutationError('Not authorized', {
        type: GraphQLErrorTypes.Forbidden,
      })

      const menu = await openHeaderMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      await confirmDeletion(view)

      await waitForKnowledgeBaseAnswerDeleteMutationCalls()

      expect(await view.findByText('Not authorized')).toBeInTheDocument()

      expect(
        view.queryByText('Knowledge base answer deleted successfully.'),
      ).not.toBeInTheDocument()
    })

    // The answer's own page of the listing may never have been loaded: there is no edge to drop
    //   from it, but the count still has to come down with the answer.
    it('lowers the cached listing count for an answer outside the loaded page', async () => {
      // Two answers in the category, the first page holding the other one: the deleted answer sits
      //   on the page that follows, which was never fetched. Left that way on purpose - the count
      //   may only drop because the cached listing was edited in place.
      mockKnowledgeBaseAnswersQuery({
        knowledgeBaseAnswers: {
          totalCount: 2,
          edges: [
            {
              node: {
                id: convertToGraphQLId('KnowledgeBase::Answer', 6),
                title: 'Another Knowledge Base Answer',
                position: 1,
              },
            },
          ],
          pageInfo: { endCursor: 'next-page', hasNextPage: true },
        },
      })

      mockAnswer({ update: true, destroy: true })
      mockCategory(true)

      // Through the category first, so its listing is in the cache when the answer is deleted.
      const view = await visitView(CATEGORY_PATH)
      expect(await view.findByText('Another Knowledge Base Answer')).toBeInTheDocument()

      // Another category's listing, cached alongside it: it never counted this answer, so its own
      //   count has to survive the delete untouched.
      mockedApolloClient.cache.writeQuery({
        query: KnowledgeBaseAnswersDocument,
        variables: { categoryId: SIBLING_CATEGORY_ID, locale: 'en-us', pageSize: 30 },
        data: {
          knowledgeBaseAnswers: {
            __typename: 'KnowledgeBaseAnswerConnection',
            totalCount: 4,
            edges: [],
            pageInfo: { __typename: 'PageInfo', endCursor: null, hasNextPage: false },
          },
        },
      })

      await view.router.push(ANSWER_PATH)

      mockSuccessfulDelete()

      const menu = await openHeaderMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      await confirmDeletion(view)

      await waitForKnowledgeBaseAnswerDeleteMutationCalls()

      const cachedCount = (categoryId: string) =>
        mockedApolloClient.cache.readQuery<KnowledgeBaseAnswersQuery>({
          query: KnowledgeBaseAnswersDocument,
          variables: { categoryId, locale: 'en-us', pageSize: 30 },
        })?.knowledgeBaseAnswers.totalCount

      await waitFor(() => {
        expect(cachedCount(CATEGORY_ID)).toBe(1)
      })

      expect(cachedCount(SIBLING_CATEGORY_ID)).toBe(4)
    })

    it('does not offer deleting an answer the user may not destroy', async () => {
      // With the edit entry on, so there is still a menu to look into.
      mockAnswer({ update: true, destroy: false })

      const view = await visitView(ANSWER_PATH)

      const menu = await openHeaderMenu(view)

      expect(menu.getByRole('button', { name: 'Edit answer' })).toBeInTheDocument()
      expect(menu.queryByRole('button', { name: 'Delete answer' })).not.toBeInTheDocument()
    })
  })

  describe('from an answer card', () => {
    const openCardMenu = async (view: Awaited<ReturnType<typeof visitView>>) => {
      await view.events.click(await view.findByRole('button', { name: 'Answer actions' }))

      return within(await view.findByRole('menu'))
    }

    it('deletes the answer after confirmation, drops its card and stays put', async () => {
      mockCategory(true)

      const view = await visitView(CATEGORY_PATH)

      mockSuccessfulDelete()

      const menu = await openCardMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      await confirmDeletion(view)

      const calls = await waitForKnowledgeBaseAnswerDeleteMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({ answerId: ANSWER_ID })

      expect(
        await view.findByText('Knowledge base answer deleted successfully.'),
      ).toBeInTheDocument()

      expect(view).toHaveCurrentUrl(CATEGORY_PATH)

      await waitFor(() => {
        expect(view.queryByText(ANSWER_TITLE)).not.toBeInTheDocument()
      })
    })

    // Refetching it would collapse a listing scrolled several pages deep back to its first page,
    //   throwing the reader to the top of the category over a card they just removed from it.
    it('drops the card from the cached listing instead of refetching it', async () => {
      mockCategory(true)

      const view = await visitView(CATEGORY_PATH)

      // Unlike `mockSuccessfulDelete`, this leaves the answer in the listing the server would
      //   serve: the card may only go because the cached listing was edited in place, and it
      //   comes back if anything asks for the listing again.
      mockKnowledgeBaseAnswerDeleteMutation({
        knowledgeBaseAnswerDelete: { success: true, errors: null },
      })

      const menu = await openCardMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      await confirmDeletion(view)

      await waitFor(() => {
        expect(view.queryByText(ANSWER_TITLE)).not.toBeInTheDocument()
      })

      // Still just the one the page opened with.
      expect(getGraphQLMockCalls(KnowledgeBaseAnswersDocument)).toHaveLength(1)
    })

    // The card hands its own category over for this: the listing is cached per category *and*
    //   locale, so the same category browsed in another locale is a second entry - and one whose
    //   loaded window need never have held the answer, leaving nothing but the count to correct.
    it('lowers the cached count of the same category in another locale', async () => {
      mockCategory(true)

      const view = await visitView(CATEGORY_PATH)
      expect(await view.findByText(ANSWER_TITLE)).toBeInTheDocument()

      const otherListing = (categoryId: string, locale: string, totalCount: number) =>
        mockedApolloClient.cache.writeQuery({
          query: KnowledgeBaseAnswersDocument,
          variables: { categoryId, locale, pageSize: 30 },
          data: {
            knowledgeBaseAnswers: {
              __typename: 'KnowledgeBaseAnswerConnection',
              totalCount,
              // Never loaded this far, so there is no edge to drop - only the count may move.
              edges: [],
              pageInfo: { __typename: 'PageInfo', endCursor: null, hasNextPage: false },
            },
          },
        })

      otherListing(CATEGORY_ID, 'de-de', 4)
      // A different category, cached alongside it: it never counted this answer, so it must not move.
      otherListing(SIBLING_CATEGORY_ID, 'de-de', 4)

      mockSuccessfulDelete()

      const menu = await openCardMenu(view)
      await view.events.click(menu.getByRole('button', { name: 'Delete answer' }))

      await confirmDeletion(view)

      await waitForKnowledgeBaseAnswerDeleteMutationCalls()

      const cachedCount = (categoryId: string) =>
        mockedApolloClient.cache.readQuery<KnowledgeBaseAnswersQuery>({
          query: KnowledgeBaseAnswersDocument,
          variables: { categoryId, locale: 'de-de', pageSize: 30 },
        })?.knowledgeBaseAnswers.totalCount

      await waitFor(() => {
        expect(cachedCount(CATEGORY_ID)).toBe(3)
      })

      expect(cachedCount(SIBLING_CATEGORY_ID)).toBe(4)
    })

    it('does not offer deleting when the category grants no destroyAnswer', async () => {
      // With `updateAnswer` on, so the card still has a menu to look into.
      mockCategory(false)

      const view = await visitView(CATEGORY_PATH)

      const menu = await openCardMenu(view)

      expect(menu.getByRole('button', { name: 'Edit answer' })).toBeInTheDocument()
      expect(menu.queryByRole('button', { name: 'Delete answer' })).not.toBeInTheDocument()
    })
  })
})
