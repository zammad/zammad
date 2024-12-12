// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import gitlabPlugin from '#desktop/pages/ticket/components/TicketSidebar/plugins/gitlab.ts'
import TicketSidebarGitLab from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/TicketSidebarGitLab/TicketSidebarGitLab.vue'
import { TicketExternalReferencesIssueTrackerItemListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

mockRouterHooks()

describe('errors', () => {
  it('shows an generic error message if query fails due failure of GitLab api', async () => {
    mockApplicationConfig({
      gitlab_integration: true,
    })
    mockGraphQLApi(
      TicketExternalReferencesIssueTrackerItemListDocument,
    ).willFailWithError([
      {
        message:
          'GitLab request failed. Please have a look at the log file for details',
        extensions: {
          type: GraphQLErrorTypes.UnknownError,
        },
      },
    ])

    const wrapper = renderComponent(TicketSidebarGitLab, {
      props: {
        sidebar: 'gitlab',
        sidebarPlugin: gitlabPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketDetailView,
          formValues: {},
          toggleCollapse: () => {},
          isCollapsed: false,
          ticket: computed(() =>
            createDummyTicket({
              externalReferences: {
                gitlab: [
                  // 'https://git.zammad.com/zammad/zammad/-/issues/123',
                  // 'https://git.zammad.com/zammad/zammad/-/issues/124',
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
      form: true,
      router: true,
      store: true,
    })

    expect(await wrapper.findByRole('alert')).toHaveTextContent(
      'Error fetching information from GitLab. Please contact your administrator.',
    )

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })
})
