<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useDisplayObjectAttribute } from './useDisplayObjectAttributes.ts'
import { isEmpty } from './utils.ts'

import type { OutputMode } from './types.ts'

interface Props {
  mode?: OutputMode
  object: ObjectLike
  attribute: ObjectAttribute
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'view',
})

const { objectAttributes: objectAttributesConfig } = useSharedVisualConfig()
const { field } = useDisplayObjectAttribute(props)
</script>

<template>
  <template v-if="field && !isEmpty(field.value)">
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
  </template>
  <template v-else>-</template>
</template>
