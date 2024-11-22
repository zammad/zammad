<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
withDefaults(
  defineProps<{
    /**
     * @property teleportTo
     * The selector of the element to teleport the backdrop to.
     * @example '#test' '.test' 'body'
     * */
    teleportTo?: string
    tag: 'div' | 'aside'
    showBackdrop?: boolean
    noCloseOnBackdropClick?: boolean
    backdropClass?: string
  }>(),
  {
    showBackdrop: true,
    teleportTo: '#app',
  },
)

defineEmits<{
  'click-background': []
}>()
</script>

<template>
  <component :is="tag" :role="tag === 'div' ? 'dialog' : 'complementary'">
    <slot />

    <teleport v-if="showBackdrop" :to="teleportTo">
      <div
        class="bg-alpha-900 -:z-30 absolute bottom-0 left-0 right-0 top-0 h-full w-full"
        :class="backdropClass"
        role="presentation"
        tabindex="-1"
        @click="!noCloseOnBackdropClick && $emit('click-background')"
      />
    </teleport>
  </component>
</template>
