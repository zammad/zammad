<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
withDefaults(
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
</script>

<template>
  <component :is="tag" :role="tag === 'div' ? 'dialog' : 'complementary'">
    <slot />

    <Teleport
      v-if="showBackdrop"
      :disabled="disableTeleport"
      :to="fullscreen ? '#app' : teleportTo"
    >
      <div
        class="bg-alpha-900 absolute bottom-0 left-0 right-0 top-0 z-30 h-full w-full"
        :class="backdropClass"
        role="presentation"
        tabindex="-1"
        @click="!noCloseOnBackdropClick && $emit('click-background')"
      />
    </Teleport>
  </component>
</template>
