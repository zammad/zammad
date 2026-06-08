<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { isInlineAttributeEditable } from '#shared/components/ObjectAttributes/utils.ts'
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useDisplayObjectAttributes } from './useDisplayObjectAttributes.ts'
import { useInlineEditable } from './useInlineEditable.ts'

import type { InlineEditable, OutputMode } from './types.ts'

export interface Props {
  mode?: OutputMode
  object: ObjectLike
  attributes: ObjectAttribute[]
  skipAttributes?: string[]
  inlineEditable?: InlineEditable
  includeStatic?: boolean
  alwaysShowAfterFields?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'view',
})

const { fields } = useDisplayObjectAttributes(props)
const { objectAttributes: objectAttributesConfig } = useSharedVisualConfig()

const config = toRef(useApplicationStore(), 'config')

const getLabel = (attribute: ObjectAttribute) =>
  attribute.dataOption?.display_config
    ? config.value[attribute.dataOption.display_config]
    : attribute.display

const getDisplayLabel = (attribute: ObjectAttribute) => {
  // If inline editable by default it shows then the field label
  if (isInlineAttributeEditable(attribute.name, props.inlineEditable)) return null

  return getLabel(attribute)
}

useInlineEditable(props, fields)
</script>

<template>
  <Component :is="objectAttributesConfig.outer" v-if="fields.length || props.alwaysShowAfterFields">
    <template v-for="field of fields" :key="field.attribute.name">
      <Component
        :is="objectAttributesConfig.wrapper"
        :label="getDisplayLabel(field.attribute)"
        :attribute="field.attribute"
      >
        <CommonLink
          v-if="field.link"
          :link="field.link"
          :class="objectAttributesConfig.classes.link"
        >
          <Component
            :is="field.component"
            :attribute="field.attribute"
            :value="field.value"
            :config="objectAttributesConfig"
            :mode="mode"
            :inline-editable="inlineEditable"
          />
        </CommonLink>
        <Component
          :is="field.component"
          v-else
          :attribute="field.attribute"
          :value="field.value"
          :config="objectAttributesConfig"
          :mode="mode"
          :inline-editable="inlineEditable"
        />
      </Component>
    </template>
    <slot name="after-fields" />
  </Component>
</template>
