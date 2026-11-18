<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useSlots, useTemplateRef, type SetupContext } from 'vue'

import { useFormGroupPairing } from './composables/useFormGroupPairing.ts'
import { getFormGroupClasses } from './initializeFormGroupClasses.ts'

const props = defineProps<{
  containerClass?: string
  help?: string
  showDirtyMark?: boolean
  halfSizeFields?: boolean
}>()

const slots: SetupContext['slots'] = useSlots()

const hasHelp = computed(() => slots.help || props.help)

const classMap = getFormGroupClasses()

useFormGroupPairing(useTemplateRef<HTMLDivElement>('container'), () => props.halfSizeFields)
</script>

<template>
  <div
    ref="container"
    v-bind="$attrs"
    :class="[
      containerClass,
      classMap.container,
      {
        [classMap.bottomMargin]: !hasHelp,
        [classMap.dirtyMark]: showDirtyMark,
        'form-group-half-size-fields': halfSizeFields,
      },
    ]"
  >
    <slot />
  </div>
  <div v-if="hasHelp" class="pt-1" :class="[classMap.bottomMargin, classMap.help]">
    <slot name="help">
      {{ help }}
    </slot>
  </div>
</template>
