// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
import type { ExtendedRenderResult } from '#tests/support/components'
import { nullableMock } from '#tests/support/utils.ts'

import {
  mockAutocompleteSearchGenericQuery,
  waitForAutocompleteSearchGenericQueryCalls,
} from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.mocks.ts'
import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockOrganizationQuery } from '#shared/entities/organization/graphql/queries/organization.mocks.ts'
import { mockUserQuery } from '#shared/entities/user/graphql/queries/user.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { testOptions } from '#desktop/components/Form/fields/FieldCustomer/__tests__/support/testOptions.ts'

export const handleMockFormUpdaterQuery = (additionalProperties = {}) =>
  mockFormUpdaterQuery({
    formUpdater: {
      fields: {
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
        pending_time: {
          show: false,
        },
        ...additionalProperties,
      },
    },
  })

export const handleCustomerMock = async (view: ExtendedRenderResult) => {
  mockAutocompleteSearchGenericQuery({
    autocompleteSearchGeneric: testOptions,
  })

  const customerField = view.getByLabelText('Customer')

  await view.events.type(customerField, 'Nicole')

  return waitForAutocompleteSearchGenericQueryCalls()
}

export const rendersFields = (view: ExtendedRenderResult) => {
  // Same for all article types
  expect(view.getByText('Title')).toBeInTheDocument()
  expect(view.getByLabelText('Customer')).toBeInTheDocument()
  expect(view.getByText('Text')).toBeInTheDocument()
  expect(view.getByLabelText('Group')).toBeInTheDocument()
  expect(view.getByLabelText('Priority')).toBeInTheDocument()
  expect(view.getByLabelText('State')).toBeInTheDocument()

  expect(view.getByText('Group')).toBeInTheDocument()
  expect(view.getByText('Owner')).toBeInTheDocument()
  expect(view.getByText('State')).toBeInTheDocument()
  expect(view.getByText('Priority')).toBeInTheDocument()
  expect(view.getByText('Tags')).toBeInTheDocument()
}

export const handleMockUserQuery = () => {
  return mockUserQuery({
    user: nullableMock({
      policy: {
        update: true,
      },
      id: convertToGraphQLId('User', 2),
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
          attribute: {
            name: 'department',
            display: 'Department',
          },
          value: '',
          renderedLink: null,
        },
        {
          attribute: {
            name: 'address',
            display: 'Address',
          },
          value: '',
          renderedLink: null,
        },
      ],
      organization: {
        id: convertToGraphQLId('Organization', 1),
        internalId: 1,
        shared: null,
        name: 'Zammad Foundation',
        active: true,
        vip: false,
        ticketsCount: {
          open: 17,
          closed: 0,
        },
      },
      secondaryOrganizations: {
        edges: [],
        totalCount: 0,
      },
      hasSecondaryOrganizations: false,
      ticketsCount: {
        open: 17,
        closed: 0,
      },
    }),
  })
}

export const handleMockOrganizationQuery = () => {
  return mockOrganizationQuery({
    organization: nullableMock({
      internalId: 1,
      name: 'Zammad Foundation',
      shared: false,
      domain: null,
      domainAssignment: false,
      allMembers: {
        edges: [
          {
            node: {
              id: convertToGraphQLId('User', 1),
              internalId: 1,
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              email: 'nicole.braun@zammad.org',
              active: true,
              vip: false,
            },
          },
        ],
        totalCount: 1,
      },
      ticketsCount: {
        open: 17,
        closed: 0,
      },
    }),
  })
}
