// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormHandlerExecution } from '@shared/components/Form'
import type { FormHandlerFunction, FormHandler } from '@shared/components/Form'
import { useSessionStore } from '@shared/stores/session'
import type { Organization } from '@shared/graphql/types'
import type { AutoCompleteCustomerOption } from '@shared/components/Form/fields/FieldCustomer'
import type { UserData } from '@shared/types/store' // TODO: remove this import
import type { FormSchemaField } from '@shared/components/Form/types'
import { getAutoCompleteOption } from '@shared/entities/organization/utils/getAutoCompleteOption'

// TODO: needs to be aligned, when auto completes has a final state.
export const useTicketFormOganizationHandling = (): FormHandler => {
  const handleOrganizationField: FormHandlerFunction = (
    execution,
    formNode,
    values,
    changeFields,
    schemaData,
    changedField,
    // TODO ...
    // eslint-disable-next-line sonarjs/cognitive-complexity
  ) => {
    if (!schemaData.fields.organization_id) return
    if (
      execution === FormHandlerExecution.FieldChange &&
      (!changedField || changedField.name !== 'customer_id')
    ) {
      return
    }

    const session = useSessionStore()

    const organizationField: Partial<FormSchemaField> = {
      show: false,
      required: false,
    }

    const setCustomer = (): Maybe<UserData> | undefined => {
      if (session.hasPermission('ticket.agent')) {
        if (changedField?.newValue) {
          return (
            getNode('customer_id')?.context?.optionValueLookup as Record<
              number,
              AutoCompleteCustomerOption
            >
          )[changedField.newValue as number].user as UserData
        }

        if (execution === FormHandlerExecution.Initial && !values.customer_id)
          return undefined

        // TODO: initial handling needs to be different (we need to use the object entity)
        return values.customer_id as UserData
      }

      return session.user
    }

    const setOrganizationField = (
      organization?: Maybe<Partial<Organization>>,
    ) => {
      if (!organization) return

      organizationField.show = true
      organizationField.required = true

      organizationField.props = {
        options: [getAutoCompleteOption(organization)],
      }
      organizationField.value = organization.id
    }

    const customer = setCustomer()
    // TODO: extend if with secondary orga... check
    if (customer) {
      setOrganizationField(customer.organization as Organization)
    }

    changeFields.organization_id = {
      ...(changeFields.organization_id || {}),
      ...organizationField,
    }
  }

  return {
    execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
    callback: handleOrganizationField,
  }
}
