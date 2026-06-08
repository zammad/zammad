// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { effectScope } from 'vue'

import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { waitForTimeout } from '#tests/support/utils.ts'

import { EnumObjectManagerObjects, type PolicyTicket } from '#shared/graphql/types.ts'

import { ObjectManagerFrontendAttributesDocument } from '../../graphql/queries/objectManagerFrontendAttributes.api.ts'
import { useObjectAttributeFormFields } from '../useObjectAttributeFormFields.ts'
import { useObjectAttributes } from '../useObjectAttributes.ts'

import ticketObjectFrontendAttributes from './mocks/ticketObjectFrontendAttributes.json'

const mockTicketObjectManagerAttributes = () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: ticketObjectFrontendAttributes,
  })
}

const scope = effectScope()

describe('useObjectAttributeFormFields', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  describe('policy-based screen resolution', () => {
    it('resolves screen based on policy', async () => {
      await scope.run(async () => {
        mockTicketObjectManagerAttributes()

        const customerPolicy: Partial<PolicyTicket> = {
          agentReadAccess: false,
          update: true,
        }

        const { getFormFieldsFromScreen } = useObjectAttributeFormFields([], customerPolicy)

        useObjectAttributes(EnumObjectManagerObjects.Ticket)
        await waitForTimeout()

        // With customer policy, should use 'edit_customer' screen
        const fields = getFormFieldsFromScreen('edit', EnumObjectManagerObjects.Ticket)

        expect(fields).toBeDefined()
        // 'edit_customer' screen has 2 fields (title, group_id)
        expect(fields.length).toBe(2)
      })
    })
  })
})
