// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitForTimeout } from '@tests/support/utils'
import { ObjectManagerFrontendAttributesDocument } from '../../graphql/queries/objectManagerFrontendAttributes.api'
import { useObjectAttributes } from '../useObjectAttributes'
import objectFrontendAttributes from './mocks/objectFrontendAttributes.json'
import { useObjectAttributeFormData } from '../useObjectAttributeFormData'

const mockOrganizationObjectManagerAttributes = () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: objectFrontendAttributes,
  })
}

const getObjectAttributeLookup = async () => {
  mockOrganizationObjectManagerAttributes()

  const { attributesLookup } = useObjectAttributes(
    EnumObjectManagerObjects.Organization,
  )
  await waitForTimeout()

  return attributesLookup
}

describe('useObjectAttributeFormFields', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('check for correct internal values and additional object attribute values', async () => {
    const objectAttributesLookup = await getObjectAttributeLookup()

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(objectAttributesLookup.value, {
        formId: '123456',
        name: 'Example',
        textarea: 'some example',
      })

    expect(internalObjectAttributeValues).toEqual({
      name: 'Example',
    })
    expect(additionalObjectAttributeValues).toEqual([
      {
        name: 'textarea',
        value: 'some example',
      },
    ])
  })
})
