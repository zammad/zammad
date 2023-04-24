// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitFrameworkContext, FormKitNode } from '@formkit/core'
import type { Dictionary } from 'ts-essentials'
import type {
  SelectOption,
  SelectValue,
} from '#shared/components/Form/fields/FieldSelect/index.ts'

type OptionValueLookup = Dictionary<SelectOption>
type SelectValueWithoutBoolean = Exclude<SelectValue, boolean>

const removeValuesForNonExistingOptions = (node: FormKitNode) => {
  const handleNewInputValue = (
    payload: SelectValueWithoutBoolean | SelectValueWithoutBoolean[],
    context: FormKitFrameworkContext,
  ) => {
    const optionValueLookup = context.optionValueLookup as OptionValueLookup

    if (Array.isArray(payload)) {
      // TODO: Workaround, because currently the "nulloption" exists also for multiselect fields (#4513).
      const availableValues = payload.filter(
        (selectValue: string | number) =>
          typeof optionValueLookup[selectValue] !== 'undefined' ||
          selectValue === '',
      ) as SelectValue[]

      return availableValues
    }

    if (typeof optionValueLookup[payload] === 'undefined') {
      if (typeof optionValueLookup[node.props._init] === 'undefined') {
        const getPreselectValue = context.getPreselectValue as () => SelectValue

        return context.clearable || getPreselectValue === undefined
          ? undefined
          : getPreselectValue()
      }

      return node.props._init
    }

    return payload
  }

  node.on('created', () => {
    const { context } = node

    if (!context) return

    node.at('$root')?.settled.then(() => {
      node.hook.input((payload, next) => {
        if (!context.fns.hasValue(payload) || !context.optionValueLookup)
          return next(payload)

        return next(handleNewInputValue(payload, context))
      })
    })
  })
}

export default removeValuesForNonExistingOptions
