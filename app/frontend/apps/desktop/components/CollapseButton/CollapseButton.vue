<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

const { isTouchDevice } = useTouchDevice()

interface Props {
  ownerId: string
  isCollapsed?: boolean
  group?: 'heading' | 'sidebar'
  orientation?: 'horizontal' | 'vertical'
  inverse?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'horizontal',
  isCollapsed: false,
})

defineEmits<{
  'toggle-collapse': [MouseEvent]
}>()

const locale = useLocaleStore()

const collapseButtonIcon = computed(() => {
  if (props.orientation === 'vertical')
    return props.isCollapsed ? 'arrows-expand' : 'arrows-collapse'

  if (
    (props.inverse && locale.localeData?.dir !== EnumTextDirection.Rtl) ||
    (!props.inverse && locale.localeData?.dir === EnumTextDirection.Rtl)
  )
    return props.isCollapsed ? 'arrow-bar-left' : 'arrow-bar-right'

  return props.isCollapsed ? 'arrow-bar-right' : 'arrow-bar-left'
})

const parentGroupClass = computed(() => {
  // Tailwindcss must be able to scan the class names to generate CSS
  // https://tailwindcss.com/docs/content-configuration#dynamic-class-names
  switch (props.group) {
    case 'heading':
      return 'group-hover/heading:opacity-100'
    case 'sidebar':
      return 'group-hover/sidebar:opacity-100'
    default:
      return ''
  }
})
</script>

<template>
  <div>
    <CommonButton
      :class="[
        { 'opacity-0 transition-opacity': !isTouchDevice && parentGroupClass },
        'focus:opacity-100',
        parentGroupClass,
      ]"
      class="collapse-button"
      :icon="collapseButtonIcon"
      :aria-expanded="!props.isCollapsed"
      :aria-controls="ownerId"
      :aria-label="
        props.isCollapsed
          ? $t('Expand this element')
          : $t('Collapse this element')
      "
      size="small"
      variant="subtle"
      @click="$emit('toggle-collapse', $event)"
    />
  </div>
</template>
