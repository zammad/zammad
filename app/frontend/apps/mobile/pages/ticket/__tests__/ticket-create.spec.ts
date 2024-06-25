// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import type { ExtendedRenderResult } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'
import { nullableMock, waitUntil } from '#tests/support/utils.ts'

import { AutocompleteSearchUserDocument } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'
import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import { TicketCreateDocument } from '#shared/entities/ticket/graphql/mutations/create.api.ts'

import { defaultOrganization } from '#mobile/entities/organization/__tests__/mocks/organization-mocks.ts'
import {
  ticketObjectAttributes,
  ticketArticleObjectAttributes,
  ticketPayload,
} from '#mobile/entities/ticket/__tests__/mocks/ticket-mocks.ts'

const visitTicketCreate = async (path = '/tickets/create') => {
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
      ticket_duplicate_detection: {
        show: true,
        hidden: false,
        value: { count: 0, items: [] },
      },
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

  const view = await visitView(path)

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

const checkShownSteps = async (
  view: ExtendedRenderResult,
  steps: Array<string>,
) => {
  steps.forEach((step) => {
    expect(view.getByRole('button', { name: step })).toBeInTheDocument()
  })
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import(
    '#shared/components/Form/fields/FieldEditor/FieldEditorInput.vue'
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

    checkShownSteps(view, ['1', '2', '3', '4'])
  })

  it('disables the submit button if required data is missing', async () => {
    const { view } = await visitTicketCreate()

    expect(view.getByRole('button', { name: 'Create' })).toBeDisabled()
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
    { name: 'Create', button: 'header submit button' },
    { name: 'Create ticket', button: 'footer submit button' },
  ])(
    'redirects to detail view after successful ticket creation when clicked on $button',
    async ({ name }) => {
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
      const editorNode = getNode('ticket-create')?.find('body', 'name')
      await editorNode?.input('Article body', false)

      // There is a button with "Create" in the header, and a "Create ticket" button in the footer.
      const submitButton = view.getByRole('button', { name })
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

    await view.events.click(view.getByRole('button', { name: 'Go home' }))

    expect(view.queryByTestId('popupWindow')).toBeInTheDocument()

    await expect(view.findByText('Confirm dialog')).resolves.toBeInTheDocument()
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

    checkShownSteps(view, ['1', '2', '3'])

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
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
      organization: defaultOrganization(),
      hasSecondaryOrganizations: false,
    })
    mockPermissions(['ticket.customer'])

    const { mockFormUpdater, view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')

    await waitUntil(() => mockFormUpdater.calls.resolve)

    await nextStep(view)

    expect(view.queryByLabelText('Organization')).not.toBeInTheDocument()
  })

  it('does show the organization field with secondary organizations', async () => {
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
      organization: defaultOrganization(),
      hasSecondaryOrganizations: true,
    })
    mockPermissions(['ticket.customer'])

    const { mockFormUpdater, view } = await visitTicketCreate()

    await view.events.type(view.getByLabelText('Title'), 'Foobar')

    await waitUntil(() => mockFormUpdater.calls.resolve)

    await nextStep(view)

    expect(view.queryByLabelText('Organization')).toBeInTheDocument()
  })

  it("doesn't show 'are you sure' dialog if duplicate protection is enabled and no changes were done", async () => {
    mockTicketOverviews()

    const { view } = await visitTicketCreate()

    await view.events.click(view.getByLabelText('Go home'))

    await waitFor(() => {
      expect(view.queryByText('Additional information')).not.toBeInTheDocument()
    })

    expect(view.queryByText('Confirm dialog')).not.toBeInTheDocument()
  })
})

describe('Creating new ticket as user having customer & agent permissions', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent', 'ticket.customer'])

    mockApplicationConfig({
      customer_ticket_create: true,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      ui_ticket_create_default_type: 'phone-in',
    })
  })

  it('does show the form for agents if having ticket.customer & ticket.agent permissions', async () => {
    const { view } = await visitTicketCreate()

    checkShownSteps(view, ['1', '2', '3', '4'])
  })
})

describe('Create ticket page redirects back', () => {
  it('correctly redirects from ticket create hash-based routes', async () => {
    setupView('agent')
    await visitTicketCreate('/#ticket/create')
    const router = getTestRouter()
    const route = router.currentRoute.value
    expect(route.name).toBe('TicketCreate')
  })

  it('correctly redirects from ticket create with id hash-based routes', async () => {
    setupView('agent')
    await visitTicketCreate('/#ticket/create/id/13214124')
    const router = getTestRouter()
    const route = router.currentRoute.value
    expect(route.name).toBe('TicketCreate')
  })
})
