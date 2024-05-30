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
  }>(),
  {
    showBackdrop: true,
    teleportTo: '#page-main-content',
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
        class="bg-alpha-100 dark:bg-alpha-800 absolute bottom-0 left-0 right-0 top-0 z-10 h-full w-full"
        role="presentation"
        tabindex="-1"
        aria-hidden="true"
        @click="!noCloseOnBackdropClick && $emit('click-background')"
      />
    </teleport>
  </component>
</template>
