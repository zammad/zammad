// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import githubPlugin from '#desktop/pages/ticket/components/TicketSidebar/plugins/github.ts'
import TicketSidebarGitHub from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/TicketSidebarGitHub/TicketSidebarGitHub.vue'
import { TicketExternalReferencesIssueTrackerItemListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

mockRouterHooks()

describe('errors', () => {
  it('shows an generic error message if query fails due failure of GitLab api', async () => {
    mockApplicationConfig({
      github_integration: true,
    })

    mockGraphQLApi(
      TicketExternalReferencesIssueTrackerItemListDocument,
    ).willFailWithError([
      {
        message:
          'GitHub request failed. Please have a look at the log file for details',
        extensions: {
          type: GraphQLErrorTypes.UnknownError,
        },
      },
    ])

    const wrapper = renderComponent(TicketSidebarGitHub, {
      props: {
        sidebar: 'github',
        sidebarPlugin: githubPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketDetailView,
          formValues: {},
          toggleCollapse: () => {},
          isCollapsed: false,
          ticket: computed(() =>
            createDummyTicket({
              externalReferences: {
                github: [
                  // 'https://github.com/zammad/zammad/issues/54',
                  // 'https://github.com/zammad/zammad/issues/55',
                ],
              },
            }),
          ),
          isTicketEditable: true,
        },
      },
      global: {
        stubs: {
          teleport: true,
        },
      },
      flyout: true,
      router: true,
    })

    expect(await wrapper.findByRole('alert')).toHaveTextContent(
      'Error fetching information from GitHub. Please contact your administrator.',
    )

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })
})
