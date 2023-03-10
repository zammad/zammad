// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import type {
  SelectOption,
  SelectValue,
} from '@shared/components/Form/fields/FieldSelect'

const removeValuesForNonExistingOptions = (node: FormKitNode) => {
  // TODO: disable for now, because we need to improve the code in a follow-up
  // eslint-disable-next-line sonarjs/cognitive-complexity
  node.on('created', () => {
    const { context } = node

    if (!context) return

    node.at('$root')?.settled.then(() => {
      node.hook.input((payload, next) => {
        if (!context.fns.hasValue(payload) || !context.optionValueLookup)
          return next(payload)

        const optionValueLookup = context.optionValueLookup as Record<
          string | number,
          SelectOption
        >

        if (context.multiple) {
          const availableValues = payload.filter(
            (selectValue: string | number) =>
              typeof optionValueLookup[selectValue] !== 'undefined',
          ) as SelectValue[]

          return next(availableValues)
        }

        if (typeof optionValueLookup[payload] === 'undefined') {
          if (typeof optionValueLookup[node.props._init] === 'undefined') {
            const getPreselectValue =
              context.getPreselectValue as () => SelectValue

            return next(
              context.clearable || getPreselectValue === undefined
                ? undefined
                : getPreselectValue(),
            )
          }

          return next(node.props._init)
        }

        return next(payload)
      })
    })
  })
}

export default removeValuesForNonExistingOptions
