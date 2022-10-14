// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitForTimeout } from '@tests/support/utils'
import { createPinia, setActivePinia } from 'pinia'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { ObjectManagerFrontendAttributesDocument } from '../../graphql/queries/objectManagerFrontendAttributes.api'
import { useObjectAttributes } from '../useObjectAttributes'

const mockOrganizationObjectManagerAttributes = () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: {
      attributes: [
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'name',
          display: 'Name',
          dataType: 'input',
          isInternal: true,
          dataOption: {
            type: 'text',
            maxlength: 150,
            null: false,
            item_class: 'formGroup--halfSize',
          },
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'shared',
          display: 'Shared organization',
          dataType: 'boolean',
          isInternal: true,
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
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'domain_assignment',
          display: 'Domain based assignment',
          dataType: 'boolean',
          isInternal: true,
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
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'domain',
          display: 'Domain',
          dataType: 'input',
          isInternal: true,
          dataOption: {
            type: 'text',
            maxlength: 150,
            null: true,
            item_class: 'formGroup--halfSize',
          },
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'note',
          display: 'Note',
          dataType: 'richtext',
          isInternal: true,
          dataOption: {
            type: 'text',
            maxlength: 5000,
            null: true,
            note: 'Notes are visible to agents only, never to customers.',
            no_images: true,
          },
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'active',
          display: 'Active',
          dataType: 'active',
          isInternal: true,
          dataOption: {
            null: true,
            default: true,
            permission: ['admin.organization'],
          },
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'test',
          display: 'test',
          dataType: 'input',
          isInternal: false,
          dataOption: {
            default: '',
            type: 'text',
            maxlength: 120,
            linktemplate: '',
            null: true,
            options: {},
            relation: '',
          },
          screens: {},
        },
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'textarea',
          display: 'textarea',
          dataType: 'textarea',
          isInternal: false,
          dataOption: {
            default: '',
            maxlength: 500,
            rows: 4,
            null: true,
            options: {},
            relation: '',
          },
          screens: {},
        },
      ],
      screens: [
        {
          name: 'view',
          attributes: [
            'name',
            'shared',
            'domain_assignment',
            'domain',
            'note',
            'active',
            'test',
            'textarea',
          ],
        },
        {
          name: 'edit',
          attributes: [
            'name',
            'shared',
            'domain_assignment',
            'domain',
            'note',
            'active',
            'test',
            'textarea',
          ],
        },
      ],
    },
  })
}

const getMeta = async () => {
  mockOrganizationObjectManagerAttributes()

  const meta = useObjectAttributes(EnumObjectManagerObjects.Organization)
  await waitForTimeout()

  return meta
}

describe('Object Manager Frontend Attributes Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('is filled for Organization', async () => {
    const meta = await getMeta()

    expect(meta.attributes).not.toBe(undefined)
  })

  it('contains screens', async () => {
    const meta = await getMeta()

    expect(meta.screens.value).toEqual({
      view: [
        'name',
        'shared',
        'domain_assignment',
        'domain',
        'note',
        'active',
        'test',
        'textarea',
      ],
      edit: [
        'name',
        'shared',
        'domain_assignment',
        'domain',
        'note',
        'active',
        'test',
        'textarea',
      ],
    })
  })

  it('provides a fancy lookup of all attributes', async () => {
    const meta = await getMeta()

    expect(meta.attributesLookup.value.get('name')).toEqual({
      __typename: 'ObjectManagerFrontendAttribute',
      name: 'name',
      display: 'Name',
      dataType: 'input',
      isInternal: true,
      dataOption: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      screens: {},
    })
  })
})
