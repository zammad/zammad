// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { vi } from 'vitest'
import { computed, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketExternalReferencesIssueTrackerItemState } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketSidebarGitLab from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/TicketSidebarGitLab/TicketSidebarGitLab.vue'
import { TICKET_SIDEBAR_SYMBOL } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import { waitForTicketExternalReferencesIssueTrackerItemAddMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIssueTrackerItemAdd.mocks.ts'
import { waitForTicketExternalReferencesIssueTrackerItemRemoveMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIssueTrackerItemRemove.mocks.ts'
import { mockTicketExternalReferencesIssueTrackerItemListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

// INFO: Import as relative to avoid vite import error if it gets imported before TicketSidebarGitLab
import gitLabPlugin from '../../../../plugins/gitlab.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

mockRouterHooks()

const mockedIssues = [
  {
    assignees: ['Benjamin Foo'],
    issueId: 356,
    labels: [
      {
        color: '#009966',
        textColor: '#FFFFFF',
        title: 'New tech stack',
      },
    ],
    milestone: 'Frontend refactoring',
    state: EnumTicketExternalReferencesIssueTrackerItemState.Open,
    title: 'Example issue for GitLab integration',
    url: 'https://git.zammad.com/zammad/zammad/-/issues/123',
  },
  {
    assignees: ['Benjamin Ha'],
    issueId: 353,
    labels: [
      {
        color: 'rgba(121,47,136,0.44)',
        textColor: '#FFFFFF',
        title: 'ship',
      },
    ],
    milestone: 'Shipping',
    state: EnumTicketExternalReferencesIssueTrackerItemState.Open,
    title: 'Safe harbor',
    url: 'https://git.zammad.com/zammad/zammad/-/issues/111',
  },
]

const renderGitLabSidebar = (
  isTicketEditable = true,
  ticketExternalReferencesIssueTrackerItemList = mockedIssues,
) => {
  mockApplicationConfig({
    gitlab_integration: true,
  })
  mockTicketExternalReferencesIssueTrackerItemListQuery({
    ticketExternalReferencesIssueTrackerItemList,
  })

  const gitLabLinks: string[] = []

  if (ticketExternalReferencesIssueTrackerItemList?.length) {
    ticketExternalReferencesIssueTrackerItemList.forEach((issue) => {
      gitLabLinks.push(issue.url)
    })
  }
  const ticket = createDummyTicket({
    externalReferences: { gitlab: gitLabLinks },
  })

  return renderComponent(TicketSidebarGitLab, {
    props: {
      sidebar: 'gitlab',
      sidebarPlugin: gitLabPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        formValues: {},
        toggleCollapse: () => {},
        isCollapsed: false,
        ticket: computed(() => ticket),
        isTicketEditable: computed(() => isTicketEditable),
      },
    },
    global: {
      stubs: {
        teleport: true,
      },
    },
    flyout: true,
    form: true,
    router: true,
  })
}

describe('TicketSidebarGitLab', () => {
  it('displays on ticket create screen correctly', async () => {
    await mockApplicationConfig({
      gitlab_integration: true,
    })

    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: [],
    })

    const wrapper = renderComponent(TicketSidebarGitLab, {
      props: {
        sidebar: 'gitlab',
        sidebarPlugin: gitLabPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketCreate,
          form: {
            formInitialSettled: true,
          },
          formValues: {},
          isTicketEditable: true,
          toggleCollapse: () => {},
          isCollapsed: false,
        },
      },
      provide: [
        [
          TICKET_SIDEBAR_SYMBOL,
          {
            shownSidebars: ref('gitlab'),
            activeSidebar: ref('gitlab'),
            switchSidebar: vi.fn(),
          },
        ],
      ],
      global: {
        stubs: {
          teleport: true,
        },
      },
      router: true,
      flyout: true,
      form: true,
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'GitLab' }))

    await waitForNextTick()

    expect(wrapper.getByRole('button', { name: 'GitLab' })).toBeInTheDocument()

    expect(
      wrapper.getByRole('button', { name: 'Link Issue' }),
    ).toBeInTheDocument()

    expect(
      wrapper.queryByRole('status', { name: 'Issues' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })

  it('displays the GitLab issue tracker', async () => {
    const wrapper = renderGitLabSidebar()

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent(
      'GitLab',
    )

    expect(
      await wrapper.findByRole('status', { name: 'Issues' }),
    ).toHaveTextContent('2')

    expect(
      await wrapper.findByRole('link', {
        name: '#356 Example issue for GitLab integration',
      }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', {
        name: '#353 Safe harbor',
      }),
    ).toBeInTheDocument()
  })

  it('links a new issue with issues present', async () => {
    const wrapper = renderGitLabSidebar()

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Action menu button' }),
    )

    expect(await wrapper.findByIconName('link-45deg')).toBeInTheDocument()
    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Link Issue' }),
    )

    const flyout = await wrapper.findByRole('complementary', {
      name: 'GitLab: Link issue',
    })

    expect(within(flyout).getByRole('heading', { level: 2 })).toHaveTextContent(
      'GitLab: Link issue',
    )

    await wrapper.events.type(
      wrapper.getByLabelText('Issue URL'),
      'https://git.zammad.com/zammad/zammad/-/issues/124',
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Link Issue' }),
    )

    const calls =
      await waitForTicketExternalReferencesIssueTrackerItemAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      issueTrackerLink: 'https://git.zammad.com/zammad/zammad/-/issues/124',
      issueTrackerType: 'gitlab',
      ticketId: convertToGraphQLId('Ticket', '1'),
    })
  })

  it('links a new issue with no issues present', async () => {
    const wrapper = renderGitLabSidebar(true, [])

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Link Issue' }),
    )

    const flyout = await wrapper.findByRole('complementary', {
      name: 'GitLab: Link issue',
    })

    expect(within(flyout).getByRole('heading', { level: 2 })).toHaveTextContent(
      'GitLab: Link issue',
    )
  })

  it('unlinks an issue in entries are present', async () => {
    const wrapper = renderGitLabSidebar()

    expect(
      await wrapper.findByRole('link', {
        name: '#356 Example issue for GitLab integration',
      }),
    ).toBeInTheDocument()

    const unlinkButtons = wrapper.getAllByRole('button', {
      name: 'Unlink issue',
    })

    await wrapper.events.click(unlinkButtons[0])

    const calls =
      await waitForTicketExternalReferencesIssueTrackerItemRemoveMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      issueTrackerLink: 'https://git.zammad.com/zammad/zammad/-/issues/123',
      issueTrackerType: 'gitlab',
      ticketId: 'gid://zammad/Ticket/1',
    })
  })

  it('does not display if no issues are linked and agent does not have update permission', async () => {
    const wrapper = renderGitLabSidebar(false, [])

    expect(wrapper.emitted('hide')).toHaveLength(1)
  })

  it('does not allow linking or removing links if ticket is not editable', async () => {
    const wrapper = renderGitLabSidebar(false)

    await waitForNextTick()

    expect(wrapper.emitted('show')).toHaveLength(1)

    expect(
      wrapper.queryByRole('button', { name: 'Unlink issue' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })
})
