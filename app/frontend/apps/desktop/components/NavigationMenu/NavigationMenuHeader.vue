<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'

interface Props {
  collapsed?: boolean
  title: string
  collapsible?: boolean
}

defineEmits<{
  'toggle-collapsed': [string]
}>()

withDefaults(defineProps<Props>(), {
  collapsed: false,
})
</script>

<template>
  <header
    class="flex cursor-default group/heading justify-between px-0 text-base font-normal leading-5 text-stone-200 dark:text-neutral-500 active:text-stone-200 dark:active:text-neutral-500"
    :class="{ 'cursor-pointer': collapsible }"
    @click="collapsible && $emit('toggle-collapsed', title)"
  >
    <slot name="title">
      <h4 class="grow text-base rtl:ml-auto ltr:mr-auto">
        {{ $t(title) }}
      </h4>
    </slot>
    <CollapseButton
      v-if="collapsible"
      :is-collapsed="collapsed"
      group="heading"
      class="rtl:order-1 mt-0.5"
      orientation="vertical"
    />
  </header>
</template>

<style scoped>
header:hover :deep(.collapse-button) {
  @apply outline outline-1 outline-offset-1 outline-blue-600 dark:outline-blue-900;
}
</style>
