<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

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
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'horizontal',
  collapsed: false,
})

defineEmits<{
  'toggle-collapse': [MouseEvent]
}>()

const locale = useLocaleStore()

const collapseButtonIcon = computed(() => {
  if (props.orientation === 'vertical')
    return props.collapsed ? 'arrows-expand' : 'arrows-collapse'

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
    return 'bg-neutral-500 focus-visible:bg-blue-800 active:dark:bg-blue-800 focus:dark:bg-blue-800 active:bg-blue-800 focus:bg-blue-800 hover:bg-blue-600 hover:dark:bg-blue-900 text-black dark:bg-gray-200 dark:text-white'

  return ''
})

const labels = computed(() => ({
  expand: props.expandLabel || i18n.t('Expand this element'),
  collapse: props.collapseLabel || i18n.t('Collapse this element'),
}))
</script>

<template>
  <div
    class="flex items-center justify-center focus-within:opacity-100 hover:opacity-100"
    :class="{
      'opacity-0': !isTouchDevice,
      'p-2': !noPadded,
    }"
  >
    <CommonButton
      v-tooltip="collapsed ? labels.expand : labels.collapse"
      class="hover:outline-transparent focus:outline-transparent focus-visible:outline-transparent dark:hover:outline-transparent dark:focus:outline-transparent"
      :class="[variantClass, buttonClass]"
      :icon="collapseButtonIcon"
      :aria-expanded="!collapsed"
      variant="none"
      :aria-controls="ownerId"
      :aria-label="
        collapsed ? $t('Expand this element') : $t('Collapse this element')
      "
      size="small"
      @click="$emit('toggle-collapse', $event)"
    />
  </div>
</template>
