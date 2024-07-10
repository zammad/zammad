<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, shallowRef, toRef } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import ActionBar from '#shared/components/Form/fields/FieldEditor/ActionBar.vue'
import { getFieldEditorProps } from '#shared/components/Form/initializeFieldEditor.ts'

import useEditorActions, { type EditorButton } from './useEditorActions.ts'

import type { EditorContentType, EditorCustomPlugins } from './types.ts'
import type { Selection } from '@tiptap/pm/state'
import type { Editor } from '@tiptap/vue-3'
import type { Except } from 'type-fest'
import type { Component } from 'vue'

const props = defineProps<{
  editor?: Editor
  contentType: EditorContentType
  visible: boolean
  disabledPlugins: EditorCustomPlugins[]
  formId: string
}>()

defineEmits<{
  hide: []
  blur: []
}>()

const editor = toRef(props, 'editor')

const { actions, isActive } = useEditorActions(
  editor,
  props.contentType,
  props.disabledPlugins,
)

const { popover, popoverTarget, open, close } = usePopover()

const editorProps = getFieldEditorProps()

const subMenuPopoverContent = shallowRef<
  Component | Except<EditorButton, 'subMenu'>[]
>()

let currentSelection: Selection | undefined

const handleButtonClick = (action: EditorButton, event: MouseEvent) => {
  if (!action.subMenu) return

  // Save selection before opening the popover
  if (editor.value && !editor.value.state.selection.empty) {
    currentSelection = editor.value?.state.selection
  }

  subMenuPopoverContent.value = action.subMenu
  popoverTarget.value = event.currentTarget as HTMLDivElement

  nextTick(() => {
    open()
  })
}

const handleSubMenuClick = () => {
  close()
  editor.value?.commands.focus()

  // Restore selection after closing the popover
  if (editor.value && currentSelection) {
    editor.value.commands.setTextSelection(currentSelection)
    currentSelection = undefined
  }
}
</script>

<template>
  <ActionBar
    v-show="visible || editorProps.actionBar.visible"
    :editor="editor"
    :visible="visible"
    :is-active="isActive"
    :actions="actions"
    @click-action="handleButtonClick"
    @blur="$emit('blur')"
    @hide="$emit('hide')"
  />

  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    orientation="autoVertical"
    placement="arrowStart"
    no-auto-focus
  >
    <template v-if="Array.isArray(subMenuPopoverContent)">
      <ActionBar
        data-test-id="sub-menu-action-bar"
        :actions="subMenuPopoverContent"
        :editor="editor"
        :is-active="isActive"
        no-gradient
        @click-action="handleButtonClick"
      />
    </template>
    <component
      :is="subMenuPopoverContent"
      v-else
      :editor="editor"
      :content-type="contentType"
      @action="handleSubMenuClick"
    />
  </CommonPopover>
</template>
