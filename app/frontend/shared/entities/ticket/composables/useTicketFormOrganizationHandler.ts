// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AutoCompleteOrganizationOption } from '#shared/components/Form/fields/FieldOrganization/types.ts'
import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  FormSchemaField,
  ReactiveFormSchemData,
  ChangedField,
  FormHandlerFunction,
  FormHandler,
} from '#shared/components/Form/types.ts'
import { getAutoCompleteOption } from '#shared/entities/organization/utils/getAutoCompleteOption.ts'
import type { Organization, Scalars } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts' // TODO: remove this import

export const useTicketFormOrganizationHandler = (): FormHandler => {
  const executeHandler = (
    execution: FormHandlerExecution,
    schemaData: ReactiveFormSchemData,
    changedField?: ChangedField,
  ) => {
    if (!schemaData.fields.organization_id) return false
    if (
      execution === FormHandlerExecution.FieldChange &&
      (!changedField || changedField.name !== 'customer_id')
    ) {
      return false
    }

    return true
  }

  const handleOrganizationField: FormHandlerFunction = (execution, reactivity, data) => {
    const { formNode, values, initialEntityObject, changedField, formUpdaterData } = data
    const { schemaData, changeFields, updateSchemaDataField } = reactivity

    if (!executeHandler(execution, schemaData, changedField)) return

    const session = useSessionStore()

    const organizationField: Partial<FormSchemaField> = {
      show: false,
      required: false,
    }

    const setCustomer = (): Maybe<UserData> | undefined => {
      if (session.hasPermission('ticket.agent')) {
        if (changedField?.newValue) {
          const optionValue = formNode?.find('customer_id', 'name')?.context
            ?.optionValueLookup as Record<number, Record<'object' | 'user', UserData>>
          // ⚠️ :INFO mobile query retrieves .user and .object for desktop
          return (
            (optionValue[changedField.newValue as number].object as UserData) ||
            (optionValue[changedField.newValue as number].user as UserData)
          )
        }

        if (
          execution === FormHandlerExecution.Initial &&
          formUpdaterData?.fields.customer_id?.value
        ) {
          return formUpdaterData.fields.customer_id.options?.[0]?.object as UserData
        }

        if (
          execution === FormHandlerExecution.FieldChange ||
          !values.customer_id ||
          !initialEntityObject
        )
          return undefined

        return initialEntityObject.customer
      }

      return session.user
    }

    const setOrganizationField = (
      customerId: Scalars['ID']['output'],
      organization?: Maybe<Partial<Organization>>,
      options?: AutoCompleteOrganizationOption[],
    ) => {
      const props = {
        defaultFilter: '*',
        alwaysApplyDefaultFilter: true,
        additionalQueryParams: {
          customerId,
        },
      }

      organizationField.show = true
      organizationField.required = true

      if (organization) {
        const currentValueOption = getAutoCompleteOption(organization)

        // Some information can be changed during the next user interactions, so update only the current schema data.
        updateSchemaDataField({
          name: 'organization_id',
          props: {
            ...props,
            options: [currentValueOption],
          },
          value: currentValueOption.value,
        })
      } else if (options) {
        updateSchemaDataField({
          name: 'organization_id',
          props: {
            ...props,
            options,
          },
          value: options[0].value,
        })
      } else {
        updateSchemaDataField({
          name: 'organization_id',
          props,
        })
      }
    }

    const customer = setCustomer()

    if (customer?.hasSecondaryOrganizations) {
      if (
        execution === FormHandlerExecution.Initial &&
        formUpdaterData?.fields.organization_id?.value
      ) {
        setOrganizationField(customer.id)
      } else if (!changedField?.formUpdaterValueChange) {
        setOrganizationField(customer.id, customer.organization as Organization)
      } else if (
        changedField?.formUpdaterValueChange &&
        schemaData.fields.organization_id?.props?.options
      ) {
        setOrganizationField(
          customer.id,
          undefined,
          schemaData.fields.organization_id?.props?.options as AutoCompleteOrganizationOption[],
        )
      }
    }

    // This values should be fixed, until the user change something in the customer_id field.
    changeFields.value.organization_id = {
      ...changeFields.value.organization_id,
      ...organizationField,
    }
  }

  return {
    execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
    callback: handleOrganizationField,
  }
}
