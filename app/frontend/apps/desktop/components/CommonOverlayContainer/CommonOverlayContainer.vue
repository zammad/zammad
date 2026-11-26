<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useAttrs, useId, useTemplateRef } from 'vue'

import { useCoveringOverlay } from '#desktop/composables/useOverlayCoverage.ts'

const props = withDefaults(
  defineProps<{
    /**
     * The selector of the element to teleport the backdrop to.
     * @example '#test' '.test' 'body'
     * */
    teleportTo?: string
    tag?: 'div' | 'aside'
    fullscreen?: boolean
    showBackdrop?: boolean
    noCloseOnBackdropClick?: boolean
    backdropClass?: string
    disableTeleport?: boolean
  }>(),
  {
    tag: 'div',
    showBackdrop: true,
    teleportTo: '#main-content',
  },
)

defineEmits<{
  'click-background': []
}>()

const fallbackId = useId()

useCoveringOverlay({
  id: String(useAttrs().id ?? fallbackId),
  element: useTemplateRef<HTMLElement>('container'),
  isShown: () => props.showBackdrop,
  coversApplication: () => props.fullscreen,
})
</script>

<template>
  <component :is="tag" ref="container" :role="tag === 'div' ? 'dialog' : 'complementary'">
    <slot />

    <Teleport
      v-if="showBackdrop"
      :disabled="disableTeleport"
      :to="fullscreen ? '#app' : teleportTo"
    >
      <div
        class="absolute inset-0 z-30 size-full bg-alpha-900 print:hidden"
        :class="backdropClass"
        role="presentation"
        tabindex="-1"
        @click="!noCloseOnBackdropClick && $emit('click-background')"
      />
    </Teleport>
  </component>
</template>
