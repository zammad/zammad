<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { ButtonSize } from '../CommonButton/types'

const { isTouchDevice } = useTouchDevice()

interface Props {
  ownerId: string
  collapsed?: boolean
  orientation?: 'horizontal' | 'vertical'
  expandLabel?: string
  collapseLabel?: string
  inverse?: boolean
  variant?: 'none' | 'tertiary-gray'
  noPadded?: boolean
  buttonClass?: string
  visible?: boolean
  size?: ButtonSize
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'horizontal',
  collapsed: false,
  expandLabel: __('Expand this element'),
  collapseLabel: __('Collapse this element'),
  size: 'small',
})

defineEmits<{
  'toggle-collapse': []
}>()

const locale = useLocaleStore()

const collapseButtonIcon = computed(() => {
  if (props.orientation === 'vertical') return props.collapsed ? 'arrows-expand' : 'arrows-collapse'

  if (
    (props.inverse && locale.localeData?.dir !== EnumTextDirection.Rtl) ||
    (!props.inverse && locale.localeData?.dir === EnumTextDirection.Rtl)
  )
    return props.collapsed ? 'arrow-bar-left' : 'arrow-bar-right'

  return props.collapsed ? 'arrow-bar-right' : 'arrow-bar-left'
})

// :TODO think if we add this variant as a Variant of CommonButton
const variantClass = computed(() => {
  if (props.variant === 'tertiary-gray')
    return 'bg-neutral-500 focus-visible:bg-blue-800 active:dark:bg-blue-800 active:bg-blue-800 hover:bg-blue-600 hover:dark:bg-blue-900 text-black dark:bg-gray-200 dark:text-white'

  return ''
})
</script>

<template>
  <div
    class="flex items-center justify-center focus-within:opacity-100 hover:opacity-100"
    :class="{
      'opacity-0': !isTouchDevice && !visible,
      'p-2': !noPadded,
    }"
  >
    <CommonButton
      v-tooltip="$t(collapsed ? expandLabel : collapseLabel)"
      class="hover:outline-transparent focus:outline-transparent focus-visible:outline-transparent dark:hover:outline-transparent dark:focus:outline-transparent"
      variant="none"
      :class="[variantClass, buttonClass]"
      :icon="collapseButtonIcon"
      :aria-expanded="!collapsed"
      :size="size"
      :aria-controls="ownerId"
      :data-test-id="`controls-${ownerId}`"
      @click="$emit('toggle-collapse')"
    />
  </div>
</template>
