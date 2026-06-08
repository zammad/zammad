// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'

import type { FormFieldValue } from '#shared/components/Form/types.ts'
import type { OptionValueLookup } from '#shared/entities/object-attributes/form/resolver/fields/select.ts'
import { flattenObjectAttributeValues } from '#shared/entities/object-attributes/utils.ts'
import { useEntity, type EntityName } from '#shared/entities/useEntity.ts'
import { extractEntityIds } from '#shared/form/utils/entity.ts'
import type { EntityObject } from '#shared/types/entity.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { FormKitNode } from '@formkit/core'
import type { Dictionary } from 'ts-essentials'

type SelectValue = string | number
type HistoricalOptions = Dictionary<string>

const extractLabelFromRelatedObject = (
  value: SelectValue,
  belongsToObjectField: string,
  initialEntityObject: ObjectLike,
): string | undefined => {
  const relatedObject = initialEntityObject[belongsToObjectField] as ObjectLike | undefined
  if (!relatedObject) return undefined

  const entity = useEntity(relatedObject.__typename as EntityName)
  return entity.display(relatedObject as EntityObject)
}

const extractLabelFromHistoricalOptions = (
  value: SelectValue,
  historicalOptions: HistoricalOptions,
): string | undefined => {
  return historicalOptions[value.toString()]
}

const getEntityValueForField = (
  fieldName: string,
  belongsToObjectField: string | undefined,
  initialEntityObject: ObjectLike,
): SelectValue | SelectValue[] | undefined => {
  if (belongsToObjectField) {
    const relatedObject = initialEntityObject[belongsToObjectField] as ObjectLike | undefined
    return extractEntityIds(relatedObject)
  }

  const initialEntityObjectAttributeMap = flattenObjectAttributeValues<FormFieldValue>(
    initialEntityObject.objectAttributeValues,
  )

  return (
    fieldName in initialEntityObjectAttributeMap
      ? initialEntityObjectAttributeMap[fieldName]
      : initialEntityObject[fieldName]
  ) as SelectValue | SelectValue[] | undefined
}

const addOrRemoveMissingEntityObjectOption = (node: FormKitNode) => {
  node.on('created', () => {
    const { context } = node

    if (!context) return

    const rootNode = node.at('$root')!

    rootNode.settled.then(() => {
      node.hook.input((payload, next) => {
        const optionValueLookup = context.optionValueLookup as OptionValueLookup | undefined

        if (!context.fns.hasValue(payload) || !optionValueLookup) return next(payload)

        // Early return if we can't extract any option.
        const belongsToObjectField = context.belongsToObjectField as string | undefined
        const historicalOptions = context.historicalOptions as HistoricalOptions | undefined
        const initialEntityObject = rootNode.context?.initialEntityObject as ObjectLike | undefined

        if ((!belongsToObjectField && !historicalOptions) || !initialEntityObject)
          return next(payload)

        // Compute entity value early so we can use it for both cleanup and add logic.
        const entityValue = getEntityValueForField(
          node.name,
          belongsToObjectField,
          initialEntityObject,
        )

        // Clean up stale appended options when the entity value changes (e.g. after save/reset).
        // We track the last known entity value to detect changes — user interactions don't alter
        // the entity value, so appended options remain stable until an actual entity update.
        if (
          context._lastEntityValue !== undefined &&
          !isEqual(context._lastEntityValue, entityValue)
        ) {
          const oldEntityValues: SelectValue[] = Array.isArray(context._lastEntityValue)
            ? context._lastEntityValue
            : [context._lastEntityValue]
          const newEntityValues = new Set<SelectValue>(
            Array.isArray(entityValue)
              ? entityValue
              : entityValue !== undefined
                ? [entityValue]
                : [],
          )

          if (context.removeMissingOption) {
            for (const oldVal of oldEntityValues) {
              if (!newEntityValues.has(oldVal)) {
                ;(context.removeMissingOption as (value: SelectValue) => void)(oldVal)
              }
            }
          }
        }

        context._lastEntityValue = entityValue

        // Check if all values already exist in options.
        if (
          (Array.isArray(payload) &&
            payload.every((value) => optionValueLookup[value] !== undefined)) ||
          optionValueLookup[payload] !== undefined
        ) {
          return next(payload)
        }

        // Only add missing options when the payload matches the entity value.
        if (!isEqual(payload, entityValue)) return next(payload)

        // Determine label extraction strategy once
        const getLabelForValue = belongsToObjectField
          ? (value: SelectValue) =>
              extractLabelFromRelatedObject(value, belongsToObjectField, initialEntityObject)
          : (value: SelectValue) => extractLabelFromHistoricalOptions(value, historicalOptions!)

        // Handle both array and single values
        const values: SelectValue[] = Array.isArray(payload) ? payload : [payload]

        values.forEach((value) => {
          if (optionValueLookup[value] !== undefined) return

          const label = getLabelForValue(value)

          if (context.addMissingOption) {
            ;(context.addMissingOption as (value: SelectValue, label?: string) => void)(
              value,
              label,
            )
          }
        })

        return next(payload)
      })
    })
  })
}

export default addOrRemoveMissingEntityObjectOption
