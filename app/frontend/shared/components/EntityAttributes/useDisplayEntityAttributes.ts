// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed } from 'vue'

import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'
import type { ObjectAttributeValue } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { getLink, getValue, isEmpty, isInlineAttributeEditable } from './utils.ts'

import type { AttributeDeclaration, InlineEditable } from './types.ts'
import type { Dictionary } from 'ts-essentials'
import type { Component } from 'vue'

interface BaseEntityAttributeDisplayOptions {
  object: ObjectLike
}

export interface EntityAttributeDisplayOptions extends BaseEntityAttributeDisplayOptions {
  attribute: EntityAttribute
}

export interface EntityAttributesDisplayOptions extends BaseEntityAttributeDisplayOptions {
  attributes: EntityAttribute[]
  skipAttributes?: string[]
  inlineEditable?: InlineEditable
  includeStatic?: boolean
}

export interface AttributeField {
  attribute: EntityAttribute
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

export const useDisplayEntityAttribute = (options: EntityAttributeDisplayOptions) => {
  const attributesObject = computed<Dictionary<ObjectAttributeValue>>(() => {
    return keyBy(options.object.objectAttributeValues || {}, 'attribute.name')
  })

  const field = computed<AttributeField>(() => {
    const { attribute, object } = options

    return {
      attribute,
      component: definitionsByType[attribute.dataType],
      value: getValue(attribute.name, object, attributesObject.value, attribute),
      link: getLink(attribute.name, attributesObject.value),
    }
  })
  return { field }
}

export const useDisplayEntityAttributes = (options: EntityAttributesDisplayOptions) => {
  const attributesObject = computed<Dictionary<ObjectAttributeValue>>(() => {
    return keyBy(options.object.objectAttributeValues || {}, 'attribute.name')
  })

  const fields = computed<AttributeField[]>(() => {
    return options.attributes
      .filter((attribute) => options.includeStatic || !attribute.isStatic)
      .map((attribute) => ({
        attribute: {
          ...attribute,
          id: `${attribute.name}-${options.object.internalId}`,
        },
        component: definitionsByType[attribute.dataType],
        value: getValue(attribute.name, options.object, attributesObject.value, attribute),
        link: getLink(attribute.name, attributesObject.value),
      }))
      .filter(({ attribute, value, component }) => {
        if (!component) return false

        if (isEmpty(value) && !isInlineAttributeEditable(attribute.name, options.inlineEditable)) {
          return false
        }

        return !options.skipAttributes?.includes(attribute.name)
      })
  })

  return {
    fields,
  }
}
