// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, reactive } from 'vue'

import type { FormSchemaField, FormSchemaNode } from '#shared/components/Form/types.ts'
import { useTicketAccountedTime } from '#shared/entities/ticket/composables/useTicketAccountedTime.ts'
import type { TicketArticleTimeAccountingFormData } from '#shared/entities/ticket/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { FormKitNode } from '@formkit/core'

// The accounted time is entered as free text, so a decimal comma is accepted as well.
export const normalizeTimeAccountingUnit = (timeUnit: string) => timeUnit.replace(',', '.')

// Both apps merge the dialog values into the article of the ticket update, so the mapping onto
//   the GraphQL input lives here. A value that cannot be parsed is left out instead of being
//   sent as NaN.
export const buildTimeAccountingArticleData = (data: TicketArticleTimeAccountingFormData) => {
  const timeUnit = parseFloat(data.time_unit ?? '')

  return {
    timeUnit: Number.isFinite(timeUnit) ? timeUnit : undefined,
    accountedTimeTypeId: data.accounted_time_type_id
      ? convertToGraphQLId('Ticket::TimeAccounting::Type', data.accounted_time_type_id)
      : undefined,
  }
}

const validateTimeAccountingUnit = (node: FormKitNode<string>) => {
  if (!node.value) return false

  return !Number.isNaN(+normalizeTimeAccountingUnit(node.value))
}

export const useTicketTimeAccountingForm = () => {
  const { timeAccountingDisplayUnit, timeAccountingConfig } = useTicketAccountedTime()

  // Both apps show the configured unit next to the input, but with their own markup, so the
  //   additional props of the time unit field are passed in by the caller.
  const buildTimeAccountingFormSchema = (timeUnitFieldProps: Partial<FormSchemaField> = {}) =>
    [
      {
        isLayout: true,
        component: 'FormGroup',
        children: [
          {
            id: 'timeUnit',
            name: 'time_unit',
            label: __('Accounted time'),
            type: 'text',
            required: true,
            placeholder: __('Enter the time you want to record'),
            validation: 'validationRuleTimeAccountingUnit',
            validationRules: {
              validationRuleTimeAccountingUnit: validateTimeAccountingUnit,
            },
            validationMessages: {
              validationRuleTimeAccountingUnit: __('This field must contain a number.'),
            },
            ...timeUnitFieldProps,
          },
          {
            if: '$timeAccountingTypes === true',
            id: 'accountedTimeTypeId',
            name: 'accounted_time_type_id',
            label: __('Activity type'),
            type: 'select',
            props: {
              clearable: true,
            },
          },
        ],
      },
    ] as FormSchemaNode[]

  const timeAccountingSchemaData = reactive({
    timeAccountingTypes: computed(() => timeAccountingConfig.value.time_accounting_types),
  })

  return {
    timeAccountingDisplayUnit,
    timeAccountingSchemaData,
    buildTimeAccountingFormSchema,
  }
}
