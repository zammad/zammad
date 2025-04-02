<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { Link } from '#shared/types/router.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { Variant } from '#desktop/components/CommonPopoverMenu/types.ts'

export interface Props {
  label?: string
  ariaLabel?: string | ((entity?: ObjectLike) => string)
  labelPlaceholder?: string[]
  link?: Link
  linkExternal?: boolean
  variant?: Variant
  icon?: string
  labelClass?: string
  iconClass?: string
}

const props = defineProps<Props>()

const variantClass = computed(() => {
  if (props.variant === 'secondary') return 'text-blue-800'
  if (props.variant === 'danger') return 'text-red-500'
  return 'group-focus-within:text-white group-hover:text-black group-hover:group-focus-within:text-white dark:group-hover:text-white'
})

const iconColor = computed(() => {
  if (props.iconClass) return props.iconClass
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
    class="group block cursor-pointer leading-snug hover:no-underline! focus-visible:!outline-hidden"
    data-test-id="popover-menu-item"
  >
    <slot name="leading" />
    <CommonLabel
      class="gap-2 text-left"
      :class="[labelClass, variantClass]"
      :prefix-icon="icon"
      :icon-color="iconColor"
    >
      <slot>{{ i18n.t(label, ...(labelPlaceholder || [])) }}</slot>
    </CommonLabel>
  </component>
</template>
