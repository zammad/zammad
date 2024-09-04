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
    class="group flex cursor-default justify-between rounded-md px-2 py-2.5 text-base font-normal leading-snug text-stone-200 focus-within:text-black focus-within:outline focus-within:outline-1 focus-within:-outline-offset-1 focus-within:outline-blue-800 hover:bg-blue-600 hover:text-black dark:text-neutral-500 dark:focus-within:text-white dark:hover:bg-blue-900 hover:dark:text-white"
    :class="{ 'cursor-pointer': collapsible }"
    @click="collapsible && $emit('toggle-collapsed', title)"
    @keydown.enter="collapsible && $emit('toggle-collapsed', title)"
  >
    <slot name="title">
      <h4
        class="grow select-none text-base text-current ltr:mr-auto rtl:ml-auto"
      >
        {{ $t(title) }}
      </h4>
    </slot>

    <CollapseButton
      v-if="collapsible"
      :collapsed="collapsed"
      :owner-id="id"
      no-padded
      class="opacity-0 focus-visible:bg-transparent focus-visible:text-black group-hover:text-black group-hover:opacity-100 rtl:order-1 dark:focus-visible:text-white dark:group-hover:text-white"
      orientation="vertical"
      @keydown.enter="collapsible && $emit('toggle-collapsed', title)"
    />
  </header>
</template>
