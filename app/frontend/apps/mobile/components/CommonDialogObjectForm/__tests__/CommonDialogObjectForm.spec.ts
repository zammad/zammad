// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { keyBy } from 'lodash-es'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitUntilApisResolved } from '#tests/support/utils.ts'

import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { closeDialog } from '#mobile/composables/useDialog.ts'
import {
  mockOrganizationObjectAttributes,
  organizationObjectAttributes,
} from '#mobile/entities/organization/__tests__/mocks/organization-mocks.ts'

import CommonDialogObjectForm from '../CommonDialogObjectForm.vue'

vi.mock('#mobile/composables/useDialog.ts')

const renderForm = () => {
  const attributesResult = organizationObjectAttributes()
  const attributes = keyBy(attributesResult.attributes, 'name')
  const attributesApi = mockOrganizationObjectAttributes(attributesResult)
  const organization = {
    id: 'faked-id',
    name: 'Some Organization',
    shared: true,
    domainAssignment: false,
    domain: '',
    note: '',
    active: false,
    vip: false,
    objectAttributeValues: [
      {
        attribute: attributes.textarea,
        value: 'old value',
        renderedLink: null,
      },
      { attribute: attributes.test, value: 'some test', renderedLink: null },
    ],
  }

  const useMutationOrganizationUpdate = () => {
    return useMutation(gql`
      mutation {
        organizationUpdate
      }
    `)
  }
  const sendMock = vi.fn().mockResolvedValue(organization)
  MutationHandler.prototype.send = sendMock
  const view = renderComponent(CommonDialogObjectForm, {
    props: {
      name: 'organization',
      object: organization,
      type: EnumObjectManagerObjects.Organization,
      schema: defineFormSchema([
        {
          screen: 'edit',
          object: EnumObjectManagerObjects.Organization,
        },
      ]),
      mutation: useMutationOrganizationUpdate,
    },
    form: true,
    formField: true,
    confirmation: true,
  })
  return {
    attributesApi,
    sendMock,
    organization,
    attributes,
    view,
  }
}

test('can update default object', async () => {
  const { attributesApi, view, sendMock, organization } = renderForm()

  await waitUntilApisResolved(attributesApi)

  const attributeValues = keyBy(
    organization.objectAttributeValues,
    'attribute.name',
  )

  const name = view.getByLabelText('Name')
  const shared = view.getByLabelText('Shared organization')
  const domainAssignment = view.getByLabelText('Domain based assignment')
  const domain = view.getByLabelText('Domain')
  const active = view.getByLabelText('Active')
  const vip = view.getByLabelText('VIP')
  const textarea = view.getByLabelText('Textarea Field')
  const test = view.getByLabelText('Test Field')

  expect(name).toHaveFocus()

  expect(name).toHaveValue(organization.name)
  expect(shared).toBeChecked()
  expect(domainAssignment).not.toBeChecked()
  expect(domain).toHaveValue(organization.domain)
  expect(active).not.toBeChecked()
  expect(vip).not.toBeChecked()
  expect(textarea).toHaveValue(attributeValues.textarea.value)
  expect(test).toHaveValue(attributeValues.test.value)

  await view.events.type(name, ' 2')

  await view.events.click(shared)
  await view.events.click(domainAssignment)

  await view.events.type(domain, 'some-domain@domain.me')
  await view.events.click(active)
  await view.events.click(vip)
  await view.events.clear(textarea)
  await view.events.type(textarea, 'new value')

  await view.events.click(view.getByRole('button', { name: 'Save' }))

  expect(sendMock).toHaveBeenCalledOnce()
  expect(sendMock).toHaveBeenCalledWith({
    id: organization.id,
    input: {
      name: 'Some Organization 2',
      shared: false,
      domain: 'some-domain@domain.me',
      domainAssignment: true,
      active: true,
      vip: true,
      note: '',
      objectAttributeValues: [
        { name: 'test', value: 'some test' },
        { name: 'textarea', value: 'new value' },
      ],
    },
  })
  expect(closeDialog).toHaveBeenCalled()
})

it("doesn't close dialog, if result is unsuccessful", async () => {
  const { attributesApi, view, sendMock } = renderForm()

  await waitUntilApisResolved(attributesApi)
  sendMock.mockResolvedValue(null)

  await view.events.type(view.getByLabelText('Domain'), 'some-domain@domain.me')

  await view.events.click(view.getByRole('button', { name: 'Save' }))

  expect(sendMock).toHaveBeenCalledOnce()
  expect(closeDialog).not.toHaveBeenCalled()
})

it("doesn't call api, if dialog is closed", async () => {
  const { attributesApi, view, sendMock } = renderForm()

  await waitUntilApisResolved(attributesApi)

  await view.events.type(view.getByLabelText('Name'), ' 2')
  await view.events.click(view.getByRole('button', { name: 'Cancel' }))

  await view.events.click(await view.findByText('Discard changes'))

  expect(sendMock).not.toHaveBeenCalledOnce()
  expect(closeDialog).toHaveBeenCalled()
})
