// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  mockMacrosQuery,
  waitForMacrosQueryCalls,
} from '#shared/graphql/queries/macros.mocks.ts'
import { getMacrosUpdateSubscriptionHandler } from '#shared/graphql/subscriptions/macrosUpdate.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketDetailBottomBar, {
  type Props,
} from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar.vue'

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticket: ref(createDummyTicket()),
  }),
}))

const renderTicketSideBarBottomBar = (props?: Partial<Props>) =>
  renderComponent(TicketDetailBottomBar, {
    props: {
      disabled: false,
      formNodeId: 'form-node-id-test',
      dirty: false,
      canUpdateTicket: true,
      groupId: convertToGraphQLId('Group', 2),
      ...props,
    },
    store: true,
  })

describe('TicketSideBarBottomBar', () => {
  it('renders submit button if form node id is provided', () => {
    const wrapper = renderTicketSideBarBottomBar()

    expect(wrapper.getByRole('button', { name: 'Update' })).toBeInTheDocument()
  })

  it('renders discard unsaved changes button if dirty prop is true', async () => {
    const wrapper = renderTicketSideBarBottomBar({
      dirty: true,
    })

    expect(
      wrapper.queryByRole('button', { name: 'Discard your unsaved changes' }),
    ).toBeInTheDocument()

    await wrapper.rerender({
      dirty: false,
    })

    expect(
      wrapper.queryByRole('button', { name: 'Discard your unsaved changes' }),
    ).not.toBeInTheDocument()
  })

  it('should disable buttons if disabled prop is true', () => {
    const wrapper = renderTicketSideBarBottomBar({
      dirty: true,
      disabled: true,
    })

    expect(wrapper.getByRole('button', { name: 'Update' })).toBeDisabled()

    expect(
      wrapper.queryByRole('button', { name: 'Discard your unsaved changes' }),
    ).toBeDisabled()
  })

  it.each(['submit', 'discard'])(
    'emits %s event when button is clicked',
    async (eventName) => {
      const wrapper = renderTicketSideBarBottomBar({
        formNodeId: 'form-node-id-test',
        dirty: true,
        disabled: false,
      })

      if (eventName === 'submit') {
        await wrapper.events.click(
          wrapper.getByRole('button', { name: 'Update' }),
        )

        expect(wrapper.emitted('submit')).toBeTruthy()
      }

      if (eventName === 'discard') {
        await wrapper.events.click(
          wrapper.getByRole('button', { name: 'Discard your unsaved changes' }),
        )

        expect(wrapper.emitted('discard')).toBeTruthy()
      }
    },
  )

  it('displays action menu button for macros for agent with update permission', async () => {
    mockMacrosQuery({
      macros: [
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 1),
          active: true,
          name: 'Macro 1',
          uxFlowNextUp: 'next_task',
        },
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 2),
          active: true,
          name: 'Macro 2',
          uxFlowNextUp: 'next_task',
        },
      ],
    })

    const wrapper = renderTicketSideBarBottomBar()

    const actionMenu = await wrapper.findByLabelText('Action menu button')

    await wrapper.events.click(actionMenu)

    const menu = await wrapper.findByRole('menu')

    expect(menu).toBeInTheDocument()

    expect(within(menu).getByText('Macros')).toBeInTheDocument()

    expect(within(menu).getByText('Macro 1')).toBeInTheDocument()

    expect(within(menu).getByText('Macro 2')).toBeInTheDocument()
  })

  it('hides action menu, submit and cancel buttons for agent without update permission', async () => {
    const wrapper = renderTicketSideBarBottomBar({
      canUpdateTicket: false,
    })

    expect(
      wrapper.queryByRole('button', { name: 'Update' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByRole('button', { name: 'Discard your unsaved changes' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByLabelText('Action menu button'),
    ).not.toBeInTheDocument()
  })

  it('reloads macro query if subscription is triggered', async () => {
    mockMacrosQuery({
      macros: [],
    })

    renderTicketSideBarBottomBar()

    const calls = await waitForMacrosQueryCalls()

    expect(calls?.at(-1)?.variables).toEqual({
      groupId: convertToGraphQLId('Group', 2),
    })

    await getMacrosUpdateSubscriptionHandler().trigger({
      macrosUpdate: {
        macroUpdated: true,
      },
    })

    mockMacrosQuery({
      macros: [
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 1),
          active: true,
          name: 'Macro 1',
          uxFlowNextUp: 'next_task',
        },
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 2),
          active: true,
          name: 'Macro updated',
          uxFlowNextUp: 'next_task',
        },
      ],
    })

    expect(calls.length).toBe(2)
  })

  it('submits event if macro is clicked', async () => {
    mockMacrosQuery({
      macros: [
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 1),
          active: true,
          name: 'Macro 1',
          uxFlowNextUp: 'next_task',
        },
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 2),
          active: true,
          name: 'Macro 2',
          uxFlowNextUp: 'next_task',
        },
      ],
    })

    const wrapper = renderTicketSideBarBottomBar()

    const actionMenu = await wrapper.findByLabelText('Action menu button')

    await wrapper.events.click(actionMenu)

    const menu = await wrapper.findByRole('menu')

    await wrapper.events.click(within(menu).getByText('Macro 1'))

    expect(wrapper.emitted('execute-macro')).toEqual([
      [
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 1),
          active: true,
          name: 'Macro 1',
          uxFlowNextUp: 'next_task',
        },
      ],
    ])
  })

  it('hides macros if there is no group id', async () => {
    const wrapper = renderTicketSideBarBottomBar({
      groupId: undefined,
    })

    expect(
      wrapper.queryByLabelText('Action menu button'),
    ).not.toBeInTheDocument()
  })
})
