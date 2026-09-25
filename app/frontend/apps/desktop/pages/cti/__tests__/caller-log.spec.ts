// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockCtiLogDoneUpdateMutation,
  mockCtiLogDoneUpdateMutationError,
  waitForCtiLogDoneUpdateMutationCalls,
} from '#desktop/entities/cti/graphql/mutations/ctiLogDoneUpdate.mocks.ts'

import { mockCtiLogsQuery, mockCtiLogsQueryError } from '../graphql/queries/ctiLogs.mocks.ts'

import {
  callerLogEntries,
  callFromUnknown,
  checkedCall,
  missedCall,
  mockUserCreateFlyoutQueries,
} from './mocks/caller-log-mocks.ts'

import type { CallerLogEntry } from '../types.ts'

const mockCallerLog = (entries: CallerLogEntry[]) =>
  mockCtiLogsQuery({
    ctiLogs: {
      totalCount: entries.length,
      edges: entries.map((node) => ({ node, cursor: node.id })),
      pageInfo: { endCursor: entries.at(-1)?.id ?? null, hasNextPage: false },
    },
  })

describe('Caller log', () => {
  beforeEach(() => {
    mockPermissions(['cti.agent'])
    mockApplicationConfig({ cti_integration: true, user_name_format: 'first_last' })
  })

  it('renders the first page of the caller log', async () => {
    mockCallerLog(callerLogEntries)

    const view = await visitView('/cti')

    expect(await view.findByRole('table', { name: 'Caller log' })).toBeInTheDocument()

    const table = within(view.getByRole('table', { name: 'Caller log' }))

    // One header row plus one row per entry.
    expect(table.getAllByRole('row')).toHaveLength(callerLogEntries.length + 1)

    expect(table.getAllByText('Franz Bauer').length).toBeGreaterThan(0)
    expect(table.getByText('Not reached')).toBeInTheDocument()
    expect(table.getAllByRole('link', { name: '+49 30 609854180' })[0]).toHaveAttribute(
      'href',
      'tel:4930609854180',
    )
  })

  it('shows an empty state without calls', async () => {
    mockCallerLog([])

    const view = await visitView('/cti')

    expect(await view.findByText('Empty caller log')).toBeInTheDocument()
    expect(view.getByText('No calls to process.')).toBeInTheDocument()
    expect(view.queryByRole('table')).not.toBeInTheDocument()
  })

  it('shows an error state when the caller log cannot be loaded', async () => {
    mockCtiLogsQueryError('Something went wrong', { type: GraphQLErrorTypes.UnknownError })

    const view = await visitView('/cti')

    expect(await view.findByText('Caller log unavailable')).toBeInTheDocument()
    expect(
      view.getByText('The caller log could not be loaded. Please try again later.'),
    ).toBeInTheDocument()
    expect(view.queryByRole('table')).not.toBeInTheDocument()
  })

  describe('without a configured CTI backend', () => {
    beforeEach(() => {
      mockApplicationConfig({
        cti_integration: false,
        sipgate_integration: false,
        placetel_integration: false,
      })
    })

    it('lists the supported backends as plain text for an agent', async () => {
      const view = await visitView('/cti')

      expect(
        await view.findByText('Sorry, there is currently no CTI backend enabled.'),
      ).toBeInTheDocument()
      expect(view.getByText('These are supported:')).toBeInTheDocument()

      expect(view.getByText('CTI (generic)')).toBeInTheDocument()
      expect(view.getByText('sipgate.io')).toBeInTheDocument()
      expect(view.getByText('Placetel')).toBeInTheDocument()

      expect(view.queryByRole('link', { name: 'CTI (generic)' })).not.toBeInTheDocument()
      expect(view.queryByRole('table')).not.toBeInTheDocument()
    })

    it('links the supported backends for an admin', async () => {
      mockPermissions(['cti.agent', 'admin.integration'])

      const view = await visitView('/cti')

      expect(
        await view.findByText('Sorry, there is currently no CTI backend enabled.'),
      ).toBeInTheDocument()

      expect(view.getByRole('link', { name: 'CTI (generic)' })).toHaveAttribute(
        'href',
        '/#system/integration/cti',
      )
      expect(view.getByRole('link', { name: 'sipgate.io' })).toHaveAttribute(
        'href',
        '/#system/integration/sipgate',
      )
      expect(view.getByRole('link', { name: 'Placetel' })).toHaveAttribute(
        'href',
        '/#system/integration/placetel',
      )
    })
  })

  it('prefills the phone number of an unknown caller in the user create flyout', async () => {
    mockPermissions(['cti.agent', 'ticket.agent'])

    mockCallerLog([callFromUnknown])
    mockUserCreateFlyoutQueries()

    const view = await visitView('/cti')

    const table = within(await view.findByRole('table', { name: 'Caller log' }))

    await view.events.click(table.getByRole('button', { name: 'New user' }))

    const flyout = await view.findByRole('complementary', { name: 'New user' })

    expect(await within(flyout).findByLabelText('Phone')).toHaveValue(callFromUnknown.fromPretty)
  })

  describe('marking a call as handled', () => {
    it('marks an open call as handled', async () => {
      mockCallerLog([missedCall])
      mockCtiLogDoneUpdateMutation({ ctiLogDoneUpdate: { log: { id: missedCall.id, done: true } } })

      const view = await visitView('/cti')

      const table = within(await view.findByRole('table', { name: 'Caller log' }))

      await view.events.click(table.getByRole('checkbox', { name: 'Mark as handled' }))

      expect(table.getByRole('checkbox', { name: 'Mark as not handled' })).toBeInTheDocument()

      const calls = await waitForCtiLogDoneUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ id: missedCall.id, done: true })
    })

    it('marks a handled call as not handled', async () => {
      mockCallerLog([checkedCall])
      mockCtiLogDoneUpdateMutation({
        ctiLogDoneUpdate: { log: { id: checkedCall.id, done: false } },
      })

      const view = await visitView('/cti')

      const table = within(await view.findByRole('table', { name: 'Caller log' }))

      await view.events.click(table.getByRole('checkbox', { name: 'Mark as not handled' }))

      expect(table.getByRole('checkbox', { name: 'Mark as handled' })).toBeInTheDocument()
    })

    it('restores the checkbox and notifies when the call could not be updated', async () => {
      mockCallerLog([missedCall])
      mockCtiLogDoneUpdateMutationError('Something went wrong', {
        type: GraphQLErrorTypes.UnknownError,
      })

      const view = await visitView('/cti')

      const table = within(await view.findByRole('table', { name: 'Caller log' }))

      await view.events.click(table.getByRole('checkbox', { name: 'Mark as handled' }))

      expect(await table.findByRole('checkbox', { name: 'Mark as handled' })).toBeInTheDocument()
      expect(view.getByText('The call could not be updated.')).toBeInTheDocument()
    })
  })

  it('treats any of the three backends as configured', async () => {
    mockApplicationConfig({
      cti_integration: false,
      sipgate_integration: false,
      placetel_integration: true,
    })
    mockCallerLog([missedCall])

    const view = await visitView('/cti')

    expect(await view.findByRole('table', { name: 'Caller log' })).toBeInTheDocument()
    expect(
      view.queryByText('Sorry, there is currently no CTI backend enabled.'),
    ).not.toBeInTheDocument()
  })
})
