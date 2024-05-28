<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'

interface Props {
  collapsed?: boolean
  title: string
  id: string
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
  <!--  eslint-disable vuejs-accessibility/no-static-element-interactions-->
  <header
    class="group/heading flex cursor-default justify-between px-0 text-base font-normal leading-snug text-stone-200 active:text-stone-200 dark:text-neutral-500 dark:active:text-neutral-500"
    :class="{ 'cursor-pointer': collapsible }"
    @click="collapsible && $emit('toggle-collapsed', title)"
    @keydown.enter="collapsible && $emit('toggle-collapsed', title)"
  >
    <slot name="title">
      <h4 class="grow text-base ltr:mr-auto rtl:ml-auto">
        {{ $t(title) }}
      </h4>
    </slot>
    <CollapseButton
      v-if="collapsible"
      :is-collapsed="collapsed"
      :owner-id="id"
      group="heading"
      class="mt-0.5 rtl:order-1"
      orientation="vertical"
      @keydown.enter="collapsible && $emit('toggle-collapsed', title)"
    />
  </header>
</template>

<style scoped>
header:hover :deep(.collapse-button) {
  @apply outline outline-1 outline-offset-1 outline-blue-600 dark:outline-blue-900;
}
</style>
