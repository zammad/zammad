// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { computed, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketSidebarIdoit from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/TicketSidebarIdoit.vue'
import { TICKET_SIDEBAR_SYMBOL } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import { waitForTicketExternalReferencesIdoitObjectRemoveMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIdoitObjectRemove.mocks.ts'
import { mockTicketExternalReferencesIdoitObjectListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectList.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import idoitPlugin from '../../../plugins/idoit.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

const mockedData = [
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
]

const renderIdoitSidebar = (
  isTicketEditable = true,
  objects = mockedData,
  customMocks = false,
) => {
  mockApplicationConfig({
    idoit_integration: true,
  })

  if (!customMocks) {
    mockTicketExternalReferencesIdoitObjectListQuery({
      ticketExternalReferencesIdoitObjectList: objects,
    })
  }

  const iDoitIds: number[] = []

  if (objects?.length) {
    objects.forEach(({ idoitObjectId }) => {
      iDoitIds.push(idoitObjectId)
    })
  }
  const ticket = createDummyTicket({
    preferences: { idoit: { object_ids: iDoitIds } },
  })

  return renderComponent(TicketSidebarIdoit, {
    props: {
      sidebar: 'i-doit',
      sidebarPlugin: idoitPlugin,
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

describe('TicketSidebarIdoit', () => {
  it('displays on ticket create screen correctly without objects', async () => {
    await mockApplicationConfig({
      idoit_integration: true,
    })

    const wrapper = renderComponent(TicketSidebarIdoit, {
      props: {
        sidebar: 'idoit',
        sidebarPlugin: idoitPlugin,
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
            shownSidebars: ref('idoit'),
            activeSidebar: ref('idoit'),
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

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'i-doit' }),
    )

    await waitForNextTick()

    expect(
      wrapper.getByRole('button', { name: 'Link Objects' }),
    ).toBeInTheDocument()

    expect(
      wrapper.queryByRole('status', { name: 'Objects' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })

  it('displays on ticket create screen correctly without objects', async () => {
    await mockApplicationConfig({
      idoit_integration: true,
    })

    mockTicketExternalReferencesIdoitObjectListQuery({
      ticketExternalReferencesIdoitObjectList: mockedData,
    })

    const wrapper = renderComponent(TicketSidebarIdoit, {
      props: {
        sidebar: 'idoit',
        sidebarPlugin: idoitPlugin,
        selected: true,
        context: {
          screenType: TicketSidebarScreenType.TicketCreate,
          formValues: {
            externalReferences: {
              idoit: [111, 2222],
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
            shownSidebars: ref('idoit'),
            activeSidebar: ref('idoit'),
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

    expect(
      wrapper.queryByRole('status', { name: 'Objects' }),
    ).toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).toBeInTheDocument()

    const group = await wrapper.findAllByRole('group')

    expect(group).toHaveLength(2)
  })

  it('displays the idoit sidebar with objects', async () => {
    const wrapper = renderIdoitSidebar(true, [mockedData[0]])

    expect(wrapper.getByRole('heading', { name: 'i-doit', level: 2 }))
    expect(wrapper.getAllByIconName('i-doit-logo-dark')).toHaveLength(2)

    expect(wrapper.getByRole('button', { name: 'i-doit' })).toBeInTheDocument()
    expect(wrapper.getByRole('status', { name: 'Objects' })).toHaveTextContent(
      '1',
    )

    const link = await wrapper.findByRole('link')

    expect(link).toHaveTextContent('Object 1')
    expect(link).toHaveAttribute('href', 'www.idoit.com/?object_id=111')

    const group = wrapper.getByRole('group')

    expect(group).toHaveTextContent('ID')
    expect(group).toHaveTextContent('Object 1')

    expect(group).toHaveTextContent('Status')
    expect(group).toHaveTextContent('Application')

    expect(group).toHaveTextContent('Type')
    expect(group).toHaveTextContent('Application')
  })

  it('adds a new object with issues present', async () => {
    const wrapper = renderIdoitSidebar()

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Action menu button' }),
    )

    const menu = await wrapper.findByRole('menu')

    await wrapper.events.click(
      within(menu).getByRole('button', { name: 'Link objects' }),
    )

    const flyout = await wrapper.findByRole('complementary', {
      name: 'i-doit: Link objects',
    })

    expect(wrapper.getAllByIconName('i-doit-logo-dark')).toHaveLength(3)

    expect(flyout).toBeInTheDocument() // :TODO adjust the rest for add mutation
  })

  it('removes an objects if entries are present', async () => {
    const wrapper = renderIdoitSidebar()

    const unlinkButtons = await wrapper.findAllByRole('button', {
      name: 'Unlink object',
    })

    await wrapper.events.click(unlinkButtons[0])

    const calls =
      await waitForTicketExternalReferencesIdoitObjectRemoveMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      ticketId: convertToGraphQLId('Ticket', 1),
      idoitObjectId: 111,
    })
  })

  it('does not display if no objects are linked and agent does not have update permission', async () => {
    const wrapper = renderIdoitSidebar(false, [])
    expect(wrapper.emitted('hide')).toHaveLength(1)
  })

  it('does not allow adding or removing objects if ticket is not editable', async () => {
    const wrapper = renderIdoitSidebar(false)

    await waitForNextTick()

    expect(
      wrapper.queryByRole('button', { name: 'Unlink object' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()
  })

  it('updates to light logo if theme is dark', () => {
    mockUserCurrent({
      preferences: {
        theme: 'dark',
      },
    })

    const wrapper = renderIdoitSidebar()

    expect(wrapper.getAllByIconName('i-doit-logo-light')).toHaveLength(2)
  })

  it('updates to dark logo if theme is light', () => {
    mockUserCurrent({
      preferences: {
        theme: 'light',
      },
    })

    const wrapper = renderIdoitSidebar()

    expect(wrapper.getAllByIconName('i-doit-logo-dark')).toHaveLength(2)
  })
})
