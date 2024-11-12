// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { keyBy, get } from 'lodash-es'
import { computed } from 'vue'

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { ObjectAttributeValue } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { camelize } from '#shared/utils/formatter.ts'

import type { AttributeDeclaration } from './types.ts'
import type { Dictionary } from 'ts-essentials'
import type { Component } from 'vue'

export interface ObjectAttributesDisplayOptions {
  object: ObjectLike
  attributes: ObjectAttribute[]
  skipAttributes?: string[]
  accessors?: Record<string, string>
}

interface AttributeField {
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

export const useDisplayObjectAttributes = (
  options: ObjectAttributesDisplayOptions,
) => {
  const attributesObject = computed<Dictionary<ObjectAttributeValue>>(() => {
    return keyBy(options.object.objectAttributeValues || {}, 'attribute.name')
  })

  const getValue = (key: string) => {
    const accessor = options.accessors?.[key]
    if (accessor) {
      return get(options.object, accessor)
    }
    if (key in attributesObject.value) {
      return attributesObject.value[key].value
    }
    if (key in options.object) {
      return options.object[key]
    }
    return options.object[camelize(key)]
  }

  const isEmpty = (value: unknown) => {
    if (Array.isArray(value)) {
      return value.length === 0
    }
    // null or undefined or ''
    return value == null || value === ''
  }

  const getLink = (name: string) => {
    const attribute = attributesObject.value[name]
    return attribute?.renderedLink || null
  }

  const session = useSessionStore()

  const fields = computed<AttributeField[]>(() => {
    return options.attributes
      .filter((attribute) => !attribute.isStatic)
      .map((attribute) => {
        let value = getValue(attribute.name)

        if (typeof value !== 'boolean' && !value) {
          value = attribute.dataOption?.default
        }

        return {
          attribute,
          component: definitionsByType[attribute.dataType],
          value,
          link: getLink(attribute.name),
        }
      })
      .filter(({ attribute, value, component }) => {
        if (!component) return false

        const dataOption = attribute.dataOption || {}

        if (
          'permission' in dataOption &&
          dataOption.permission &&
          !session.hasPermission(dataOption.permission)
        ) {
          return false
        }

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
