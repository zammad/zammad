// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  mockUserQuery,
  waitForUserQueryCalls,
} from '#shared/entities/user/graphql/queries/user.mocks.ts'

import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { TicketSidebarScreenType } from '../../../../types/sidebar.ts'
import customerSidebarPlugin from '../../plugins/customer.ts'
import TicketSidebarCustomer from '../TicketSidebarCustomer.vue'

mockRouterHooks()
const renderTicketSidebarCustomer = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarCustomer, {
    props: {
      sidebar: 'customer',
      sidebarPlugin: customerSidebarPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        ...context,
      },
    },
    router: true,
    form: true,
    provide: [
      [
        TICKET_KEY,
        () => {
          const ticket = createDummyTicket()

          return {
            ticketId: computed(() => ticket.id),
            ticket: computed(() => ticket),
            form: ref(),
            showTicketArticleReplyForm: () => {},
            isTicketEditable: computed(() => true),
            newTicketArticlePresent: ref(false),
            ticketInternalId: computed(() => ticket.internalId),
          }
        },
      ],
    ],
    global: {
      stubs: {
        teleport: true,
      },
    },
    ...options,
  })

  if (context.formValues.customer_id) await waitForUserQueryCalls()

  await waitForNextTick()

  return result
}

describe('TicketSidebarCustomer.vue', () => {
  it('shows sidebar when customer ID is present', async () => {
    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)
  })

  it('does not show sidebar when customer ID is absent', async () => {
    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: null,
      },
    })

    expect(wrapper.emitted('show')).toBeUndefined()
  })

  it('hides sidebar when customer got removed', async () => {
    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)

    await wrapper.rerender({
      context: {
        formValues: {
          customer_id: null,
        },
      },
    })

    expect(wrapper.emitted('hide')).toHaveLength(1)
  })

  it.each([
    { open: 1, alarming: false },
    { open: 2, alarming: true },
    { open: 100, alarming: true },
  ])(
    'displays badge with open ticket count (open=$open, alarming=$alarming)',
    async ({ open, alarming }) => {
      mockUserQuery({
        user: {
          ticketsCount: {
            open,
          },
        },
      })

      const wrapper = await renderTicketSidebarCustomer({
        formValues: {
          customer_id: 1,
        },
      })

      const badge = wrapper.getByRole('status', { name: 'Open tickets' })

      const count = open < 100 ? open.toString() : '99+'

      expect(badge).toHaveTextContent(count)

      if (alarming) expect(badge).toHaveClasses(['bg-pink-500', 'text-white'])
      else expect(badge).not.toHaveClasses(['bg-pink-500', 'text-white'])
    },
  )
})
