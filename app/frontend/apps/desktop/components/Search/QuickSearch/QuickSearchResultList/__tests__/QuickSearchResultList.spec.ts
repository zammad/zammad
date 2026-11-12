// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { waitFor } from '@testing-library/vue'
import { defineComponent } from 'vue'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  EnumKnowledgeBaseVisibility,
  EnumSearchableModels,
  EnumTicketStateColorCode,
  type QuickSearchQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import {
  mockQuickSearchQuery,
  waitForQuickSearchQueryCalls,
} from '../../../graphql/queries/quickSearch.mocks.ts'
import { searchPlugins } from '../../../plugins/index.ts'
import QuickSearchResultList from '../QuickSearchResultList.vue'

import type { SearchPlugin } from '../../../types.ts'

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

// Groups are listed in the order the server answers in, which the result list must not rely on.
const quickSearchGroups = (
  groups: Partial<
    Record<
      EnumSearchableModels,
      DeepPartial<Omit<QuickSearchQuery['searchGrouped'][number], 'model'>>
    >
  >,
): DeepPartial<QuickSearchQuery> => ({
  searchGrouped: Object.entries(groups).map(([model, group]) =>
    Object.assign({ model: model as EnumSearchableModels }, group),
  ),
})

describe('QuickSearchResultList', () => {
  it('renders by default the sections with an empty state', async () => {
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: {
          totalCount: 0,
          items: [],
        },
        [EnumSearchableModels.User]: {
          totalCount: 0,
          items: [],
        },
        [EnumSearchableModels.Ticket]: {
          totalCount: 0,
          items: [],
        },
      }),
    )

    const wrapper = await renderQuickSearchResultList('')

    expect(wrapper.queryByText('Found organizations')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found tickets')).not.toBeInTheDocument()

    expect(await wrapper.findByText('No results for this query.')).toBeInTheDocument()
  })

  it('renders the sections with the results', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: {
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
        [EnumSearchableModels.User]: {
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
        [EnumSearchableModels.Ticket]: {
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
      }),
    )

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

  it('orders the groups by plugin priority regardless of the order the server answers in', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })

    const organization = {
      __typename: 'Organization' as const,
      id: convertToGraphQLId('Organization', 1),
      internalId: 1,
      name: 'Organization 1',
    }

    const user = {
      __typename: 'User' as const,
      id: convertToGraphQLId('User', 1),
      internalId: 1,
      fullname: 'User 1',
    }

    const ticket = {
      __typename: 'Ticket' as const,
      id: convertToGraphQLId('Ticket', 1),
      internalId: 1,
      title: 'Ticket 1',
      number: '1',
      state: { id: convertToGraphQLId('Ticket::State', 1), name: 'open' },
      stateColorCode: EnumTicketStateColorCode.Open,
    }

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: {
          totalCount: 1,
          items: [answerTranslation(1, 'Answer 1')],
        },
        [EnumSearchableModels.Organization]: { totalCount: 1, items: [organization] },
        [EnumSearchableModels.User]: { totalCount: 1, items: [user] },
        [EnumSearchableModels.Ticket]: { totalCount: 1, items: [ticket] },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(await wrapper.findByText('Found tickets')).toBeInTheDocument()

    expect(wrapper.getAllByText(/^Found /).map((label) => label.textContent?.trim())).toEqual([
      'Found tickets',
      'Found users',
      'Found organizations',
      'Found knowledge base answers',
    ])
  })

  it('searches only the entity types offered to an agent', async () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })
    mockQuickSearchQuery({ searchGrouped: [] })

    await renderQuickSearchResultList('1')

    const calls = await waitForQuickSearchQueryCalls()

    expect(calls.at(-1)?.variables.onlyIn).toEqual(
      expect.arrayContaining([
        EnumSearchableModels.Ticket,
        EnumSearchableModels.User,
        EnumSearchableModels.Organization,
      ]),
    )
    expect(calls.at(-1)?.variables.onlyIn).toHaveLength(3)
  })

  it('searches only the entity types offered to a customer', async () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: true })
    mockQuickSearchQuery({ searchGrouped: [] })

    await renderQuickSearchResultList('1')

    const calls = await waitForQuickSearchQueryCalls()

    expect(calls.at(-1)?.variables.onlyIn).toEqual(
      expect.arrayContaining([
        EnumSearchableModels.Ticket,
        EnumSearchableModels.KnowledgeBaseAnswerTranslation,
      ]),
    )
    expect(calls.at(-1)?.variables.onlyIn).toHaveLength(2)
  })

  it('renders inactive users', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.User]: {
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
        [EnumSearchableModels.Organization]: {
          totalCount: 0,
          items: [],
        },
        [EnumSearchableModels.Ticket]: {
          totalCount: 0,
          items: [],
        },
      }),
    )

    const wrapper = await renderQuickSearchResultList('User 1')

    await waitForQuickSearchQueryCalls()

    await wrapper.findByIconName('user-inactive')

    const userLink = wrapper.getByRole('link', { name: 'User 1' })

    expect(wrapper.getByText('User 1')).toHaveClass('text-neutral-500!')

    expect(userLink).toHaveAttribute('aria-description', 'User is inactive.')
  })

  it('renders inactive organization', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: {
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
        [EnumSearchableModels.Ticket]: {
          totalCount: 0,
          items: [],
        },
        [EnumSearchableModels.User]: {
          totalCount: 0,
          items: [],
        },
      }),
    )

    const wrapper = await renderQuickSearchResultList('Organization')

    await waitForQuickSearchQueryCalls()

    await wrapper.findByIconName('buildings-slash')

    const userLink = wrapper.getByRole('link', { name: 'Organization 1' })

    expect(wrapper.getByText('Organization 1')).toHaveClass('text-neutral-500!')
    expect(userLink).toHaveAttribute('aria-description', 'Organization is inactive.')
  })

  it('renders detailed search button if search term is provided', async () => {
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: {
          totalCount: 0,
          items: [],
        },
        [EnumSearchableModels.User]: {
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
        [EnumSearchableModels.Ticket]: {
          totalCount: 0,
          items: [],
        },
      }),
    )

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

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: {
          totalCount: 0,
          items: [],
        },
        [EnumSearchableModels.User]: {
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
        [EnumSearchableModels.Ticket]: {
          totalCount: 0,
          items: [],
        },
      }),
    )

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
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: {
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
        [EnumSearchableModels.User]: {
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
        [EnumSearchableModels.Ticket]: {
          totalCount: 0,
          items: [],
        },
      }),
    )

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

describe('QuickSearchResultList chat sessions', () => {
  const mockSessions = (totalCount: number, ...names: (string | null)[]) => {
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: { totalCount: 0, items: [] },
        [EnumSearchableModels.User]: { totalCount: 0, items: [] },
        [EnumSearchableModels.Ticket]: { totalCount: 0, items: [] },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: { totalCount: 0, items: [] },
        [EnumSearchableModels.ChatSession]: {
          totalCount,
          items: names.map((name, index) => ({
            __typename: 'ChatSession' as const,
            id: convertToGraphQLId('Chat::Session', index + 1),
            internalId: index + 1,
            name,
          })),
        },
      }),
    )
  }

  it('renders the group for a chat agent while the chat feature is on', async () => {
    mockPermissions(['chat.agent'])
    mockApplicationConfig({ chat: true })
    mockSessions(1, 'VPN setup')

    const wrapper = await renderQuickSearchResultList('vpn')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.getByText('Found chat sessions')).toBeInTheDocument()
    expect(wrapper.getByRole('link', { name: '#1 VPN setup' })).toBeInTheDocument()
  })

  it('omits the group while the chat feature is off', async () => {
    mockPermissions(['chat.agent'])
    mockApplicationConfig({ chat: false })
    mockSessions(1, 'VPN setup')

    const wrapper = await renderQuickSearchResultList('vpn')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.queryByText('Found chat sessions')).not.toBeInTheDocument()
  })

  it('links to the detailed search for the sessions it does not show', async () => {
    mockPermissions(['chat.agent'])
    mockApplicationConfig({ chat: true })
    mockSessions(12, 'VPN setup', null)

    const wrapper = await renderQuickSearchResultList('vpn')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.getByRole('link', { name: '#2' })).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('link', { name: '10 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.query).toEqual({ entity: EnumSearchableModels.ChatSession })
  })
})

// The fourth result group, and the first one gated by `show` rather than by `permissions` - see
//   plugins/knowledgeBaseAnswer.ts for why it has to be.
describe('QuickSearchResultList knowledge base answers', () => {
  const mockAnswers = (totalCount: number, ...titles: string[]) => {
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: { totalCount: 0, items: [] },
        [EnumSearchableModels.User]: { totalCount: 0, items: [] },
        [EnumSearchableModels.Ticket]: { totalCount: 0, items: [] },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: {
          totalCount,
          items: titles.map((title, index) => answerTranslation(index + 1, title)),
        },
      }),
    )
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

  // AC9's link to the detailed search for the rest.
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
    expect(router.currentRoute.value.query).toEqual({
      entity: EnumSearchableModels.KnowledgeBaseAnswerTranslation,
    })
  })

  // The same for one of the groups that had a tab all along.
  it('keeps the entity on the link of a group that has a detailed-search tab', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Organization]: { totalCount: 0, items: [] },
        [EnumSearchableModels.User]: { totalCount: 0, items: [] },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: { totalCount: 0, items: [] },
        [EnumSearchableModels.Ticket]: {
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
      }),
    )

    const wrapper = await renderQuickSearchResultList('ocarina')

    await waitForQuickSearchQueryCalls()

    await wrapper.events.click(wrapper.getByRole('link', { name: '11 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.query).toEqual({ entity: 'Ticket' })
  })
})

// The panel shows at most 10 items per group, but drops to 5 as soon as three or more entity types
//   match at once - see zammad/coordination-desktop-view#901.
describe('QuickSearchResultList per entity type limit', () => {
  const tickets = (count: number) =>
    Array.from({ length: count }, (_, index) => ({
      __typename: 'Ticket' as const,
      id: convertToGraphQLId('Ticket', index + 1),
      internalId: index + 1,
      title: `Ticket ${index + 1}`,
      number: `${index + 1}`,
      state: { id: convertToGraphQLId('Ticket::State', 1), name: 'open' },
      stateColorCode: EnumTicketStateColorCode.Open,
    }))

  const users = (count: number) =>
    Array.from({ length: count }, (_, index) => ({
      __typename: 'User' as const,
      id: convertToGraphQLId('User', index + 1),
      internalId: index + 1,
      fullname: `User ${index + 1}`,
    }))

  const organizations = (count: number) =>
    Array.from({ length: count }, (_, index) => ({
      __typename: 'Organization' as const,
      id: convertToGraphQLId('Organization', index + 1),
      internalId: index + 1,
      name: `Organization ${index + 1}`,
    }))

  const answers = (count: number) =>
    Array.from({ length: count }, (_, index) => answerTranslation(index + 1, `Answer ${index + 1}`))

  it('shows five results per group when three entity types match', async () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Ticket]: { totalCount: 10, items: tickets(10) },
        [EnumSearchableModels.User]: { totalCount: 10, items: users(10) },
        [EnumSearchableModels.Organization]: { totalCount: 10, items: organizations(10) },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: { totalCount: 0, items: [] },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(await wrapper.findByText('#5 - Ticket 5')).toBeInTheDocument()
    expect(wrapper.queryByText('#6 - Ticket 6')).not.toBeInTheDocument()

    expect(wrapper.getByText('User 5')).toBeInTheDocument()
    expect(wrapper.queryByText('User 6')).not.toBeInTheDocument()

    expect(wrapper.getByText('Organization 5')).toBeInTheDocument()
    expect(wrapper.queryByText('Organization 6')).not.toBeInTheDocument()
  })

  it('shows five results per group when all four entity types match', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Ticket]: { totalCount: 10, items: tickets(10) },
        [EnumSearchableModels.User]: { totalCount: 10, items: users(10) },
        [EnumSearchableModels.Organization]: { totalCount: 10, items: organizations(10) },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: {
          totalCount: 10,
          items: answers(10),
        },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(await wrapper.findByText('#5 - Ticket 5')).toBeInTheDocument()
    expect(wrapper.queryByText('#6 - Ticket 6')).not.toBeInTheDocument()

    expect(wrapper.getByText('Answer 5')).toBeInTheDocument()
    expect(wrapper.queryByText('Answer 6')).not.toBeInTheDocument()
  })

  // Also the sub-bullet of the first criterion: the two groups the panel drops for having no result
  //   at all do not push it over the threshold.
  it('shows ten results per group when two entity types match', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Ticket]: { totalCount: 10, items: tickets(10) },
        [EnumSearchableModels.User]: { totalCount: 10, items: users(10) },
        [EnumSearchableModels.Organization]: { totalCount: 0, items: [] },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: { totalCount: 0, items: [] },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(await wrapper.findByText('#10 - Ticket 10')).toBeInTheDocument()
    expect(wrapper.getByText('User 10')).toBeInTheDocument()

    expect(wrapper.queryByText('Found organizations')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found knowledge base answers')).not.toBeInTheDocument()
  })

  // A group the user is not shown can still carry results from the backend - cutting the two
  //   visible groups down for it would shorten the panel for a group nobody sees.
  it('does not count a group hidden from the user towards the threshold', async () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Ticket]: { totalCount: 10, items: tickets(10) },
        [EnumSearchableModels.User]: { totalCount: 10, items: users(10) },
        [EnumSearchableModels.Organization]: { totalCount: 0, items: [] },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: {
          totalCount: 10,
          items: answers(10),
        },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.queryByText('Found knowledge base answers')).not.toBeInTheDocument()

    expect(await wrapper.findByText('#10 - Ticket 10')).toBeInTheDocument()
    expect(wrapper.getByText('User 10')).toBeInTheDocument()
  })

  // The reduced limit withholds items the query already returned, so the link has to count them
  //   too - against what the group displays, not against what came back.
  it('counts the results the reduced limit withholds into the link to the detailed search', async () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })

    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Ticket]: { totalCount: 8, items: tickets(8) },
        [EnumSearchableModels.User]: { totalCount: 5, items: users(5) },
        [EnumSearchableModels.Organization]: { totalCount: 6, items: organizations(6) },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: { totalCount: 0, items: [] },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(await wrapper.findByRole('link', { name: '3 more' })).toBeInTheDocument()
    expect(wrapper.getByRole('link', { name: '1 more' })).toBeInTheDocument()

    // The group whose five results the reduced limit takes in full keeps no link at all, so the two
    //   above are the only ones the panel shows.
    expect(wrapper.getAllByRole('link', { name: /more$/ })).toHaveLength(2)

    await wrapper.events.click(wrapper.getByRole('link', { name: '3 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.params).toEqual({ searchTerm: '1' })
    expect(router.currentRoute.value.query).toEqual({ entity: 'Ticket' })
  })
})

// The GraphQL mocker only knows core types, so the add-on plugin takes over a core type whose own
//   plugin is switched off: the group has to reach the add-on component by the plugin name alone.
describe('QuickSearchResultList add-on search plugin', () => {
  const AddonSearchRow = defineComponent({
    props: { item: { type: Object, required: true }, mode: { type: String, required: true } },
    template: '<span data-test-id="addon-search-row">{{ item.title }}</span>',
  })

  const addonPlugin: SearchPlugin = {
    name: EnumSearchableModels.KnowledgeBaseAnswerTranslation,
    label: 'Add-on project',
    priority: 1000,
    quickSearchResultLabel: 'Found add-on projects',
    quickSearchComponent: AddonSearchRow,
    filtersDisabled: true,
  }

  beforeEach(() => {
    searchPlugins.push(addonPlugin)

    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ kb_active: false, kb_active_publicly: false })
  })

  afterEach(() => {
    searchPlugins.splice(searchPlugins.indexOf(addonPlugin), 1)
  })

  const addonItems = (count: number) =>
    Array.from({ length: count }, (_, index) =>
      answerTranslation(index + 1, `Project ${index + 1}`),
    )

  it('requests the add-on type and renders its rows through the add-on component', async () => {
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.Ticket]: { totalCount: 0, items: [] },
        [EnumSearchableModels.User]: { totalCount: 0, items: [] },
        [EnumSearchableModels.Organization]: { totalCount: 0, items: [] },
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: {
          totalCount: 2,
          items: addonItems(2),
        },
      }),
    )

    const wrapper = await renderQuickSearchResultList('project')

    const calls = await waitForQuickSearchQueryCalls()

    expect(calls.at(-1)?.variables.onlyIn).toContain(
      EnumSearchableModels.KnowledgeBaseAnswerTranslation,
    )

    expect(await wrapper.findByText('Found add-on projects')).toBeInTheDocument()
    expect(wrapper.queryByText('Found knowledge base answers')).not.toBeInTheDocument()

    expect(wrapper.getAllByTestId('addon-search-row').map((row) => row.textContent)).toEqual([
      'Project 1',
      'Project 2',
    ])

    expect(wrapper.queryByRole('link', { name: /more$/ })).not.toBeInTheDocument()
  })

  it('orders, limits and links the add-on group like a core group', async () => {
    mockQuickSearchQuery(
      quickSearchGroups({
        [EnumSearchableModels.KnowledgeBaseAnswerTranslation]: {
          totalCount: 12,
          items: addonItems(10),
        },
        [EnumSearchableModels.Organization]: {
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
        [EnumSearchableModels.User]: {
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
        [EnumSearchableModels.Ticket]: { totalCount: 0, items: [] },
      }),
    )

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(await wrapper.findByText('Found add-on projects')).toBeInTheDocument()

    expect(wrapper.getAllByText(/^Found /).map((label) => label.textContent?.trim())).toEqual([
      'Found users',
      'Found organizations',
      'Found add-on projects',
    ])

    expect(wrapper.getAllByTestId('addon-search-row')).toHaveLength(5)

    await wrapper.events.click(wrapper.getByRole('link', { name: '7 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.query).toEqual({
      entity: EnumSearchableModels.KnowledgeBaseAnswerTranslation,
    })
  })
})
