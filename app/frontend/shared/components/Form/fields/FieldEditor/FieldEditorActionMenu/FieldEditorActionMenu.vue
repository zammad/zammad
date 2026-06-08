<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import { useTemplateRef } from 'vue'

import type { ActionMenuProps } from '#shared/components/Form/fields/FieldEditor/FieldEditorActionMenu/types.ts'
import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { getEditorComponents } from '#shared/components/Form/initializeFieldEditor.ts'

const actionMenuComponent = getEditorComponents().actionMenu

const props = defineProps<ActionMenuProps>()

const actionMenuInstance = useTemplateRef<{ close: () => void }>('action-menu')

defineEmits<{
  'click-action': [EditorButton, MouseEvent]
}>()

defineExpose({
  close: () => actionMenuInstance.value?.close(),
})
</script>

<template>
  <component
    v-bind="props"
    :is="actionMenuComponent"
    ref="action-menu"
    @click-action="
      (action: EditorButton, event: MouseEvent) => $emit('click-action', action, event)
    "
  >
    <template #default="slotProps">
      <slot v-bind="slotProps" />
    </template>
  </component>
</template>
