<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import { EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/extensions/AiAssistantTextTools.ts'
import { getAiAssistantTextToolsClasses } from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantTextTools/initializeAiAssistantTextToolsClasses.ts'
import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { useAiAssistantTextToolsStore } from '#shared/stores/aiAssistantTextTools.ts'

import type { FormKitNode } from '@formkit/core'
import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
  formContext?: FormFieldContext<FieldEditorProps>
}>()

const emit = defineEmits<{
  close: []
  action: []
  'hide-action-bar': [boolean]
  'show-ai-text-loader': [boolean]
}>()

const meta = props.formContext?.meta || {}
const fieldName = meta[EXTENSION_NAME]?.groupNodeName
const { formId } = props.formContext!

const groupField = getNodeByName(formId as string, fieldName as string) as
  | FormKitNode<number>
  | undefined

const groupId = ref(groupField?.value)

groupField?.on('commit', ({ payload }) => {
  groupId.value = payload
})

onBeforeUnmount(() => {
  groupField?.off('commit')
})

const smartEditorClasses = getAiAssistantTextToolsClasses()

const { lookupResult } = useAiAssistantTextToolsStore()

const textToolsList = computed(() => lookupResult(groupId.value)?.value)

const { notify } = useNotifications()

const hasSelection = computed(
  () => props.editor?.state.selection.anchor !== props.editor?.state.selection.head,
)

const actions = computed(
  () =>
    textToolsList.value?.aiAssistanceTextToolsList.map((tool) => ({
      key: tool.id,
      label: tool.name,
      disabled: !hasSelection.value,
      command: () => {
        emit('action')
        props.editor!.commands.modifyTextWithAi(tool.id)
      },
    })) ?? [],
)

onMounted(() => {
  if (hasSelection.value) return

  nextTick(() => {
    emit('close')

    notify({
      id: 'ai-assistant-text-tools-no-selection',
      type: NotificationTypes.Info,
      message: __('Please select some text first.'),
    })
  })
})
</script>

<template>
  <div v-if="actions.length" :class="smartEditorClasses.popover.base">
    <ul ref="list">
      <li v-for="action in actions" :key="action.key" :class="smartEditorClasses.popover.item">
        <button
          :disabled="action.disabled"
          :class="smartEditorClasses.popover.button"
          class="disabled:pointer-events-none disabled:opacity-60"
          @click="action.command"
        >
          {{ $t(action.label) }}
        </button>
      </li>
    </ul>
  </div>
</template>

<style>
[data-theme='light'] [contenteditable='false'][name='body'] {
  color: #a0a3a6;

  * {
    color: currentColor;
  }
}

[contenteditable='false'][name='body'],
[data-theme='dark'] [contenteditable='false'][name='body'] {
  color: #999;

  * {
    color: currentColor;
  }
}

[data-theme='light'] [contenteditable='false'][name='body'] ::selection {
  color: #585856;
  background: transparent;
}

[contenteditable='false'][name='body'] ::selection,
[data-theme='dark'] [contenteditable='false'][name='body'] ::selection {
  color: #d1d1d1;
  background: transparent;
}
</style>
