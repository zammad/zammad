// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockTodaysTicketsQuery } from '../graphql/queries/todaysTickets.mocks.ts'
import Dashboard from '../views/Dashboard.vue'

const renderDashboard = async () => {
  const wrapper = renderComponent(Dashboard, {
    store: true,
    router: true,
  })

  await waitForNextTick()

  return wrapper
}

describe('Dashboard', () => {
  beforeEach((context) => {
    context.skipConsole = true
    
    mockTodaysTicketsQuery({
      todaysTickets: []
    })
  })

  describe('dashboard layout', () => {
    it('renders dashboard welcome section', async () => {
      const wrapper = await renderDashboard()

      expect(wrapper.getByText('Welcome back, %s!')).toBeInTheDocument()
      expect(wrapper.getByText("Here's what's happening with your tickets today.")).toBeInTheDocument()
    })

    it('displays dashboard grid layout', async () => {
      const wrapper = await renderDashboard()

      const gridContainer = wrapper.container.querySelector('.grid')
      expect(gridContainer).toBeInTheDocument()
    })

    it('renders TodaysTicketsWidget component', async () => {
      const wrapper = await renderDashboard()

      expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
    })
  })

  describe('quick actions section', () => {
    it('renders quick actions header', async () => {
      const wrapper = await renderDashboard()

      expect(wrapper.getByText('Quick Actions')).toBeInTheDocument()
    })

    it('displays action buttons', async () => {
      const wrapper = await renderDashboard()

      const buttons = wrapper.container.querySelectorAll('button')
      expect(buttons.length).toBeGreaterThan(0)
    })

    it('renders without crashing when components are present', async () => {
      const wrapper = await renderDashboard()

      expect(wrapper.container).toBeInTheDocument()
      expect(wrapper.container.querySelector('.grid')).toBeInTheDocument()
    })
  })

  describe('component integration', () => {
    it('integrates TodaysTicketsWidget successfully', async () => {
      const wrapper = await renderDashboard()

      expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
      expect(wrapper.getByText('Auto-refresh every 30 seconds')).toBeInTheDocument()
    })

    it('handles empty dashboard state', async () => {
      const wrapper = await renderDashboard()

      expect(wrapper.container).toBeInTheDocument()
      expect(wrapper.getByText('Welcome back, %s!')).toBeInTheDocument()
    })
  })
})