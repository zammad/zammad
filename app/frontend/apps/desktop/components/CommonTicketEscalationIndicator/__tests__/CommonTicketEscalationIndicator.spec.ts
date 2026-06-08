// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import CommonTicketEscalationIndicator from '../CommonTicketEscalationIndicator.vue'

describe('CommonTicketEscalationIndicator.vue', () => {
  it('renders running escalation correctly', () => {
    const ticket = createDummyTicket({
      escalationAt: new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 35).toISOString(),
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    const alert = view.getByRole('alert')

    expect(alert).toHaveClass('common-badge-danger')
    expect(alert).toHaveTextContent('escalation 1 month ago')
  })

  it('renders warning escalation correctly', () => {
    const ticket = createDummyTicket({
      escalationAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    const alert = view.getByRole('alert')

    expect(alert).toHaveClass('common-badge-warning')
    expect(alert).toHaveTextContent('escalation in 1 month')
  })

  it('renders unknown escalation correctly', () => {
    const ticket = createDummyTicket({
      escalationAt: 'foobar',
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('renders undefined escalation correctly', () => {
    const ticket = createDummyTicket({
      escalationAt: undefined,
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('renders first response escalation correctly', async () => {
    const firstResponseEscalationAt = new Date(
      new Date().getTime() + 1000 * 60 * 60 * 24 * 35,
    ).toISOString()

    const ticket = createDummyTicket({
      escalationAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
      firstResponseEscalationAt,
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    await view.events.hover(
      view.getByRole('button', { name: 'Show ticket escalation information' }),
    )

    const popover = await view.findByRole('region')

    expect(within(popover).getByText('Escalation times')).toBeVisible()

    const container = within(popover).getByLabelText('First response time')

    expect(within(container).getByText('First response time')).toBeVisible()
    expect(within(container).getByText('in 1 month')).toBeVisible()
  })

  it('renders update escalation correctly', async () => {
    const updateEscalationAt = new Date(
      new Date().getTime() + 1000 * 60 * 60 * 24 * 35,
    ).toISOString()

    const ticket = createDummyTicket({
      escalationAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
      updateEscalationAt,
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    await view.events.hover(
      view.getByRole('button', { name: 'Show ticket escalation information' }),
    )

    const popover = await view.findByRole('region')

    expect(within(popover).getByText('Escalation times')).toBeVisible()

    const container = within(popover).getByLabelText('Update time')

    expect(within(container).getByText('Update time')).toBeVisible()
    expect(within(container).getByText('in 1 month')).toBeVisible()
  })

  it('renders solution escalation correctly', async () => {
    const closeEscalationAt = new Date(
      new Date().getTime() + 1000 * 60 * 60 * 24 * 35,
    ).toISOString()

    const ticket = createDummyTicket({
      escalationAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
      closeEscalationAt,
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    await view.events.hover(
      view.getByRole('button', { name: 'Show ticket escalation information' }),
    )

    const popover = await view.findByRole('region')

    expect(within(popover).getByText('Escalation times')).toBeVisible()

    const container = within(popover).getByLabelText('Solution time')

    expect(within(container).getByText('Solution time')).toBeVisible()
    expect(within(container).getByText('in 1 month')).toBeVisible()
  })

  it('renders multiple escalations correctly', async () => {
    const ticket = createDummyTicket({
      escalationAt: new Date('2023-02-28 13:00:00').toISOString(),
      firstResponseEscalationAt: new Date('2023-02-28 13:00:00').toISOString(),
      closeEscalationAt: new Date('2023-02-28 15:00:00').toISOString(),
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket, hasPopover: true },
    })

    await view.events.hover(
      view.getByRole('button', { name: 'Show ticket escalation information' }),
    )

    await view.events.hover(
      view.getByRole('button', { name: 'Show ticket escalation information' }),
    )

    const popover = await view.findByRole('region')

    expect(within(popover).getByText('Escalation times')).toBeVisible()
    expect(within(popover).queryByLabelText('First response time')).toBeInTheDocument()
    expect(within(popover).queryByLabelText('Update time')).not.toBeInTheDocument()
    expect(within(popover).queryByLabelText('Solution time')).toBeInTheDocument()
  })

  it('renders no popover when hasPopover is false', async () => {
    const ticket = createDummyTicket({
      escalationAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
      closeEscalationAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
    })

    const view = renderComponent(CommonTicketEscalationIndicator, {
      props: { ticket },
    })

    expect(
      view.queryByRole('button', { name: 'Show ticket escalation information' }),
    ).not.toBeInTheDocument()

    const alert = view.getByRole('alert')

    expect(alert).toHaveClass('common-badge-warning')
    expect(alert).toHaveTextContent('escalation in 1 month')
  })
})
