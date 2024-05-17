<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import type { ObjectManagerFrontendAttribute } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useDisplayObjectAttributes } from './useDisplayObjectAttributes.ts'

export interface Props {
  object: ObjectLike
  attributes: ObjectManagerFrontendAttribute[]
  skipAttributes?: string[]
  accessors?: Record<string, string>
  alwaysShowAfterFields?: boolean
}

const props = defineProps<Props>()

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
          />
        </CommonLink>
        <Component
          :is="field.component"
          v-else
          :attribute="field.attribute"
          :value="field.value"
        />
      </Component>
    </template>
    <slot name="after-fields" />
  </Component>
</template>
