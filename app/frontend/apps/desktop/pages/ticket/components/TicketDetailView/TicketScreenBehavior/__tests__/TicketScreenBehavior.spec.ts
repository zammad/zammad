// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'

import { waitForUserCurrentTicketScreenBehaviorMutationCalls } from '#desktop/entities/user/current/graphql/mutations/userCurrentTicketScreenBehavior.mocks.ts'
import TicketScreenBehavior from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/TicketScreenBehavior.vue'

const renderTicketScreenBehavior = () => renderComponent(TicketScreenBehavior)

describe('TicketScreenBehavior', () => {
  it('displays a list of screen behavior options', async () => {
    mockUserCurrent({
      preferences: {
        secondaryAction: EnumTicketScreenBehavior.StayOnTab,
      },
    })
    const wrapper = renderTicketScreenBehavior()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Stay on tab' }),
    )

    const menu = await wrapper.findByRole('menu')

    const uncheckedCheckboxes = within(menu).getAllByRole('checkbox', {
      checked: false,
    })

    expect(uncheckedCheckboxes.length).toBe(2)
    expect(menu).toHaveTextContent('Close tab')
    expect(menu).toHaveTextContent('Close tab on ticket close')
    // :TODO Add this option as soon as overview is implemented
    // expect(menu).toHaveTextContent('Next in overview')

    expect(
      within(menu).getByRole('checkbox', { checked: true }),
    ).toHaveTextContent('Stay on tab')
  })

  it('displays as a selected default ticket_secondary_action from config', async () => {
    mockUserCurrent({
      preferences: {
        secondaryAction: null,
      },
    })

    await mockApplicationConfig({
      ticket_secondary_action: EnumTicketScreenBehavior.CloseTab,
    })

    const wrapper = renderTicketScreenBehavior()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Close tab' }),
    )

    const menu = await wrapper.findByRole('menu')

    expect(
      within(menu).getByRole('checkbox', { checked: true }),
    ).toHaveTextContent('Close tab')
  })

  it('defaults to stay on tab if other application config and user preferences are not set', async () => {
    mockUserCurrent({
      preferences: {
        secondaryAction: undefined,
      },
    })

    mockApplicationConfig({
      ticket_secondary_action: undefined,
    })

    const wrapper = renderTicketScreenBehavior()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Stay on tab' }),
    )

    const menu = await wrapper.findByRole('menu')

    expect(
      within(menu).getByRole('checkbox', { checked: true }),
    ).toHaveTextContent('Stay on tab')
  })

  it('updates screen behavior if option is selected', async () => {
    const wrapper = renderTicketScreenBehavior()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Stay on tab' }),
    )

    const menu = await wrapper.findByRole('menu')

    await wrapper.events.click(
      within(menu).getByRole('checkbox', { name: 'check2 Close tab' }),
    )

    const calls = await waitForUserCurrentTicketScreenBehaviorMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      behavior: EnumTicketScreenBehavior.CloseTab,
    })
  })
})
