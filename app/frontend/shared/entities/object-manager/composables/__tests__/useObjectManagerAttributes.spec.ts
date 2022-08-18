// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitForTimeout } from '@tests/support/utils'
import { ObjectManagerFrontendAttributesDocument } from '@shared/graphql/queries/objectManagerFrontendAttributes.api'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { useObjectManagerAttributes } from '../useObjectManagerAttributes'

const mockOrganizationObjectManagerAttributes = async () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: [
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'name',
        display: 'Name',
        dataType: 'input',
        dataOption: {
          type: 'text',
          maxlength: 150,
          null: false,
          item_class: 'formGroup--halfSize',
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'shared',
        display: 'Shared organization',
        dataType: 'boolean',
        dataOption: {
          null: true,
          default: true,
          note: "Customers in the organization can view each other's items.",
          item_class: 'formGroup--halfSize',
          options: {
            true: 'yes',
            false: 'no',
          },
          translate: true,
          permission: ['admin.organization'],
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'domain_assignment',
        display: 'Domain based assignment',
        dataType: 'boolean',
        dataOption: {
          null: true,
          default: false,
          note: 'Assign users based on user domain.',
          item_class: 'formGroup--halfSize',
          options: {
            true: 'yes',
            false: 'no',
          },
          translate: true,
          permission: ['admin.organization'],
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'domain',
        display: 'Domain',
        dataType: 'input',
        dataOption: {
          type: 'text',
          maxlength: 150,
          null: true,
          item_class: 'formGroup--halfSize',
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'note',
        display: 'Note',
        dataType: 'richtext',
        dataOption: {
          type: 'text',
          maxlength: 5000,
          null: true,
          note: 'Notes are visible to agents only, never to customers.',
          no_images: true,
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'active',
        display: 'Active',
        dataType: 'active',
        dataOption: {
          null: true,
          default: true,
          permission: ['admin.organization'],
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'test',
        display: 'test',
        dataType: 'input',
        dataOption: {
          default: '',
          type: 'text',
          maxlength: 120,
          linktemplate: '',
          null: true,
          options: {},
          relation: '',
        },
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'textarea',
        display: 'textarea',
        dataType: 'textarea',
        dataOption: {
          default: '',
          maxlength: 500,
          rows: 4,
          null: true,
          options: {},
          relation: '',
        },
      },
    ],
  })
}

const getMeta = async () => {
  await mockOrganizationObjectManagerAttributes()

  const meta = useObjectManagerAttributes(EnumObjectManagerObjects.Organization)
  await waitForTimeout()

  return meta
}

describe('Object Manager Frontend Attributes Store', () => {
  it('is filled for Organization', async () => {
    const meta = await getMeta()

    expect(meta.attributes).not.toBe(undefined)
  })

  it('contains keys for all attributes', async () => {
    const meta = await getMeta()

    expect(meta.attributesKeys.value.length).toBe(8)
  })

  it('contains values for all attributes', async () => {
    const meta = await getMeta()

    expect(meta.attributesValues.value.length).toBe(8)
  })

  it('provides a fancy lookup of all attributes', async () => {
    const meta = await getMeta()

    expect(meta.attributesLookup.value.get('name')).toEqual({
      __typename: 'ObjectManagerFrontendAttribute',
      name: 'name',
      display: 'Name',
      dataType: 'input',
      dataOption: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
    })
  })
})
