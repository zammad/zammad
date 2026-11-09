// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { effectScope } from 'vue'

import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { waitForTimeout } from '#tests/support/utils.ts'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { ObjectManagerFrontendAttributesDocument } from '../../graphql/queries/objectManagerFrontendAttributes.api.ts'
import { useEntityAttributeFormData } from '../useEntityAttributeFormData.ts'
import { useEntityAttributes } from '../useEntityAttributes.ts'

import objectFrontendAttributes from './mocks/objectFrontendAttributes.json'

const mockOrganizationObjectManagerAttributes = () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: objectFrontendAttributes,
  })
}

const getEntityAttributeLookup = async () => {
  mockOrganizationObjectManagerAttributes()

  const { attributesLookup } = useEntityAttributes(EnumObjectManagerObjects.Organization)
  await waitForTimeout()

  return attributesLookup
}

const scope = effectScope()

describe('useEntityAttributeFormFields', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('check for correct internal values and additional object attribute values', async () => {
    await scope.run(async () => {
      const entityAttributesLookup = await getEntityAttributeLookup()

      const { internalObjectAttributeValues, additionalObjectAttributeValues } =
        useEntityAttributeFormData(EnumObjectManagerObjects.Ticket, entityAttributesLookup.value, {
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
})
