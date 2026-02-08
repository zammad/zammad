<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener } from '@vueuse/core'
import { computed, ref } from 'vue'

import type { ActionMenuProps } from '#shared/components/Form/fields/FieldEditor/FieldEditorActionMenu/types.ts'
import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import type { PopupItemDescriptor } from '#mobile/components/CommonSectionPopup/types.ts'

defineEmits<{
  hide: []
  blur: []
  'click-action': [EditorButton, MouseEvent]
}>()

const props = withDefaults(defineProps<ActionMenuProps>(), {
  visible: true,
})

const showPopup = ref(false)

const handleClose = () => {
  showPopup.value = false
}

const messages = computed<PopupItemDescriptor[]>(() =>
  Array.isArray(props.actions)
    ? props.actions?.reduce((acc, action) => {
        if (!action.show || action.show()) {
          acc.push({
            type: 'button',
            label: action.label || action.name,
            buttonVariant: 'secondary',
            buttonPrefixIcon: action.icon,
            buttonAlign: 'start',
            onAction: () => {
              action.command?.(new MouseEvent('click'))
            },
          })
        }
        return acc
      }, [] as PopupItemDescriptor[])
    : [],
)

useEventListener('click', (event: MouseEvent) => {
  const { editor } = props

  if (!editor || !props.targetId) return
  if (showPopup.value) return

  const { target } = event

  const targetElementWithId = (target as HTMLElement)?.closest(`#${CSS.escape(props.targetId)}`)

  if (!targetElementWithId) return
  showPopup.value = true
})

defineExpose({
  close: handleClose,
})
</script>

<template>
  <CommonSectionPopup
    v-model:state="showPopup"
    :messages="messages"
    no-refocus
    @close="handleClose"
  />
</template>
