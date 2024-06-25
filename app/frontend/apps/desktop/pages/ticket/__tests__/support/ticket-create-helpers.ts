// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import type { ExtendedRenderResult } from '#tests/support/components'

import {
  mockAutocompleteSearchGenericQuery,
  waitForAutocompleteSearchGenericQueryCalls,
} from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.mocks.ts'
import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockUserQuery } from '#shared/entities/user/graphql/queries/user.mocks.ts'

import { testOptions } from '#desktop/components/Form/fields/FieldCustomer/__tests__/support/testOptions.ts'

export const handleMockFormUpdaterQuery = (additionalProperties = {}) =>
  mockFormUpdaterQuery({
    formUpdater: {
      ...additionalProperties,
      group_id: {
        options: [
          {
            value: 1,
            label: 'Users',
          },
          {
            value: 2,
            label: 'some group1',
          },
        ],
      },
      priority_id: {
        options: [
          { value: 1, label: '1 low' },
          { value: 2, label: '2 normal' },
          { value: 3, label: '3 high' },
        ],
      },
      state_id: {
        options: [
          { value: 4, label: 'closed' },
          { value: 1, label: 'new' },
          { value: 2, label: 'open' },
          { value: 6, label: 'pending close' },
          { value: 3, label: 'pending reminder' },
        ],
      },
    },
  })

export const handleCustomerMock = async (view: ExtendedRenderResult) => {
  mockAutocompleteSearchGenericQuery({
    autocompleteSearchGeneric: testOptions,
  })

  const customerField = view.getByRole('combobox', { name: 'Customer' })

  await view.events.type(customerField, 'Nicole')

  return waitForAutocompleteSearchGenericQueryCalls()
}

export const rendersFields = (view: ExtendedRenderResult) => {
  // Same for all article types
  expect(view.getByText('Title')).toBeInTheDocument()
  expect(view.getByRole('combobox', { name: 'Customer' })).toBeInTheDocument()
  expect(view.getByText('Text')).toBeInTheDocument()
  expect(view.getByRole('combobox', { name: 'Group' })).toBeInTheDocument()
  expect(view.getByRole('combobox', { name: 'Priority' })).toBeInTheDocument()
  expect(view.getByRole('combobox', { name: 'State' })).toBeInTheDocument()

  expect(view.getByText('Group')).toBeInTheDocument()
  expect(view.getByText('Owner')).toBeInTheDocument()
  expect(view.getByText('State')).toBeInTheDocument()
  expect(view.getByText('Priority')).toBeInTheDocument()
  expect(view.getByText('Tags')).toBeInTheDocument()
}

export const handleMockUserQuery = () => {
  return mockUserQuery({
    user: {
      __typename: 'User',
      policy: {
        __typename: 'PolicyDefault',
        update: true,
      },
      id: 'gid://zammad/User/2',
      internalId: 2,
      firstname: 'Nicole',
      lastname: 'Braun',
      fullname: 'Nicole Braun',
      outOfOffice: false,
      outOfOfficeStartAt: null,
      outOfOfficeEndAt: null,
      image: null,
      email: 'nicole.braun@zammad.org',
      web: '',
      vip: false,
      phone: '',
      mobile: '',
      fax: '',
      note: '',
      active: true,
      objectAttributeValues: [
        {
          __typename: 'ObjectAttributeValue',
          attribute: {
            __typename: 'ObjectManagerFrontendAttribute',
            name: 'department',
            display: 'Department',
          },
          value: '',
          renderedLink: null,
        },
        {
          __typename: 'ObjectAttributeValue',
          attribute: {
            __typename: 'ObjectManagerFrontendAttribute',
            name: 'address',
            display: 'Address',
          },
          value: '',
          renderedLink: null,
        },
      ],
      organization: {
        __typename: 'Organization',
        id: 'gid://zammad/Organization/1',
        internalId: 1,
        name: 'Zammad Foundation',
        active: true,
        vip: false,
        ticketsCount: {
          __typename: 'TicketCount',
          open: 17,
          closed: 0,
        },
      },
      secondaryOrganizations: {
        __typename: 'OrganizationConnection',
        edges: [],
        totalCount: 0,
      },
      hasSecondaryOrganizations: false,
      ticketsCount: {
        __typename: 'TicketCount',
        open: 17,
        closed: 0,
      },
    },
  })
}
