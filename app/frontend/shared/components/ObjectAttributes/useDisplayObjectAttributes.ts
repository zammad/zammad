// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed } from 'vue'

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { ObjectAttributeValue } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { getLink, getValue, isEmpty } from './utils.ts'

import type { AttributeDeclaration } from './types.ts'
import type { Dictionary } from 'ts-essentials'
import type { Component } from 'vue'

interface BaseObjectAttributeDisplayOptions {
  object: ObjectLike
}

export interface ObjectAttributeDisplayOptions
  extends BaseObjectAttributeDisplayOptions {
  attribute: ObjectAttribute
}

export interface ObjectAttributesDisplayOptions
  extends BaseObjectAttributeDisplayOptions {
  skipAttributes?: string[]
  attributes: ObjectAttribute[]
}

export interface AttributeField {
  attribute: ObjectAttribute
  component: Component
  value: unknown
  link: Maybe<string>
}

const attributesDeclarations = import.meta.glob<AttributeDeclaration>(
  './attributes/Attribute*/index.ts',
  { eager: true, import: 'default' },
)

const definitionsByType = Object.values(attributesDeclarations).reduce(
  (acc, declaration) => {
    declaration.dataTypes.forEach((type) => {
      acc[type] = declaration.component
    })
    return acc
  },
  {} as Record<string, Component>,
)

export const useDisplayObjectAttribute = (
  options: ObjectAttributeDisplayOptions,
) => {
  const attributesObject = computed<Dictionary<ObjectAttributeValue>>(() => {
    return keyBy(options.object.objectAttributeValues || {}, 'attribute.name')
  })

  const field = computed<AttributeField>(() => {
    const { attribute, object } = options

    return {
      attribute,
      component: definitionsByType[attribute.dataType],
      value: getValue(
        attribute.name,
        object,
        attributesObject.value,
        attribute,
      ),
      link: getLink(attribute.name, attributesObject.value),
    }
  })
  return { field }
}

export const useDisplayObjectAttributes = (
  options: ObjectAttributesDisplayOptions,
) => {
  const attributesObject = computed<Dictionary<ObjectAttributeValue>>(() => {
    return keyBy(options.object.objectAttributeValues || {}, 'attribute.name')
  })

  const fields = computed<AttributeField[]>(() => {
    return options.attributes
      .filter((attribute) => !attribute.isStatic)
      .map((attribute) => ({
        attribute,
        component: definitionsByType[attribute.dataType],
        value: getValue(
          attribute.name,
          options.object,
          attributesObject.value,
          attribute,
        ),
        link: getLink(attribute.name, attributesObject.value),
      }))
      .filter(({ attribute, value, component }) => {
        if (!component) return false

        if (isEmpty(value)) {
          return false
        }

        return !options.skipAttributes?.includes(attribute.name)
      })
  })

  return {
    fields,
  }
}
