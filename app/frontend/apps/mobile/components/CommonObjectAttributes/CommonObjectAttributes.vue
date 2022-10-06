<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Component } from 'vue'
import { computed } from 'vue'
import { keyBy } from 'lodash-es'
import type { Dictionary } from 'lodash'
import { camelize } from '@shared/utils/formatter'
import type {
  ObjectAttributeValue,
  ObjectManagerFrontendAttribute,
} from '@shared/graphql/types'
import { useSessionStore } from '@shared/stores/session'
import type { AttributeDeclaration, ObjectLike } from './types'
import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '../CommonSectionMenu/CommonSectionMenuItem.vue'

export interface Props {
  object: ObjectLike
  attributes: ObjectManagerFrontendAttribute[]
}

const props = defineProps<Props>()

const attributesDeclarations = import.meta.glob<AttributeDeclaration>(
  './Attribute*/index.ts',
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

const attributesObject = computed<Dictionary<ObjectAttributeValue>>(() => {
  return keyBy(props.object.objectAttributeValues || {}, 'attribute.name')
})

const getValue = (key: string) => {
  if (key in attributesObject.value) {
    return attributesObject.value[key].value
  }
  if (key in props.object) {
    return props.object[key]
  }
  return props.object[camelize(key)]
}

const isEmpty = (value: unknown) => {
  if (Array.isArray(value)) {
    return value.length === 0
  }
  // null or undefined or ''
  return value == null || value === ''
}

const session = useSessionStore()

const skipAttributes = ['name']

interface AttributeField {
  attribute: ObjectManagerFrontendAttribute
  component: Component
  value: unknown
}

const fields = computed<AttributeField[]>(() => {
  return props.attributes
    .map((attribute) => {
      let value = getValue(attribute.name)

      if (typeof value !== 'boolean' && !value) {
        value = attribute.dataOption?.default
      }

      return {
        attribute,
        component: definitionsByType[attribute.dataType],
        value,
      }
    })
    .filter(({ attribute, value, component }) => {
      if (!component) return false

      const dataOption = attribute.dataOption || {}

      if (
        'permission' in dataOption &&
        !session.hasPermission(dataOption.permission)
      ) {
        return false
      }

      if (isEmpty(value)) {
        return false
      }

      return !skipAttributes.includes(attribute.name)
    })
})
</script>

<template>
  <CommonSectionMenu v-if="fields.length">
    <template v-for="field of fields" :key="field.attribute.name">
      <CommonSectionMenuItem :label="field.attribute.display">
        <!-- TODO link template might have #{}, but we don't have access to those, it should come from backend -->
        <CommonLink
          v-if="field.attribute.dataOption?.linktemplate"
          :link="field.attribute.dataOption?.linktemplate"
          class="cursor-pointer text-blue"
        >
          <Component
            :is="field.component"
            :attribute="field.attribute"
            :value="field.value"
          />
        </CommonLink>
        <Component
          :is="field.component"
          v-else
          :attribute="field.attribute"
          :value="field.value"
        />
      </CommonSectionMenuItem>
    </template>
    <slot name="after-fields" />
  </CommonSectionMenu>
</template>
