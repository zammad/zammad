// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { vi } from 'vitest'
import { computed, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import TicketSidebarSnipeit from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/TicketSidebarSnipeit.vue'
import { TICKET_SIDEBAR_SYMBOL } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import { waitForTicketExternalReferencesSnipeitAssetRemoveMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesSnipeitAssetRemove.mocks.ts'
import {
  mockTicketExternalReferencesSnipeitAssetListQuery,
  mockTicketExternalReferencesSnipeitAssetListQueryError,
} from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesSnipeitAssetList.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import snipeitPlugin from '../../../plugins/snipeit.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

mockRouterHooks()

const mockedData = [
  {
    snipeitAssetId: 111,
    name: 'Asset 1',
    link: 'www.snipeit.com/hardware/111',
    status: 'Ready to Deploy',
    model: 'MacBook Pro',
    category: 'Laptops',
    assetTag: 'LAP001',
  },
  {
    snipeitAssetId: 2222,
    name: 'Asset 2',
    link: 'www.snipeit.com/hardware/222',
    status: 'Deployed',
    model: 'UltraSharp',
    category: 'Monitors',
    assetTag: 'MON001',
  },
]

const renderSnipeitSidebar = (
  isTicketEditable = true,
  assets = mockedData,
  customMocks = false,
) => {
  mockApplicationConfig({
    snipeit_integration: true,
  })

  if (!customMocks) {
    mockTicketExternalReferencesSnipeitAssetListQuery({
      ticketExternalReferencesSnipeitAssetList: assets,
    })
  }

  const snipeitIds: number[] = []

  if (assets?.length) {
    assets.forEach(({ snipeitAssetId }) => {
      snipeitIds.push(snipeitAssetId)
    })
  }
  const ticket = createDummyTicket({
    preferences: { snipeit: { asset_ids: snipeitIds } },
  })

  return renderComponent(TicketSidebarSnipeit, {
    props: {
      sidebar: 'snipeit',
      sidebarPlugin: snipeitPlugin,
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
    store: true,
  })
}

describe('TicketSidebarSnipeit', () => {
  it('displays on ticket create screen correctly without assets', async () => {
    await mockApplicationConfig({
      snipeit_integration: true,
    })

    const wrapper = renderComponent(TicketSidebarSnipeit, {
      props: {
        sidebar: 'snipeit',
        sidebarPlugin: snipeitPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketCreate,
          formValues: {},
          form: {
            formInitialSettled: true,
          },
          toggleCollapse: () => {},
          isCollapsed: false,
        },
      },
      provide: [
        [
          TICKET_SIDEBAR_SYMBOL,
          {
            shownSidebars: ref('snipeit'),
            activeSidebar: ref('snipeit'),
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

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Snipe-IT' }))

    await waitForNextTick()

    expect(wrapper.getByRole('button', { name: 'Link assets' })).toBeInTheDocument()

    expect(wrapper.queryByRole('status', { name: 'Assets' })).not.toBeInTheDocument()

    expect(wrapper.queryByRole('button', { name: 'Action menu button' })).not.toBeInTheDocument()
  })

  it('displays on ticket create screen correctly with assets', async () => {
    await mockApplicationConfig({
      snipeit_integration: true,
    })

    mockTicketExternalReferencesSnipeitAssetListQuery({
      ticketExternalReferencesSnipeitAssetList: mockedData,
    })

    const wrapper = renderComponent(TicketSidebarSnipeit, {
      props: {
        sidebar: 'snipeit',
        sidebarPlugin: snipeitPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketCreate,
          formValues: {
            externalReferences: {
              snipeit: [111, 2222],
            },
          },
          form: {
            formInitialSettled: true,
          },
          toggleCollapse: () => {},
          isCollapsed: false,
        },
      },
      provide: [
        [
          TICKET_SIDEBAR_SYMBOL,
          {
            shownSidebars: ref('snipeit'),
            activeSidebar: ref('snipeit'),
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

    expect(wrapper.queryByRole('status', { name: 'Assets' })).toBeInTheDocument()

    expect(wrapper.queryByRole('button', { name: 'Action menu button' })).toBeInTheDocument()

    const group = await wrapper.findAllByRole('group')

    expect(group).toHaveLength(2)
  })

  it('displays the snipeit sidebar with assets', async () => {
    const wrapper = renderSnipeitSidebar(true, [mockedData[0]])

    expect(wrapper.getByRole('heading', { name: 'Snipe-IT', level: 2 }))
    expect(wrapper.getAllByIconName('snipeit-logo-dark')).toHaveLength(2)

    expect(wrapper.getByRole('button', { name: 'Snipe-IT' })).toBeInTheDocument()
    expect(wrapper.getByRole('status', { name: 'Assets' })).toHaveTextContent('1')

    const link = await wrapper.findByRole('link')

    expect(link).toHaveTextContent('Asset 1')
    expect(link).toHaveAttribute('href', 'www.snipeit.com/hardware/111')

    const group = wrapper.getByRole('group')

    expect(group).toHaveTextContent('ID')
    expect(group).toHaveTextContent('Asset Tag')
    expect(group).toHaveTextContent('Status')
    expect(group).toHaveTextContent('Model')
    expect(group).toHaveTextContent('Category')
  })

  it('adds a new asset with assets present', async () => {
    const wrapper = renderSnipeitSidebar()

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Action menu button' }))

    const menu = await wrapper.findByRole('menu')

    await wrapper.events.click(within(menu).getByRole('button', { name: 'Link assets' }))

    const flyout = await wrapper.findByRole('complementary', {
      name: 'Snipe-IT: Link assets',
    })

    expect(wrapper.getAllByIconName('snipeit-logo-dark')).toHaveLength(3)

    expect(flyout).toBeInTheDocument()
  })

  it('removes an asset if entries are present', async () => {
    const wrapper = renderSnipeitSidebar()

    const unlinkButtons = await wrapper.findAllByRole('button', {
      name: 'Unlink asset',
    })

    await wrapper.events.click(unlinkButtons[0])

    const calls = await waitForTicketExternalReferencesSnipeitAssetRemoveMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      ticketId: convertToGraphQLId('Ticket', 1),
      snipeitAssetId: 111,
    })
  })

  it('does not display if no assets are linked and agent does not have update permission', async () => {
    const wrapper = renderSnipeitSidebar(false, [])
    expect(wrapper.emitted('hide')).toHaveLength(1)
  })

  it('does not allow adding or removing assets if ticket is not editable', async () => {
    const wrapper = renderSnipeitSidebar(false)

    await waitForNextTick()

    expect(wrapper.queryByRole('button', { name: 'Unlink asset' })).not.toBeInTheDocument()

    expect(wrapper.queryByRole('button', { name: 'Action menu button' })).not.toBeInTheDocument()
  })

  it('updates to light logo if theme is dark', () => {
    mockUserCurrent({
      preferences: {
        theme: 'dark',
      },
    })

    const wrapper = renderSnipeitSidebar()

    expect(wrapper.getAllByIconName('snipeit-logo-light')).toHaveLength(2)
  })

  it('updates to dark logo if theme is light', () => {
    mockUserCurrent({
      preferences: {
        theme: 'light',
      },
    })

    const wrapper = renderSnipeitSidebar()

    expect(wrapper.getAllByIconName('snipeit-logo-dark')).toHaveLength(2)
  })
})

describe('errors', () => {
  it('shows a generic error message if query fails due to failure of Snipe-IT api', async () => {
    mockApplicationConfig({
      snipeit_integration: true,
    })

    mockTicketExternalReferencesSnipeitAssetListQueryError(
      'Snipe-IT request failed. Please have a look at the log file for details',
      { type: GraphQLErrorTypes.UnknownError },
    )

    const wrapper = renderComponent(TicketSidebarSnipeit, {
      props: {
        sidebar: 'snipeit',
        sidebarPlugin: snipeitPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketDetailView,
          formValues: {},
          toggleCollapse: () => {},
          isCollapsed: false,
          ticket: ref(
            createDummyTicket({
              preferences: {
                snipeit: {
                  asset_ids: [111, 2222],
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
      'Error fetching information from Snipe-IT. Please contact your administrator.',
    )

    expect(wrapper.queryByRole('button', { name: 'Action menu button' })).not.toBeInTheDocument()
  })
})
