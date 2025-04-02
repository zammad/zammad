// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  mockMacrosQuery,
  waitForMacrosQueryCalls,
} from '#shared/graphql/queries/macros.mocks.ts'
import { getMacrosUpdateSubscriptionHandler } from '#shared/graphql/subscriptions/macrosUpdate.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketDetailBottomBar, {
  type Props,
} from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar/TicketDetailBottomBar.vue'

import liveUserList from './mocks/live-user-list.json'

const ticket = createDummyTicket()

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticket: ref(ticket),
  }),
}))

const renderTicketDetailBottomBar = (props?: Partial<Props>) =>
  renderComponent(TicketDetailBottomBar, {
    props: {
      disabled: false,
      dirty: false,
      isTicketEditable: true,
      groupId: convertToGraphQLId('Group', 2),
      liveUserList: [],
      ticketId: ticket.id,
      isTicketAgent: true,
      ...props,
    },
    store: true,
    router: true,
  })

describe('TicketDetailBottomBar', () => {
  it('renders submit button if form node id is provided', () => {
    const wrapper = renderTicketDetailBottomBar()

    expect(wrapper.getByRole('button', { name: 'Update' })).toBeInTheDocument()
  })

  it('renders discard unsaved changes button if dirty prop is true', async () => {
    const wrapper = renderTicketDetailBottomBar({
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
    const wrapper = renderTicketDetailBottomBar({
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
      const wrapper = renderTicketDetailBottomBar({
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

  describe('Drafts', () => {
    it.todo('should not display draft information if ticket has no draft')
    it.todo('should display draft information if ticket has a draft')
  })

  describe('Macros', () => {
    it('displays action menu button for macros for agent with update permission', async () => {
      mockPermissions(['ticket.agent'])

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

      const wrapper = renderTicketDetailBottomBar()

      const actionMenu = await wrapper.findByLabelText(
        'Additional ticket edit actions',
      )

      await wrapper.events.click(actionMenu)

      const menu = await wrapper.findByRole('menu')

      expect(menu).toBeInTheDocument()
      expect(within(menu).getByText('Macros')).toBeInTheDocument()
      expect(within(menu).getByText('Macro 1')).toBeInTheDocument()
      expect(within(menu).getByText('Macro 2')).toBeInTheDocument()
    })

    it('hides action menu, submit and cancel buttons for agent without update permission', async () => {
      const wrapper = renderTicketDetailBottomBar({
        isTicketEditable: false,
      })

      expect(
        wrapper.queryByRole('button', { name: 'Update' }),
      ).not.toBeInTheDocument()

      expect(
        wrapper.queryByRole('button', { name: 'Discard your unsaved changes' }),
      ).not.toBeInTheDocument()

      expect(
        wrapper.queryByLabelText('Additional ticket edit actions'),
      ).not.toBeInTheDocument()
    })

    it('reloads macro query if subscription is triggered', async () => {
      mockMacrosQuery({
        macros: [],
      })

      renderTicketDetailBottomBar()

      const calls = await waitForMacrosQueryCalls()

      expect(calls?.at(-1)?.variables).toEqual({
        groupIds: [convertToGraphQLId('Group', 2)],
      })

      await waitForNextTick()

      await getMacrosUpdateSubscriptionHandler().trigger({
        macrosUpdate: {
          macroId: convertToGraphQLId('Macro', 1),
          groupIds: [],
          removeMacroId: null,
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
      mockPermissions(['ticket.agent'])

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

      const wrapper = renderTicketDetailBottomBar()

      const actionMenu = await wrapper.findByLabelText(
        'Additional ticket edit actions',
      )

      await wrapper.events.click(actionMenu)

      const menu = await wrapper.findByRole('menu')

      expect(within(menu).getByRole('menuitem')).toBeInTheDocument()

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
      const wrapper = renderTicketDetailBottomBar({
        groupId: undefined,
      })

      const addonButton = wrapper.getByRole('button', {
        name: 'Additional ticket edit actions',
      })

      await wrapper.events.click(addonButton)

      expect(
        within(wrapper.getByRole('menu')).queryByRole('menuitem'),
      ).not.toBeInTheDocument()
    })
  })

  describe('Live Users', () => {
    it('shows live user information as avatars', async () => {
      const wrapper = renderTicketDetailBottomBar({
        liveUserList: liveUserList as TicketLiveAppUser[],
      })

      expect(
        wrapper.getByRole('img', { name: 'Avatar (Nicole Braun) (VIP)' }),
      ).toBeInTheDocument()

      expect(
        wrapper.getByRole('img', { name: 'Avatar (Test Admin Agent)' }),
      ).toBeInTheDocument()

      expect(
        wrapper.getByRole('img', { name: 'Avatar (Agent 1 Test)' }),
      ).toBeInTheDocument()

      expect(
        wrapper.getByRole('img', { name: 'Avatar (Agent 2 Test)' }),
      ).toBeInTheDocument()
    })
  })
})
