// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForKnowledgeBaseUpdateMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseUpdate.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const KNOWLEDGE_BASE_ID = convertToGraphQLId('KnowledgeBase', 1)
const KB_LOCALE_ID = convertToGraphQLId('KnowledgeBase::Locale', 1)

describe('knowledge base edit knowledge base', () => {
  beforeEach(() => {
    mockPermissions(['knowledge_base.editor'])
    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: KNOWLEDGE_BASE_ID,
        title: 'My Knowledge Base',
        footerNote: 'Footer',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        policy: { update: true },
        kbLocales: [
          {
            id: KB_LOCALE_ID,
            primary: true,
            systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
          },
        ],
        currentLocale: {
          id: KB_LOCALE_ID,
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: null,
        subcategories: [],
      },
    })

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {},
      },
    })
  })

  it('opens from the root header, saves and closes the flyout', async () => {
    const view = await visitView('/knowledge-base')

    const header = within(await view.findByTestId('knowledge-base-header-full'))

    await view.events.click(header.getByRole('button', { name: 'Additional actions' }))
    await view.events.click(await view.findByText('Edit knowledge base'))

    expect(
      await view.findByRole('heading', { level: 2, name: 'Edit knowledge base' }),
    ).toBeInTheDocument()

    const title = await view.findByLabelText('Title')
    await view.events.clear(title)
    await view.events.type(title, 'Help Center')

    await view.events.click(view.getByRole('button', { name: 'Update' }))

    const calls = await waitForKnowledgeBaseUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      input: {
        title: 'Help Center',
        footerNote: 'Footer',
      },
      locale: 'en-us',
    })

    await waitFor(() => {
      expect(
        view.queryByRole('heading', { level: 2, name: 'Edit knowledge base' }),
      ).not.toBeInTheDocument()
    })
  })
})
