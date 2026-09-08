// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { waitFor } from '@testing-library/vue'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumKnowledgeBaseVisibility, EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockQuickSearchQuery,
  waitForQuickSearchQueryCalls,
} from '../../../graphql/queries/quickSearch.mocks.ts'
import QuickSearchResultList from '../QuickSearchResultList.vue'

// The test router is created once per file and these replace its defaults wholesale, so every
//   route any result item links to has to be here. The knowledge base answer route is what an
//   answer item resolves to for a user who may open the agent answer view; the catch-all is where
//   the public help-site path everyone else gets resolves to, as it does in the real router.
const routerRoutes = [
  { path: '/', name: 'Dashboard', component: { template: '<div />' } },
  { path: '/search/:searchTerm?', name: 'Search', component: { template: '<div />' } },
  {
    path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId',
    name: 'KnowledgeBaseAnswer',
    component: { template: '<div />' },
  },
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: '<div />' } },
]

const renderQuickSearchResultList = async (search: string) => {
  const wrapper = renderComponent(QuickSearchResultList, {
    props: {
      search,
      debounceTime: 400,
    },
    router: true,
    routerRoutes,
  })

  await waitForNextTick()

  return wrapper
}

describe('QuickSearchResultList', () => {
  it('renders by default the sections with an empty state', async () => {
    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 0,
        items: [],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('')

    expect(wrapper.queryByText('Found organizations')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found tickets')).not.toBeInTheDocument()

    expect(await wrapper.findByText('No results for this query.')).toBeInTheDocument()
  })

  it('renders the sections with the results', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 1,
        items: [
          {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 1),
            internalId: 1,
            name: 'Organization 1',
          },
        ],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User 1',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 100,
        items: [
          {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            title: 'Ticket 1',
            number: '1',
            state: {
              __typename: 'TicketState',
              id: convertToGraphQLId('TicketState', 1),
              name: 'open',
            },
            stateColorCode: EnumTicketStateColorCode.Open,
          },
        ],
      },
    })

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.getByRole('link', { name: '99 more' })).toBeInTheDocument()

    expect(wrapper.getByText('Found organizations')).toBeInTheDocument()
    expect(wrapper.getByText('Found users')).toBeInTheDocument()
    expect(wrapper.getByText('Found tickets')).toBeInTheDocument()

    expect(wrapper.getByText('Found organizations')).toBeInTheDocument()
    expect(wrapper.getByText('Found users')).toBeInTheDocument()
    expect(wrapper.getByText('Found tickets')).toBeInTheDocument()

    expect(
      wrapper.queryByText('Start typing i.e. the name of a ticket, an organization or a user.'),
    ).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('link', { name: '99 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.params).toEqual({ searchTerm: '1' })
    expect(router.currentRoute.value.query).toEqual({ entity: 'Ticket' })
  })

  it('renders inactive users', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery({
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 2),
            internalId: 2,
            fullname: 'User 1',
          },
        ],
      },
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('User 1')

    await waitForQuickSearchQueryCalls()

    await wrapper.findByIconName('user-inactive')

    const userLink = wrapper.getByRole('link', { name: 'User 1' })

    expect(wrapper.getByText('User 1')).toHaveClass('text-neutral-500!')

    expect(userLink).toHaveAttribute('aria-description', 'User is inactive.')
  })

  it('renders inactive organization', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])

    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 1,
        items: [
          {
            __typename: 'Organization',
            active: false,
            id: convertToGraphQLId('Organization', 1),
            internalId: 1,
            name: 'Organization 1',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('Organization')

    await waitForQuickSearchQueryCalls()

    await wrapper.findByIconName('buildings-slash')

    const userLink = wrapper.getByRole('link', { name: 'Organization 1' })

    expect(wrapper.getByText('Organization 1')).toHaveClass('text-neutral-500!')
    expect(userLink).toHaveAttribute('aria-description', 'Organization is inactive.')
  })

  it('renders detailed search button if search term is provided', async () => {
    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('User')

    await waitForQuickSearchQueryCalls()

    const detailedSearchButton = await wrapper.findByRole('link', {
      name: 'detailed search',
    })

    await wrapper.events.click(detailedSearchButton)

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.params).toEqual({ searchTerm: 'User' })
  })

  it('hides customer entity from user if application not set', () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: false })

    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = renderComponent(QuickSearchResultList, {
      props: {
        search: '',
        debounceTime: 400,
      },
    })

    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
  })

  it('hides organization and users from customer', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({ kb_active: true })

    // backend should not return any data in this case, but we are testing the frontend code here
    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 1,
        items: [
          {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 1),
            internalId: 1,
            name: 'Organization 1',
          },
        ],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = renderComponent(QuickSearchResultList, {
      props: {
        search: '',
        debounceTime: 400,
      },
    })

    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found organizations')).not.toBeInTheDocument()
  })
})

// The fourth result group, and the first one gated by `show` rather than by `permissions` - see
//   plugins/knowledgeBaseAnswer.ts for why it has to be.
describe('QuickSearchResultList knowledge base answers', () => {
  const answerTranslation = (id: number, title: string) => ({
    __typename: 'KnowledgeBaseAnswerTranslation' as const,
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
    title,
    visibility: EnumKnowledgeBaseVisibility.Published,
    kbLocale: { systemLocale: { locale: 'en-us' } },
    answer: {
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      category: { id: convertToGraphQLId('KnowledgeBase::Category', 1) },
    },
  })

  const mockAnswers = (totalCount: number, ...titles: string[]) => {
    mockQuickSearchQuery({
      quickSearchOrganizations: { totalCount: 0, items: [] },
      quickSearchUsers: { totalCount: 0, items: [] },
      quickSearchTickets: { totalCount: 0, items: [] },
      quickSearchKnowledgeBaseAnswers: {
        totalCount,
        items: titles.map((title, index) => answerTranslation(index + 1, title)),
      },
    })
  }

  it('renders the group for an agent who may browse the knowledge base', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })
    mockAnswers(1, 'Ocarina tuning')

    const wrapper = await renderQuickSearchResultList('ocarina')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.getByText('Found knowledge base answers')).toBeInTheDocument()
    expect(wrapper.getByText('Ocarina tuning')).toBeInTheDocument()
  })

  // A customer holds no knowledge base permission at all, which is exactly why the plugin cannot be
  //   gated by `permissions` - AC5 of the story still promises them published answers.
  it('renders the group for a customer when the knowledge base is public', async () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({ kb_active: true, kb_active_publicly: true })
    mockAnswers(1, 'Ocarina tuning')

    const wrapper = await renderQuickSearchResultList('ocarina')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.getByText('Found knowledge base answers')).toBeInTheDocument()
  })

  it('omits the group when no answer matches', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })
    mockAnswers(0)

    const wrapper = await renderQuickSearchResultList('sackbut')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.queryByText('Found knowledge base answers')).not.toBeInTheDocument()
  })

  it('omits the group when no knowledge base is enabled', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })
    mockAnswers(1, 'Ocarina tuning')

    const wrapper = await renderQuickSearchResultList('ocarina')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.queryByText('Found knowledge base answers')).not.toBeInTheDocument()
  })

  // AC9's link to the detailed search for the rest. It carries no `entity`, unlike the other three
  //   groups: this entity has no tab to select yet (zammad/coordination-desktop-view#874), and
  //   Search.vue's beforeRouteEnter normalises a missing one - so the link opens the detailed
  //   search without writing an unselectable entity into the URL and the search taskbar tab.
  it('links to the detailed search for the answers it does not show', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })
    mockAnswers(12, 'Ocarina tuning', 'Ocarina cleaning')

    const wrapper = await renderQuickSearchResultList('ocarina')

    await waitForQuickSearchQueryCalls()

    await wrapper.events.click(wrapper.getByRole('link', { name: '10 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.params).toEqual({ searchTerm: 'ocarina' })
    expect(router.currentRoute.value.query).toEqual({})
  })

  // The control on the case above: the groups that do have a tab still name their entity.
  it('keeps the entity on the link of a group that has a detailed-search tab', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })
    mockQuickSearchQuery({
      quickSearchOrganizations: { totalCount: 0, items: [] },
      quickSearchUsers: { totalCount: 0, items: [] },
      quickSearchKnowledgeBaseAnswers: { totalCount: 0, items: [] },
      quickSearchTickets: {
        totalCount: 12,
        items: [
          {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            title: 'Ocarina ticket',
            number: '123',
            state: { id: convertToGraphQLId('Ticket::State', 1), name: 'open' },
            stateColorCode: EnumTicketStateColorCode.Open,
          },
        ],
      },
    })

    const wrapper = await renderQuickSearchResultList('ocarina')

    await waitForQuickSearchQueryCalls()

    await wrapper.events.click(wrapper.getByRole('link', { name: '11 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.query).toEqual({ entity: 'Ticket' })
  })
})
