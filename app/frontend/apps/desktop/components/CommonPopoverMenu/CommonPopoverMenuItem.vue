<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

import type { Variant } from '#desktop/components/CommonPopoverMenu/types.ts'

export interface Props {
  label?: string
  ariaLabel?: string | ((entity?: ObjectLike) => string)
  labelPlaceholder?: string[]
  link?: string
  linkExternal?: boolean
  variant?: Variant
  icon?: string
  labelClass?: string
}

const props = defineProps<Props>()

const variantClass = computed(() => {
  if (props.variant === 'secondary') return 'text-blue-800'
  if (props.variant === 'danger') return 'text-red-500'
  return 'group-focus-within:text-white group-hover:text-black group-hover:group-focus-within:text-white dark:group-hover:text-white'
})

const iconColor = computed(() => {
  if (props.variant === 'secondary') return 'text-blue-800'
  if (props.variant === 'danger') return 'text-red-500'
  return 'text-stone-200 dark:text-neutral-500 group-hover:text-black dark:group-hover:text-white group-focus-within:text-white group-hover:group-focus-within:text-white'
})
</script>

<template>
  <component
    :is="link ? 'CommonLink' : 'button'"
    :link="link"
    :external="link && linkExternal"
    class="block cursor-pointer leading-snug hover:no-underline focus-visible:!outline-none"
    data-test-id="popover-menu-item"
  >
    <CommonLabel
      class="gap-2"
      :class="[labelClass, variantClass]"
      :prefix-icon="icon"
      :icon-color="iconColor"
    >
      <slot>{{ i18n.t(label, ...(labelPlaceholder || [])) }}</slot>
    </CommonLabel>
  </component>
</template>
