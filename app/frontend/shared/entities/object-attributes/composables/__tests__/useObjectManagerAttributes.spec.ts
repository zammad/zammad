// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitForTimeout } from '@tests/support/utils'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import objectFrontendAttributes from './mocks/objectFrontendAttributes.json'
import { ObjectManagerFrontendAttributesDocument } from '../../graphql/queries/objectManagerFrontendAttributes.api'
import { useObjectAttributes } from '../useObjectAttributes'

const mockOrganizationObjectManagerAttributes = () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: objectFrontendAttributes,
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
