<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

const props = defineProps<{
  direction: 'start' | 'end'
}>()

defineEmits<{
  'scroll-start': [direction: 'start' | 'end']
  'scroll-stop': []
}>()

const locale = useLocaleStore()

const isLtrLocale = computed(() => locale.localeData?.dir === EnumTextDirection.Ltr)

const ariaLabel = computed(() =>
  props.direction === 'start' ? i18n.t('Scroll to start') : i18n.t('Scroll to end'),
)

const classNamesPerDirection = computed(() => {
  const baseClass = props.direction === 'start' ? 'inset-s-0' : 'inset-e-0'

  const isVisualStart = isLtrLocale.value === (props.direction === 'start')

  const directionClass = isVisualStart ? 'ScrollButtonStart' : 'ScrollButtonEnd'

  return `${baseClass} ${directionClass}`
})

const iconNamePerDirection = computed(() => {
  if (isLtrLocale.value) {
    return props.direction === 'start' ? 'arrow-left' : 'arrow-right'
  }
  return props.direction === 'start' ? 'arrow-right' : 'arrow-left'
})
</script>

<template>
  <div
    class="group absolute top-0 z-55 flex h-full w-25 items-center justify-center"
    :class="classNamesPerDirection"
    :aria-label="ariaLabel"
    role="button"
    tabindex="0"
    @focusin="$emit('scroll-start', direction)"
    @focusout="$emit('scroll-stop')"
    @mouseover="$emit('scroll-start', direction)"
    @mouseleave="$emit('scroll-stop')"
  >
    <div
      class="flex size-9 items-center justify-center rounded-lg bg-blue-600 text-black group-hover:bg-blue-800 group-hover:text-white dark:bg-blue-900 dark:text-white"
    >
      <CommonIcon :name="iconNamePerDirection" size="small" decorative />
    </div>
  </div>
</template>

<style scoped>
.ScrollButtonStart {
  background: linear-gradient(270deg, rgba(237, 241, 242, 0), var(--color-blue-200));
}

.ScrollButtonEnd {
  background: linear-gradient(90deg, rgba(237, 241, 242, 0), var(--color-blue-200));
}

[data-theme='dark'] {
  .ScrollButtonStart {
    background: linear-gradient(270deg, rgba(50, 50, 52, 0), var(--color-gray-500));
  }

  .ScrollButtonEnd {
    background: linear-gradient(90deg, rgba(50, 50, 52, 0), var(--color-gray-500));
  }
}
</style>
