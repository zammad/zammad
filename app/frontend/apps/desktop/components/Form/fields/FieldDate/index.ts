// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { dateFieldProps } from '#shared/components/Form/fields/FieldDate/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldDateTimeInput from './FieldDateTimeInput.vue'

import type { FormKitNode, FormKitProps } from '@formkit/core'

const addDateRangeValidation = (node: FormKitNode) => {
  const addDataRangeValidation = (props: Partial<FormKitProps>) => {
    const { validation } = props
    if (Array.isArray(validation)) {
      validation.push(['date_range'])
      return
    }

    if (!validation) {
      props.validation = 'date_range'
      return
    }

    if (!validation.includes('required')) {
      props.validation = `${validation}|date_range`
    }
  }

  const removeDataRangeValidation = (props: Partial<FormKitProps>) => {
    const { validation } = props

    if (!validation) return

    if (Array.isArray(validation)) {
      props.validation = validation.filter(([rule]) => rule !== 'date_range')
      return
    }

    if (validation.includes('date_range')) {
      props.validation = validation
        .split('|')
        .filter((rule: string) => !rule.includes('date_range'))
        .join('|')
    }
  }

  node.on('created', () => {
    const { props } = node

    if (props.range) {
      addDataRangeValidation(props)
    }

    node.on('prop:range', ({ payload }) => {
      if (payload) {
        addDataRangeValidation(props)
      } else {
        removeDataRangeValidation(props)
      }
    })
  })
}

const dateFieldDefinition = createInput(FieldDateTimeInput, dateFieldProps, {
  features: [addLink, formUpdaterTrigger(), addDateRangeValidation],
})

export default [
  {
    fieldType: 'date',
    definition: dateFieldDefinition,
  },
  {
    fieldType: 'datetime',
    definition: dateFieldDefinition,
  },
]
