// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  ticketObjectAttributes,
  ticketArticleObjectAttributes,
  ticketPayload,
} from '@mobile/entities/ticket/__tests__/mocks/ticket-mocks'
import { defaultOrganization } from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import { FormUpdaterDocument } from '@shared/components/Form/graphql/queries/formUpdater.api'
import { ObjectManagerFrontendAttributesDocument } from '@shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api'
import { visitView } from '@tests/support/components/visitView'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { mockAccount } from '@tests/support/mock-account'
import type { ExtendedRenderResult } from '@tests/support/components'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { flushPromises } from '@vue/test-utils'
import { nullableMock, waitUntil } from '@tests/support/utils'
import { getTestRouter } from '@tests/support/components/renderComponent'
import { getNode } from '@formkit/core'
import { AutocompleteSearchUserDocument } from '@shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api'
import { TicketCreateDocument } from '../graphql/mutations/create.api'

const visitTicketCreate = async () => {
  const mockObjectAttributes = mockGraphQLApi(
    ObjectManagerFrontendAttributesDocument,
  ).willBehave(({ object }) => {
    if (object === 'Ticket') {
      return {
        data: {
          objectManagerFrontendAttributes: ticketObjectAttributes(),
        },
      }
    }

    return {
      data: {
        objectManagerFrontendAttributes: ticketArticleObjectAttributes(),
      },
    }
  })

  const mockFormUpdater = mockGraphQLApi(FormUpdaterDocument).willResolve({
    formUpdater: {
      group_id: {
        show: true,
        options: [
          {
            label: 'Users',
            value: 1,
          },
        ],
        clearable: true,
      },
      owner_id: {
        show: true,
        options: [{ value: 100, label: 'Max Mustermann' }],
      },
      priority_id: {
        show: true,
        options: [
          { value: 1, label: '1 low' },
          { value: 2, label: '2 normal' },
          { value: 3, label: '3 high' },
        ],
        clearable: true,
      },
      pending_time: {
        show: false,
        required: false,
        hidden: false,
        disabled: false,
      },
      state_id: {
        show: true,
        options: [
          { value: 4, label: 'closed' },
          { value: 2, label: 'open' },
          { value: 7, label: 'pending close' },
          { value: 3, label: 'pending reminder' },
        ],
        clearable: true,
      },
    },
  })

  const view = await visitView('/tickets/create')

  await flushPromises()
  await getNode('ticket-create')?.settled

  return { mockFormUpdater, mockObjectAttributes, view }
}

const mockTicketCreate = () => {
  return mockGraphQLApi(TicketCreateDocument).willResolve({
    ticketCreate: {
      ticket: ticketPayload(),
      errors: null,
      __typename: 'TicketCreatePayload',
    },
  })
}

const mockCustomerQueryResult = () => {
  return mockGraphQLApi(AutocompleteSearchUserDocument).willResolve({
    autocompleteSearchUser: [
      nullableMock({
        value: '2',
        label: 'Nicole Braun',
        labelPlaceholder: null,
        heading: 'Zammad Foundation',
        headingPlaceholder: null,
        disabled: null,
        icon: null,
        user: {
          id: 'gid://zammad/User/2',
          internalId: 2,
          firstname: 'Nicole',
          lastname: 'Braun',
          fullname: 'Nicole Braun',
          image: null,
          objectAttributeValues: [],
          organization: {
            id: 'gid://zammad/Organization/1',
            internalId: 1,
            name: 'Zammad Foundation',
            active: true,
            objectAttributeValues: [],
            __typename: 'Organization',
          },
          hasSecondaryOrganizations: false,
          __typename: 'User',
        },
        __typename: 'AutocompleteSearchUserEntry',
      }),
    ],
  })
}

const nextStep = async (view: ExtendedRenderResult) => {
  await view.events.click(view.getByRole('button', { name: 'Continue' }))
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import(
    '@shared/components/Form/fields/FieldEditor/FieldEditorInput.vue'
  )
})

describe('Creating new ticket as agent', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      customer_ticket_create: true,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      ui_ticket_create_default_type: 'phone-in',
    })
  })

  it('shows 4 steps for agents', async () => {
    const { view } = await visitTicketCreate()

    const steps = ['1', '2', '3', '4']
    steps.forEach((step) => {
      expect(view.getByRole('button', { name: step })).toBeInTheDocument()
    })
  })

  it('disables the submit button if required data is missing', async () => {
    const { view } = await visitTicketCreate()

    expect(view.getByRole('button', { name: 'Create ticket' })).toBeDisabled()
  })

  it('invalidates a single step if required data is missing', async () => {
    const { mockFormUpdater, view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')

    await waitUntil(() => mockFormUpdater.calls.resolve)

    await nextStep(view)
    await nextStep(view)
    await nextStep(view)

    expect(
      view.getByRole('status', { name: 'Invalid values in step 3' }),
    ).toBeInTheDocument()
  })

  it.each([
    { index: 0, button: 'arrow submit button' },
    { index: 1, button: 'text submit button' },
  ])(
    'redirects to detail view after successful ticket creation when clicked on $button',
    async ({ index }) => {
      const mockCustomer = mockCustomerQueryResult()
      const mockTicket = mockTicketCreate()

      const { mockFormUpdater, view } = await visitTicketCreate()

      await view.events.type(view.getByLabelText('Title'), 'Ticket Title')
      await waitUntil(() => mockFormUpdater.calls.resolve === 2)

      await nextStep(view)
      await nextStep(view)

      // Customer selection.
      await view.events.click(view.getByLabelText('Customer'))
      await view.events.type(await view.findByRole('searchbox'), 'nicole')

      await waitUntil(() => mockCustomer.calls.resolve)

      await view.events.click(view.getByText('Nicole Braun'))

      await waitUntil(() => mockFormUpdater.calls.resolve === 3)

      // Group selection.
      await view.events.click(view.getByLabelText('Group'))
      await view.events.click(view.getByText('Users'))
      await waitUntil(() => mockFormUpdater.calls.resolve === 4)

      await nextStep(view)

      // Text input.
      const editorNode = getNode('body')
      await editorNode?.input('Article body', false)

      // there is button with "arrow up" and actual button
      const submitButton = view.getAllByRole('button', {
        name: 'Create ticket',
      })[index]
      await waitUntil(() => !submitButton.hasAttribute('disabled'))

      expect(submitButton).not.toBeDisabled()

      // don't actually redirect
      const router = getTestRouter()
      router.mockMethods()

      await view.events.click(submitButton)

      await waitUntil(() => mockTicket.calls.resolve)

      await expect(view.findByRole('alert')).resolves.toHaveTextContent(
        'Ticket has been created successfully.',
      )

      expect(router.replace).toHaveBeenCalledWith('/tickets/1')
    },
  )

  it('shows confirm popup, when leaving', async () => {
    const { view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')

    // Wait on the changes
    await getNode('ticket-create')?.settled

    await view.events.click(view.getByRole('button', { name: 'Go back' }))

    expect(view.queryByTestId('popupWindow')).toBeInTheDocument()

    await expect(
      view.findByRole('alert', { name: 'Confirm dialog' }),
    ).resolves.toBeInTheDocument()
  })

  it('shows the CC field for type "Email"', async () => {
    const { mockFormUpdater, view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')
    await waitUntil(() => mockFormUpdater.calls.resolve)
    await nextStep(view)

    await view.events.click(view.getByLabelText('Send Email'))
    await nextStep(view)

    expect(view.getByLabelText('CC')).toBeInTheDocument()
  })

  // The rest of the test cases are covered by E2E test, due to limitations of JSDOM test environment.
})

describe('Creating new ticket as customer', () => {
  beforeEach(() => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({
      customer_ticket_create: true,
    })
  })

  it('shows 3 steps for customers', async () => {
    const { view } = await visitTicketCreate()

    const steps = ['1', '2', '3']
    steps.forEach((step) => {
      expect(view.getByRole('button', { name: step })).toBeInTheDocument()
    })

    expect(view.queryByRole('button', { name: '4' })).not.toBeInTheDocument()
  })

  it('redirects to the error page if ticket creation is turned off', async () => {
    mockApplicationConfig({
      customer_ticket_create: false,
    })

    const { view } = await visitTicketCreate()

    expect(view.getByRole('main')).toHaveTextContent(
      'Creating new tickets via web is disabled.',
    )
  })

  it('does not show the organization field without secondary organizations', async () => {
    mockAccount({
      lastname: 'Doe',
      firstname: 'John',
      organization: defaultOrganization(),
      hasSecondaryOrganizations: false,
    })

    const { mockFormUpdater, view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')

    await waitUntil(() => mockFormUpdater.calls.resolve)

    await nextStep(view)

    expect(view.queryByLabelText('Organization')).not.toBeInTheDocument()
  })

  it('does show the organization field with secondary organizations', async () => {
    mockAccount({
      lastname: 'Doe',
      firstname: 'John',
      organization: defaultOrganization(),
      hasSecondaryOrganizations: true,
    })

    const { mockFormUpdater, view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')

    await waitUntil(() => mockFormUpdater.calls.resolve)

    await nextStep(view)

    expect(view.queryByLabelText('Organization')).toBeInTheDocument()
  })
})
