<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
export interface Props {
  label?: string
  labelPlaceholder?: string[]
  link?: string
  linkExternal?: boolean
  icon?: string
}

defineProps<Props>()
</script>

<template>
  <component
    :is="link ? 'CommonLink' : 'button'"
    :link="link"
    :external="link && linkExternal"
    class="block cursor-pointer leading-4 hover:no-underline focus-visible:!outline-none"
    data-test-id="popover-menu-item"
  >
    <CommonLabel
      class="gap-2 group-focus-within:text-white group-hover:text-black group-hover:group-focus-within:text-white dark:group-hover:text-white"
      :prefix-icon="icon"
      icon-color="text-stone-200 dark:text-neutral-500 group-hover:text-black dark:group-hover:text-white group-focus-within:text-white group-hover:group-focus-within:text-white"
    >
      <slot>{{ i18n.t(label, ...(labelPlaceholder || [])) }}</slot>
    </CommonLabel>
  </component>
</template>
