// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  ObjectSelectOption,
  ObjectSelectValue,
} from '#shared/entities/object-attributes/form/resolver/fields/select.ts'

import type { FormKitFrameworkContext, FormKitNode } from '@formkit/core'
import type { Dictionary } from 'ts-essentials'

type OptionValueLookup = Dictionary<ObjectSelectOption>
type SelectValueWithoutBoolean = Exclude<ObjectSelectValue, boolean>

const removeValuesForNonExistingOrDisabledOptions = (node: FormKitNode) => {
  const handleNewInputValue = (
    payload: SelectValueWithoutBoolean | SelectValueWithoutBoolean[],
    context: FormKitFrameworkContext,
  ) => {
    const optionValueLookup = context.optionValueLookup as OptionValueLookup

    if (Array.isArray(payload)) {
      // TODO: Workaround for empty string, because currently the "nulloption" exists also for multiselect fields (#4513).
      const availableValues = payload.filter(
        (selectValue: string | number) =>
          (typeof optionValueLookup[selectValue] !== 'undefined' &&
            !optionValueLookup[selectValue].disabled) ||
          selectValue === '',
      )

      return availableValues
    }

    if (
      typeof optionValueLookup[payload] === 'undefined' ||
      optionValueLookup[payload].disabled
    ) {
      if (typeof optionValueLookup[node.props._init] === 'undefined') {
        const getPreselectValue =
          context.getPreselectValue as () => ObjectSelectValue

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

export default removeValuesForNonExistingOrDisabledOptions
