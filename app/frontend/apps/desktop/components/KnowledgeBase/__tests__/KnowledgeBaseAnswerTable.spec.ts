// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslation,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'

import KnowledgeBaseAnswerTable from '../KnowledgeBaseAnswerTable.vue'

mockRouterHooks()

// The row link resolves the named answer route, so the test router has to know it. The catch-all
//   stands in for the public help site, where an answer goes when the user cannot browse in-app.
const routerRoutes = [
  { path: '/', name: 'Dashboard', component: { template: '<div />' } },
  {
    path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId',
    name: 'KnowledgeBaseAnswer',
    component: { template: '<div />' },
  },
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: '<div />' } },
]

const tableHeaders = ['title', 'updated_at', 'visibility']

// The shape the detailed search selects, not the full type — `detailSearch.graphql` asks for these
//   fields alone, so a complete record would test something the component never receives.
const tableItems = [
  {
    __typename: 'KnowledgeBaseAnswerTranslation',
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 7),
    title: 'Ocarina tuning guide',
    updatedAt: '2025-02-20T10:21:14Z',
    visibility: EnumKnowledgeBaseVisibility.Published,
    answer: {
      __typename: 'KnowledgeBaseAnswer',
      id: convertToGraphQLId('KnowledgeBase::Answer', 42),
      category: {
        __typename: 'KnowledgeBaseCategory',
        id: convertToGraphQLId('KnowledgeBase::Category', 3),
      },
    },
    kbLocale: {
      __typename: 'KnowledgeBaseLocale',
      systemLocale: { __typename: 'Locale', locale: 'en-us' },
    },
  },
] as KnowledgeBaseAnswerTranslation[]

const renderListTable = async (props: Partial<ListTableProps<KnowledgeBaseAnswerTranslation>>) => {
  const wrapper = renderComponent(KnowledgeBaseAnswerTable, {
    router: true,
    routerRoutes,
    form: true,
    props: {
      headers: tableHeaders,
      items: tableItems,
      totalCount: 1,
      caption: 'Search result for: Knowledge base answer',
      tableId: 'search-knowledge-base-answer-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

describe('KnowledgeBaseAnswerTable', () => {
  beforeEach(() => {
    mockPermissions(['knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })
  })

  it('renders the three columns the story asks for', async () => {
    const wrapper = await renderListTable({})

    expect(wrapper.getByRole('columnheader', { name: 'Name' })).toBeInTheDocument()
    expect(wrapper.getByRole('columnheader', { name: 'Updated at' })).toBeInTheDocument()
    expect(wrapper.getByRole('columnheader', { name: 'Visibility' })).toBeInTheDocument()
  })

  it('renders the answer title and its visibility', async () => {
    const wrapper = await renderListTable({})

    expect(wrapper.getByText('Ocarina tuning guide')).toBeInTheDocument()
    expect(wrapper.getAllByText('Published').length).toBeGreaterThan(0)
  })

  // The locale comes from the row, not from the session: a result may be in a locale other than
  //   the user's own, and the answer route needs both it and the answer's internal id. The
  //   `/desktop` prefix is the app's mount point, which CommonLink puts back on.
  it('links a row to the answer in its own locale', async () => {
    const wrapper = await renderListTable({})

    expect(wrapper.getByRole('link', { name: 'Ocarina tuning guide' })).toHaveAttribute(
      'href',
      '/desktop/knowledge-base/locale/en-us/answer/42',
    )
  })

  // No columns are sortable: the knowledge base backend ranks by relevance and the search query
  //   ignores `orderBy` for this entity, so a sort control would do nothing.
  it('offers no sorting on any column', async () => {
    const wrapper = await renderListTable({})

    expect(wrapper.queryAllByRole('button', { name: /^Sort by/ })).toHaveLength(0)
  })

  it('renders the empty-list slot when there are no answers', async () => {
    const wrapper = await renderListTable({ items: [], totalCount: 0 })

    expect(wrapper.queryByRole('table')).not.toBeInTheDocument()
  })
})
