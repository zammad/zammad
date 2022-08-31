// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { closeDialog } from '@shared/composables/useDialog'
import { renderComponent } from '@tests/support/components'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { OrganizationUpdateDocument } from '../../graphql/mutations/update.api'
import OrganizationEditDialog from '../OrganizationEditDialog.vue'

vi.mock('@shared/composables/useDialog')

const createUpdateMock = () =>
  mockGraphQLApi(OrganizationUpdateDocument).willResolve({
    organizationUpdate: {
      organization: {
        id: 'faked-id',
        name: 'Some Organization',
        shared: false,
        domain: 'some-domain@domain.me',
        domainAssignment: true,
        active: true,
        note: 'Save something as this note',
      },
      errors: null,
    },
  })

const renderEditDialog = () =>
  renderComponent(OrganizationEditDialog, {
    props: {
      name: 'some-name',
      organization: {
        id: 'faked-id',
        name: 'Some Organization',
        shared: true,
        domainAssignment: false,
        domain: '',
        note: '',
        active: false,
      },
    },
    form: true,
    router: true,
    store: true,
  })

describe('editing organization', () => {
  test('can edit organization', async () => {
    const mockApi = createUpdateMock()

    const view = renderEditDialog()

    await view.events.click(view.getByLabelText('Shared organization'))
    await view.events.click(view.getByLabelText('Domain based assignment'))
    await view.events.type(
      view.getByLabelText('Domain'),
      'some-domain@domain.me',
    )
    await view.events.type(
      view.getByLabelText('Note'),
      'Save something as this note',
    )
    await view.events.click(view.getByLabelText('Active'))

    await view.events.click(view.getByRole('button', { name: 'Save' }))

    await waitUntil(() => mockApi.calls.resolve)

    expect(mockApi.spies.resolve).toHaveBeenCalledWith({
      id: 'faked-id',
      input: {
        shared: false,
        domain: 'some-domain@domain.me',
        domainAssignment: true,
        active: true,
        note: 'Save something as this note',
      },
    })
    expect(closeDialog).toHaveBeenCalled()
  })

  test("doesn't call on cancel", async () => {
    const mockApi = createUpdateMock()

    const view = renderEditDialog()

    await view.events.click(view.getByRole('button', { name: 'Cancel' }))

    expect(closeDialog).toHaveBeenCalled()
    expect(mockApi.spies.resolve).not.toHaveBeenCalled()
  })
})
