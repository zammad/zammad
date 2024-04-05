<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

const { isTouchDevice } = useTouchDevice()

interface Props {
  isCollapsed?: boolean
  group?: string
  orientation?: 'horizontal' | 'vertical'
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

  if (locale.localeData?.dir === EnumTextDirection.Rtl)
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
        { 'transition-opacity opacity-0': !isTouchDevice && parentGroupClass },
        'focus:opacity-100',
        parentGroupClass,
      ]"
      class="collapse-button"
      :icon="collapseButtonIcon"
      :aria-label="props.isCollapsed ? $t('expand') : $t('collapse')"
      size="small"
      variant="subtle"
      @click="$emit('toggle-collapse', $event)"
    />
  </div>
</template>
