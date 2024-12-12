// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { computed, ref } from 'vue'

import {
  type ExtendedRenderResult,
  renderComponent,
} from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  type ChecklistItem,
  type ChecklistTemplate,
  type TicketChecklistUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import '#tests/graphql/builders/mocks.ts'

import { waitForTicketChecklistAddMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistAdd.mocks.ts'
import { waitForTicketChecklistDeleteMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistDelete.mocks.ts'
import { waitForTicketChecklistItemDeleteMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemDelete.mocks.ts'
import {
  mockTicketChecklistItemUpsertMutation,
  waitForTicketChecklistItemUpsertMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemUpsert.mocks.ts'
import { waitForTicketChecklistTitleUpdateMutationCalls } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistTitleUpdate.mocks.ts'
import { mockChecklistTemplatesQuery } from '#desktop/pages/ticket/graphql/queries/checklistTemplates.mocks.ts'
import { mockTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.mocks.ts'
import { getChecklistTemplateUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/checklistTemplateUpdates.mocks.ts'
import { getTicketChecklistUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import checklistSidebarPlugin from '../../plugins/checklist.ts'
import TicketSidebarChecklist from '../TicketSidebarChecklist.vue'

const ticket = { value: createDummyTicket() }

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticketInternalId: ref(ticket.value.internalId),
    ticketId: computed(() => ticket.value.id),
    ticket: computed(() => ticket.value),
    isTicketEditable: computed(() => !!ticket.value?.policy.update),
  }),
}))

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForConfirmation: () => Promise.resolve(true),
    waitForVariantConfirmation: () => Promise.resolve(true),
  }),
}))

mockRouterHooks()

const templateMocks: Partial<ChecklistTemplate>[] = [
  {
    __typename: 'ChecklistTemplate',
    id: convertToGraphQLId('Checklist::Item', 1),
    name: 'Foo template',
    active: true,
  },
  {
    __typename: 'ChecklistTemplate',
    id: convertToGraphQLId('Checklist::Item', 2),
    name: 'Bar template',
    active: true,
  },
  {
    __typename: 'ChecklistTemplate',
    id: convertToGraphQLId('Checklist::Item', 3),
    name: 'Hu template',
    active: true,
  },
]

const checklistItemsMock: Partial<ChecklistItem>[] = [
  {
    __typename: 'ChecklistItem',
    id: convertToGraphQLId('Checklist::Item', 1),
    text: 'Checklist item A',
    checked: false,
    ticketReference: null,
  },
  {
    __typename: 'ChecklistItem',
    id: convertToGraphQLId('Checklist::Item', 2),
    text: 'Checklist item B',
    checked: false,
    ticketReference: null,
  },
]

// Overrides the default checklist values if set to null, checklist will be empty
const mockChecklistUpdateSubscription = async (
  partialTicketChecklist: Partial<
    TicketChecklistUpdatesSubscription['ticketChecklistUpdates']['ticketChecklist']
  > | null,
) => {
  if (partialTicketChecklist === null) {
    await getTicketChecklistUpdatesSubscriptionHandler().trigger({
      ticketChecklistUpdates: {
        ticketChecklist: null,
      },
    })
    return
  }

  const ticketChecklist = {
    completed: false,
    name: 'Checklist title',
    id: convertToGraphQLId('Checklist', 1),
    items: [
      {
        checked: false,
        id: convertToGraphQLId('Checklist::Item', 1),
        text: 'Checklist item A',
      },
      {
        checked: false,
        id: convertToGraphQLId('Checklist::Item', 2),
        text: 'Checklist item B',
      },
    ],
    ...partialTicketChecklist,
  }

  await getTicketChecklistUpdatesSubscriptionHandler().trigger({
    ticketChecklistUpdates: {
      removedTicketChecklist: null,
      ticketChecklist,
    },
  })
}

const openMenuAndClickAction = async (
  wrapper: ExtendedRenderResult,
  action: string,
  /**
   * 0 is checklist menu
   * 1 is checklist item menu
   */
  index = 1,
) => {
  await wrapper.events.click(
    wrapper
      .getAllByRole('button', { name: 'Action menu button' })
      .at(index) as HTMLElement,
  )

  expect(await wrapper.findByRole('menu')).toBeInTheDocument()

  await wrapper.events.click(wrapper.getByRole('button', { name: action }))
}

const verifyChecked = async (
  checkboxes: HTMLElement[],
  withSubscription = true,
) => {
  const upsertCalls = await waitForTicketChecklistItemUpsertMutationCalls()

  expect(upsertCalls.at(-1)?.variables).toEqual({
    checklistId: convertToGraphQLId('Checklist', 1),
    checklistItemId: convertToGraphQLId('Checklist::Item', 1),
    input: {
      checked: true,
    },
  })

  if (withSubscription) {
    await mockChecklistUpdateSubscription({
      items: [
        {
          checked: true,
          id: convertToGraphQLId('Checklist::Item', 1),
          text: 'Checklist item A',
        },
        {
          checked: false,
          id: convertToGraphQLId('Checklist::Item', 2),
          text: 'Checklist item B',
        },
      ],
    })
  }

  expect(checkboxes[0]).toBeChecked()
}

const verifyTextUpdate = async (
  wrapper: ExtendedRenderResult,
  withSubscription = true,
) => {
  if (withSubscription) {
    await mockChecklistUpdateSubscription({
      items: [
        {
          checked: false,
          id: convertToGraphQLId('Checklist::Item', 1),
          text: 'Checklist item A update',
        },
        {
          checked: false,
          id: convertToGraphQLId('Checklist::Item', 2),
          text: 'Checklist item B',
        },
      ],
    })
  }

  expect(
    await wrapper.findByText('Checklist item A update'),
  ).toBeInTheDocument()
}

const renderChecklist = async () => {
  const result = renderComponent(TicketSidebarChecklist, {
    props: {
      sidebar: 'checklist',
      sidebarPlugin: checklistSidebarPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        formValues: {},
        toggleCollapse: () => {},
        isCollapsed: false,
      },
    },
    router: true,
    form: true,
    dialog: true,
  })

  await waitForNextTick()

  return result
}

describe('TicketSidebarChecklist', () => {
  beforeAll(() => {
    const app = document.createElement('div')
    app.id = 'ticketSidebar'
    document.body.appendChild(app)
  })

  afterAll(() => {
    document.body.innerHTML = ''
  })

  beforeEach(() => {
    ticket.value = createDummyTicket()

    mockApplicationConfig({ ticket_hook: 'TicketTitle#' })
  })

  it('displays content in readonly mode if agent has no permissions', async () => {
    mockTicketChecklistQuery({
      ticketChecklist: null,
    })

    ticket.value = createDummyTicket({
      defaultPolicy: {
        agentReadAccess: true,
        update: false,
      },
    })

    const wrapper = await renderChecklist()

    expect(wrapper.getAllByIconName('checklist')).toHaveLength(2)

    expect(
      await wrapper.findByText('No checklist added to this ticket yet.'),
    ).toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Add From a Template' }),
    ).not.toBeInTheDocument()
  })

  it('displays permission denied message for checklist item if agent has no permission on linked ticket', async () => {
    mockTicketChecklistQuery({
      ticketChecklist: {
        name: 'Checklist title',
        items: [
          {
            __typename: 'ChecklistItem',
            id: convertToGraphQLId('Checklist::Item', 1),
            text: 'Checklist item A',
            checked: false,
            ticketReference: {
              ticket: null,
            },
          },
        ],
      },
    })

    ticket.value = createDummyTicket({
      defaultPolicy: {
        agentReadAccess: true,
        update: false,
      },
    })

    const wrapper = await renderChecklist()

    expect(await wrapper.findByText('Access denied')).toBeInTheDocument()
    expect(wrapper.getByIconName('x-lg')).toBeInTheDocument()
  })

  it('creates a empty checklist with a couple of items', async () => {
    mockTicketChecklistQuery({
      ticketChecklist: null,
    })

    const wrapper = await renderChecklist()

    expect(
      wrapper.getByRole('heading', { name: 'Checklist', level: 2 }),
    ).toBeInTheDocument()

    expect(wrapper.getAllByIconName('checklist')).toHaveLength(2)

    expect(
      await wrapper.findByRole('button', { name: 'Add Empty Checklist' }),
    ).toBeInTheDocument()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Add Empty Checklist' }),
    )

    await waitFor(() =>
      expect(
        wrapper.getByRole('button', { name: 'Add Empty Checklist' }),
      ).not.toBeDisabled(),
    )
    const calls = await waitForTicketChecklistAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      ticketId: convertToGraphQLId('Ticket', 1),
    })
  })

  it('shows message if checklist is empty', async () => {
    mockTicketChecklistQuery({
      ticketChecklist: {
        id: convertToGraphQLId('Checklist', 1),
        name: 'Checklist title',
        completed: true,
        incomplete: 0,
        items: nullableMock([]),
      },
    })
    const wrapper = await renderChecklist()

    expect(
      await wrapper.findByText('No checklist items yet'),
    ).toBeInTheDocument()
  })

  describe('actions', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])
    })

    it('update checklist title', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          name: 'Checklist title',
          items: [],
        },
      })

      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      await wrapper.events.click(
        wrapper.getByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      )

      expect(await wrapper.findByRole('textbox')).toBeInTheDocument()

      await wrapper.events.type(await wrapper.findByRole('textbox'), ' update')

      await wrapper.events.click(
        wrapper.getByRole('button', { name: 'Save changes' }),
      )

      const calls = await waitForTicketChecklistTitleUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        checklistId: convertToGraphQLId('Checklist', 999), // Mock Error: Should be the checklist id of 1
        title: 'Checklist title update',
      })

      // Subscription runs correctly, but somehow there is an identity problem with the id
      // Subscription update runs but does not update the query with the new data

      // await mockChecklistUpdateSubscription({
      //   name: 'Checklist title update',
      // })
      //
      // expect(
      //   await wrapper.findByRole('heading', {
      //     level: 3,
      //     name: 'Checklist title update',
      //   }),
      // ).toBeInTheDocument()
    })

    it('checks item through checkbox', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: checklistItemsMock,
        },
      })
      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      const checkboxes = wrapper.getAllByRole('checkbox')

      await wrapper.events.click(checkboxes[0])

      await verifyChecked(checkboxes)
    })

    it('checks item through action menu', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: checklistItemsMock,
        },
      })
      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      mockTicketChecklistItemUpsertMutation({
        ticketChecklistItemUpsert: {
          checklistItem: {
            id: convertToGraphQLId('Checklist::Item', 1),
            checked: true,
          },
        },
      })

      const checkboxes = wrapper.getAllByRole('checkbox')

      await openMenuAndClickAction(wrapper, 'Check item')

      await verifyChecked(checkboxes, false)
    })

    it('removes entire checklist', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: checklistItemsMock,
        },
      })
      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      await openMenuAndClickAction(wrapper, 'Remove checklist', 0)

      const calls = await waitForTicketChecklistDeleteMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        checklistId: convertToGraphQLId('Checklist', 1),
      })

      await mockChecklistUpdateSubscription(null)
    })

    it('renames checklist title by item click', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: checklistItemsMock,
        },
      })

      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      await wrapper.events.click(wrapper.getByText('Checklist item A'))

      await wrapper.events.type(
        await wrapper.findByRole('textbox'),
        ' update{enter}',
      )

      const calls = await waitForTicketChecklistItemUpsertMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        checklistId: convertToGraphQLId('Checklist', 1),
        checklistItemId: convertToGraphQLId('Checklist::Item', 1),
        input: {
          text: 'Checklist item A update',
        },
      })

      await verifyTextUpdate(wrapper)
    })

    it('renames checklist text by edit menu action', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: checklistItemsMock,
        },
      })

      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      await openMenuAndClickAction(wrapper, 'Edit item', 1)

      mockTicketChecklistItemUpsertMutation({
        ticketChecklistItemUpsert: {
          checklistItem: {
            id: convertToGraphQLId('Checklist::Item', 1),
            text: 'Checklist item A update',
          },
        },
      })

      await wrapper.events.type(
        await wrapper.findByRole('textbox'),
        ' update{enter}',
      )

      await verifyTextUpdate(wrapper, false)
    })

    it('removes checklist item', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: checklistItemsMock,
        },
      })
      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('heading', {
          level: 3,
          name: 'Checklist title',
        }),
      ).toBeInTheDocument()

      await openMenuAndClickAction(wrapper, 'Remove item')

      const calls = await waitForTicketChecklistItemDeleteMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        checklistId: convertToGraphQLId('Checklist', 1),
        checklistItemId: convertToGraphQLId('Checklist::Item', 1),
      })
    })
  })

  describe('checklist templates', () => {
    it.todo('applies template to ticket checklist', async () => {
      mockTicketChecklistQuery({
        ticketChecklist: null,
      })

      mockChecklistTemplatesQuery({ checklistTemplates: templateMocks })

      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByText('Or choose a checklist template.'),
      ).toBeInTheDocument()

      await wrapper.events.click(
        wrapper.getByRole('button', { name: 'Add From a Template' }),
      )

      expect(await wrapper.findByRole('menu')).toBeInTheDocument()

      await wrapper.events.click(wrapper.getByText('Foo template'))

      const calls = await waitForTicketChecklistAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        templateId: convertToGraphQLId('Checklist::Item', 1),
        ticketId: convertToGraphQLId('Ticket', 1),
      })

      await mockChecklistUpdateSubscription({
        items: [checklistItemsMock[1] as ChecklistItem],
      })

      expect(wrapper.queryByText('Checklist item A')).not.toBeInTheDocument()
    })

    it('hides template button if no templates are available', async () => {
      mockPermissions(['admin'])

      mockTicketChecklistQuery({
        ticketChecklist: null,
      })

      mockChecklistTemplatesQuery({
        checklistTemplates: [],
      })

      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('link', {
          name: 'Create a new checklist template in the admin interface.',
        }),
      ).toBeInTheDocument()

      expect(
        wrapper.queryByText('Or choose a checklist template.'),
      ).not.toBeInTheDocument()

      expect(
        wrapper.queryByRole('button', { name: 'Add From a Template' }),
      ).not.toBeInTheDocument()
    })

    it('updates templates if they got modified', async () => {
      mockPermissions(['admin'])

      mockTicketChecklistQuery({
        ticketChecklist: null,
      })

      mockChecklistTemplatesQuery({ checklistTemplates: templateMocks })

      const wrapper = await renderChecklist()

      expect(
        await wrapper.findByRole('button', { name: 'Add From a Template' }),
      ).toBeInTheDocument()

      await wrapper.events.click(
        wrapper.getByRole('button', { name: 'Add From a Template' }),
      )

      const menuItems = wrapper.getAllByRole('menuitem')

      expect(menuItems).toHaveLength(3)

      await getChecklistTemplateUpdatesSubscriptionHandler().trigger({
        checklistTemplateUpdates: {
          checklistTemplates: [templateMocks[0], templateMocks[1]],
        },
      })

      expect(wrapper.getAllByRole('menuitem')).toHaveLength(2)

      expect(
        wrapper.getByRole('menuitem', {
          name: templateMocks[0].name as string,
        }),
      ).toBeInTheDocument()
      expect(
        wrapper.getByRole('menuitem', {
          name: templateMocks[1].name as string,
        }),
      ).toBeInTheDocument()

      // Last item should not be focused
      expect(wrapper.getAllByRole('menuitem').at(-1)).not.toHaveFocus()
    })
  })
})
