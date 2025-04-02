<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useDisplayObjectAttributes } from './useDisplayObjectAttributes.ts'

import type { OutputMode } from './types.ts'

export interface Props {
  mode?: OutputMode
  object: ObjectLike
  attributes: ObjectAttribute[]
  skipAttributes?: string[]
  alwaysShowAfterFields?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'view',
})

const { fields } = useDisplayObjectAttributes(props)
const { objectAttributes: objectAttributesConfig } = useSharedVisualConfig()
</script>

<template>
  <Component
    :is="objectAttributesConfig.outer"
    v-if="fields.length || props.alwaysShowAfterFields"
  >
    <template v-for="field of fields" :key="field.attribute.name">
      <Component
        :is="objectAttributesConfig.wrapper"
        :label="field.attribute.display"
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
          />
        </CommonLink>
        <Component
          :is="field.component"
          v-else
          :attribute="field.attribute"
          :value="field.value"
          :config="objectAttributesConfig"
          :mode="mode"
        />
      </Component>
    </template>
    <slot name="after-fields" />
  </Component>
</template>
