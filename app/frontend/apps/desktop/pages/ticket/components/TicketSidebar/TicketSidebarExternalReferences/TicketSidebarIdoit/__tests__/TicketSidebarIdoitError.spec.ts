// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { vi } from 'vitest'
import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import idoitPlugin from '#desktop/pages/ticket/components/TicketSidebar/plugins/idoit.ts'
import TicketSidebarIdoit from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/TicketSidebarIdoit.vue'
import { TicketExternalReferencesIdoitObjectListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

mockRouterHooks()

describe('errors', () => {
  it('shows an generic error message if query fails due failure of i-doit api', async () => {
    mockApplicationConfig({
      idoit_integration: true,
    })
    mockGraphQLApi(
      TicketExternalReferencesIdoitObjectListDocument,
    ).willFailWithError([
      {
        message:
          'I-doit request failed. Please have a look at the log file for details',
        extensions: {
          type: GraphQLErrorTypes.UnknownError,
        },
      },
    ])

    const wrapper = renderComponent(TicketSidebarIdoit, {
      props: {
        sidebar: 'i-doit',
        sidebarPlugin: idoitPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketDetailView,
          formValues: {},
          toggleCollapse: () => {},
          isCollapsed: false,
          ticket: ref(
            createDummyTicket({
              preferences: {
                idoit: {
                  object_ids: [
                    {
                      idoitObjectId: 111,
                      title: 'Object 1',
                      link: 'www.idoit.com/?object_id=111',
                      type: 'Application',
                    },
                    {
                      idoitObjectId: 2222,
                      title: 'Object 2',
                      link: 'www.idoit.com/?object_id=222',
                      type: 'Monitor',
                    },
                  ],
                },
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
      'Error fetching information from i-doit. Please contact your administrator.',
    )

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })
})
