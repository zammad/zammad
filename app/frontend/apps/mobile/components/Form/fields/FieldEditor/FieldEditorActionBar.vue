<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { nextTick, shallowRef, toRef, ref, defineAsyncComponent, watch } from 'vue'

import useEditorActionHelper from '#shared/components/Form/fields/FieldEditor/composables/useEditorActionHelper.ts'
import type {
  EditorButton,
  EditorContentType,
  EditorCustomPlugins,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { FieldEditorProps } from '#shared/components/Form/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import type { PopupItemDescriptor } from '#mobile/components/CommonSectionPopup/types'
import useEditorActions from '#mobile/components/Form/fields/FieldEditor/useEditorActions.ts'

import ActionToolbar from './FieldEditorActionBar/ActionToolbar.vue'

import type { Selection } from '@tiptap/pm/state'
import type { Editor } from '@tiptap/vue-3'
import type { Except } from 'type-fest'
import type { Component } from 'vue'

const props = defineProps<{
  editor?: Editor
  contentType: EditorContentType
  visible: boolean
  disabledPlugins: EditorCustomPlugins[]
  formContext?: FormFieldContext<FieldEditorProps>
}>()

defineEmits<{
  hide: [boolean?]
  blur: []
}>()

const AiAssistantTextToolsLoadingBanner = defineAsyncComponent(
  () =>
    import(
      '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantLoadingBanner/AiAssistantLoadingBanner.vue'
    ),
)

const editor = toRef(props, 'editor')

const hideActionBarLocally = ref(false)

const { isActive } = useEditorActionHelper(editor)

const { actions } = useEditorActions(editor, props.contentType, props.disabledPlugins)

const subMenuPopupContent = shallowRef<Component | Except<EditorButton, 'subMenu'>[]>()

let currentSelection: Selection | undefined

const subMenuPopupItems = shallowRef<PopupItemDescriptor[]>([])

const popupShown = ref(false)

const handleButtonClick = (action: EditorButton) => {
  if (!action.subMenu) return

  // Save selection before opening the popover
  if (editor.value && !editor.value.state.selection.empty) {
    currentSelection = editor.value?.state.selection
  }

  subMenuPopupContent.value = undefined

  if (Array.isArray(action.subMenu)) {
    subMenuPopupItems.value = action.subMenu.map((item) => ({
      type: 'button',
      label: item.label || item.name,
      buttonVariant: 'secondary',
      buttonPrefixIcon: item.icon,
      buttonAlign: 'start',
      onAction: () => {
        item.command?.(new MouseEvent('click'))
      },
    }))
  } else {
    subMenuPopupContent.value = action.subMenu
  }

  nextTick(() => {
    popupShown.value = true
  })
}

const handleSubMenuClick = (clearPopupContent = false) => {
  popupShown.value = false

  if (clearPopupContent) subMenuPopupContent.value = undefined

  editor.value?.commands.focus()

  // Restore selection after closing the popup.
  if (editor.value && currentSelection) {
    editor.value.commands.setTextSelection(currentSelection)
    currentSelection = undefined
  }
}

const showAiAssistantTextToolsLoadingBanner = ref(false)

const { config } = storeToRefs(useApplicationStore())

watch(
  () => editor.value?.storage?.showAiTextLoader,
  (showLoader) => {
    showAiAssistantTextToolsLoadingBanner.value = !!showLoader
    hideActionBarLocally.value = !!showLoader
  },
)
</script>

<template>
  <div>
    <ActionToolbar
      v-show="!hideActionBarLocally && visible"
      :editor="editor"
      :visible="visible"
      :is-active="isActive"
      :actions="actions"
      @click-action="handleButtonClick"
      @blur="$emit('blur')"
      @hide="$emit('hide')"
    />

    <AiAssistantTextToolsLoadingBanner
      v-if="showAiAssistantTextToolsLoadingBanner && config.ai_assistance_text_tools"
      :editor="editor"
    />

    <CommonSectionPopup
      v-model:state="popupShown"
      :messages="subMenuPopupContent ? undefined : subMenuPopupItems"
      @close="handleSubMenuClick(true)"
    >
      <template #header>
        <component
          :is="subMenuPopupContent"
          v-show="subMenuPopupContent"
          :editor="editor"
          :content-type="contentType"
          :form-context="formContext"
          @action="handleSubMenuClick"
          @close="handleSubMenuClick(true)"
          @hide-action-bar="hideActionBarLocally = $event"
          @show-ai-text-loader="showAiAssistantTextToolsLoadingBanner = $event"
        />
      </template>
    </CommonSectionPopup>
  </div>
</template>
