<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useDisplayEntityAttribute } from './useDisplayEntityAttributes.ts'
import { isEmpty } from './utils.ts'

import type { OutputMode } from './types.ts'

interface Props {
  object: ObjectLike
  attribute: EntityAttribute
  mode?: OutputMode
  inlineEditable?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'view',
})

const { entityAttributes: entityAttributesConfig } = useSharedVisualConfig()
const { field } = useDisplayEntityAttribute(props)
</script>

<template>
  <template v-if="field && !isEmpty(field.value)">
    <CommonLink
      v-if="field.link"
      v-bind="$attrs"
      :link="field.link"
      :class="entityAttributesConfig.classes.link"
      external
      open-in-new-tab
    >
      <Component
        :is="field.component"
        :attribute="field.attribute"
        :value="field.value"
        :config="entityAttributesConfig"
        :mode="mode"
      />
    </CommonLink>
    <Component
      v-bind="$attrs"
      :is="field.component"
      v-else
      :attribute="field.attribute"
      :value="field.value"
      :config="entityAttributesConfig"
      :mode="mode"
    />
  </template>
  <template v-else>
    <span v-bind="$attrs"> - </span>
  </template>
</template>
