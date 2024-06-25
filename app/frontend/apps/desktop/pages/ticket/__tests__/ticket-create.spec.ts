// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { waitForTicketCreateMutationCalls } from '#shared/entities/ticket/graphql/mutations/create.mocks.ts'

import {
  handleMockUserQuery,
  handleCustomerMock,
  handleMockFormUpdaterQuery,
  rendersFields,
} from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'

vi.hoisted(() => {
  vi.setSystemTime('2024-11-11T00:00:00Z')
})

describe('ticket create view', async () => {
  describe('view with denied access', async () => {
    beforeEach(() => {
      mockApplicationConfig({
        customer_ticket_create: false,
      })
      mockPermissions(['ticket.customer'])
    })

    it('redirects to error page', async () => {
      const view = await visitView('/ticket/create')
      // :TODO adapt as soon as we have real error page
      expect(view.getByText('ERROR XYZ')).toBeInTheDocument()
    })
  })

  describe('view with granted access', async () => {
    beforeEach(() => {
      mockApplicationConfig({
        ui_ticket_create_available_types: [
          'phone-in',
          'phone-out',
          'email-out',
        ],
        customer_ticket_create: true,
      })
      mockPermissions(['ticket.agent'])
    })

    it('renders view correctly', async () => {
      const view = await visitView('/ticket/create')

      expect(
        await view.findByRole('heading', { level: 1, name: 'New Ticket' }),
      ).toBeInTheDocument()

      expect(view.getByRole('tablist')).toBeInTheDocument()

      // Default tab is the first one
      expect(
        view.getByRole('tab', { selected: true, name: 'Received Call' }),
      ).toBeInTheDocument()

      rendersFields(view)
    })

    it('cancels ticket creation', async () => {
      const view = await visitView('/ticket/create')

      expect(
        await view.findByRole('heading', { level: 1, name: 'New Ticket' }),
      ).toBeInTheDocument()

      await view.events.click(
        view.getByRole('button', { name: 'Cancel & Go Back' }),
      )

      await waitFor(() =>
        expect(
          view.queryByRole('heading', { level: 1, name: 'New Ticket' }),
        ).not.toBeInTheDocument(),
      )
    })

    it('shows send email article type', async () => {
      const view = await visitView('/ticket/create')

      await view.events.click(view.getByText('Send Email'))

      expect(
        view.getByRole('tab', { selected: true, name: 'Send Email' }),
      ).toBeInTheDocument()
      expect(view.getByRole('combobox', { name: 'CC' })).toBeInTheDocument()
      rendersFields(view)
    })

    it('shows outbound call article type', async () => {
      const view = await visitView('/ticket/create')

      await view.events.click(view.getByText('Outbound Call'))

      expect(
        view.getByRole('tab', { selected: true, name: 'Outbound Call' }),
      ).toBeInTheDocument()
      rendersFields(view)
    })

    it('detects duplicate ticket', async () => {
      await mockApplicationConfig({
        ticket_duplicate_detection: true,
        ticket_duplicate_detection_title: 'Similar tickets found',
        ticket_duplicate_detection_body:
          'Tickets with the same attributes were found.',
      })

      handleMockFormUpdaterQuery({
        ticket_duplicate_detection: {
          show: true,
          hidden: false,
          value: { count: 1, items: [[1, '123,', 'foo title']] },
        },
      })

      const view = await visitView('/ticket/create')

      await view.events.type(view.getByLabelText('Title'), 'foo title')

      await waitFor(() =>
        expect(view.getByText('Similar tickets found')).toBeInTheDocument(),
      )

      expect(view.getByTestId('common-alert')).toHaveTextContent('foo title')

      expect(view.getByIconName('exclamation-triangle')).toBeInTheDocument()

      expect(
        view.getByText('Tickets with the same attributes were found.'),
      ).toBeInTheDocument()
    })

    it('prevents submission on incomplete form', async () => {
      handleMockFormUpdaterQuery()

      const view = await visitView('/ticket/create')

      await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

      await view.events.click(view.getByRole('button', { name: 'Create' }))

      expect(await view.findAllByText('This field is required.')).toHaveLength(
        4,
      )
    })

    it('discards unsaved changes', async () => {
      handleMockFormUpdaterQuery()

      const view = await visitView('/ticket/create')

      expect(
        await view.findByRole('button', { name: 'Cancel & Go Back' }),
      ).toBeInTheDocument()

      await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

      await waitFor(() =>
        expect(
          view.queryByRole('button', { name: 'Cancel & Go Back' }),
        ).not.toBeInTheDocument(),
      )

      await view.events.click(
        await view.findByRole('button', { name: 'Discard Changes' }),
      )

      const dialog = await view.findByRole('dialog', {
        name: 'Unsaved Changes',
      })

      expect(dialog).toBeInTheDocument()

      const dialogView = within(dialog)

      expect(
        await dialogView.findByText(
          'Are you sure? You have unsaved changes that will get lost.',
        ),
      )

      await view.events.click(
        dialogView.getByRole('button', { name: 'Discard Changes' }),
      )

      // should not be in the document anymore
      await waitFor(() =>
        expect(view.getByLabelText('Title')).not.toHaveTextContent(
          'Test Ticket',
        ),
      )
    })

    it('keeps form values on cancel unsaved changes', async () => {
      handleMockFormUpdaterQuery()

      const view = await visitView('/ticket/create')

      await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

      await view.events.click(
        await view.findByRole('button', { name: 'Discard Changes' }),
      )

      const dialog = await view.findByRole('dialog', {
        name: 'Unsaved Changes',
      })

      const dialogView = within(dialog)

      await view.events.click(
        dialogView.getByRole('button', { name: 'Cancel & Go Back' }),
      )

      expect(view.getByText('Test Ticket')).toBeInTheDocument()
    })

    it('creates a new ticket', async () => {
      handleMockFormUpdaterQuery()

      const view = await visitView('/ticket/create')

      await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

      // Page title updates when title is set
      expect(
        await view.findByRole('heading', { level: 1, name: 'Test Ticket' }),
      ).toBeInTheDocument()

      // Page title defaults back when title is cleared
      await view.events.clear(view.getByLabelText('Title'))
      await waitFor(() =>
        expect(
          view.getByRole('heading', { level: 1, name: 'New Ticket' }),
        ).toBeInTheDocument(),
      )

      await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

      // Customer field
      await handleCustomerMock(view)

      handleMockUserQuery()

      await view.events.click(
        view.getByRole('option', {
          name: 'Avatar (Nicole Braun) Nicole Braun – Zammad Foundation',
        }),
      )

      // Sidebar
      expect(view.getByLabelText('Avatar (Nicole Braun)')).toBeInTheDocument()
      expect(view.getByText('Zammad Foundation')).toBeInTheDocument()
      expect(view.getByText('open tickets')).toBeInTheDocument()
      expect(view.getByText('nicole.braun@zammad.org')).toBeInTheDocument()
      expect(view.getByText('closed tickets')).toBeInTheDocument()
      expect(view.getByLabelText('Open tickets')).toHaveTextContent('17')

      // Text field
      await view.events.type(
        view.getByRole('textbox', { name: 'Text' }),
        'Test ticket text',
      )

      // Group field
      await view.events.click(view.getByRole('combobox', { name: 'Group' }))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      // State field
      await view.events.click(view.getByRole('combobox', { name: 'Priority' }))
      await view.events.click(view.getByRole('option', { name: '2 normal' }))

      // Priority Field
      await view.events.click(view.getByRole('combobox', { name: 'State' }))
      await view.events.click(
        view.getByRole('option', { name: 'pending reminder' }),
      )

      // Date selection Field ?
      await view.events.click(view.getByText('Pending till'))

      await waitFor(() => expect(view.getByRole('dialog')).toBeInTheDocument())

      const dateCells: Element[] = view.getAllByRole('gridcell', { name: '29' })

      await view.events.click(<Element>dateCells.at(-1))

      // Submission
      await view.events.click(view.getByRole('button', { name: 'Create' }))

      const calls = await waitForTicketCreateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          article: {
            body: 'Test ticket text',
            cc: undefined,
            contentType: 'text/html',
            security: undefined,
            sender: 'Customer',
            type: 'phone',
          },
          customer: {
            id: 'gid://zammad/User/2',
          },
          groupId: 'gid://zammad/Group/1',
          objectAttributeValues: [],
          pendingTime: '2024-11-29T00:00:00.000Z',
          priorityId: 'gid://zammad/Ticket::Priority/2',
          stateId: 'gid://zammad/Ticket::State/3',
          title: 'Test Ticket',
        },
      })

      await waitFor(() =>
        expect(
          view.getByText('Ticket has been created successfully.'),
        ).toBeInTheDocument(),
      )
    })
  })
})
