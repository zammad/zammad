<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useSlots } from 'vue'

import { getFormGroupClasses } from './initializeFormGroupClasses.ts'

const props = defineProps<{ help?: string; showDirtyMark?: boolean }>()

const slots = useSlots()

const hasHelp = computed(() => slots.help || props.help)

const classMap = getFormGroupClasses()
</script>

<template>
  <div
    v-bind="$attrs"
    :class="[
      classMap.container,
      {
        'mb-4': !hasHelp,
        [classMap.dirtyMark]: showDirtyMark,
      },
    ]"
  >
    <slot />
  </div>
  <div v-if="hasHelp" class="mb-4 pt-1" :class="classMap.help">
    <slot name="help">
      {{ help }}
    </slot>
  </div>
</template>
