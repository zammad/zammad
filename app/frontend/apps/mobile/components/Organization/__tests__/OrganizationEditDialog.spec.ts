// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { closeDialog } from '@shared/composables/useDialog'
import { renderComponent } from '@tests/support/components'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { OrganizationUpdateDocument } from '@mobile/entities/organization/graphql/mutations/update.api'
import { mockOrganizationObjectAttributes } from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import OrganizationEditDialog from '../OrganizationEditDialog.vue'

vi.mock('@shared/composables/useDialog')

const textareaAttribute = {
  name: 'textarea',
  display: 'Textarea Field',
  dataType: 'textarea',
  dataOption: {
    default: '',
    maxlength: 500,
    rows: 4,
    null: true,
    options: {},
    relation: '',
  },
  __typename: 'ObjectManagerFrontendAttribute',
}

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
        objectAttributeValues: [
          { attribute: textareaAttribute, value: 'new value' },
        ],
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
        objectAttributeValues: [
          { attribute: textareaAttribute, value: 'old value' },
        ],
      },
    },
    form: true,
    router: true,
    store: true,
  })

describe('editing organization', () => {
  test('can edit organization', async () => {
    const attributesApi = mockOrganizationObjectAttributes()

    const mockApi = createUpdateMock()

    const view = renderEditDialog()

    await waitUntil(() => attributesApi.calls.resolve)

    await view.events.type(view.getByLabelText('Name'), ' 2')
    await view.events.click(view.getByLabelText('Shared organization'))
    await view.events.click(view.getByLabelText('Domain based assignment'))
    await view.events.type(
      view.getByLabelText('Domain'),
      'some-domain@domain.me',
    )
    await view.events.click(view.getByLabelText('Active'))

    const textarea = view.getByLabelText('Textarea Field')
    await view.events.clear(textarea)
    await view.events.type(textarea, 'new value')

    await view.events.click(view.getByRole('button', { name: 'Save' }))

    await waitUntil(() => mockApi.calls.resolve)

    expect(mockApi.spies.resolve).toHaveBeenCalledWith({
      id: 'faked-id',
      input: {
        name: 'Some Organization 2',
        shared: false,
        domain: 'some-domain@domain.me',
        domainAssignment: true,
        active: true,
        note: '',
        objectAttributeValues: [{ name: 'textarea', value: 'new value' }],
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
