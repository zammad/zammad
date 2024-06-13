<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { findParentNodeClosestToPos } from '@tiptap/core'
import { useEventListener, onKeyUp } from '@vueuse/core'
import { computed, nextTick, toRef } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import ActionBar from '#shared/components/Form/fields/FieldEditor/ActionBar.vue'
// import {
//   getFieldEditorClasses,
//   getFieldEditorProps,
// } from '#shared/components/Form/initializeFieldEditor.ts'
import { i18n } from '#shared/i18n.ts'
import getUuid from '#shared/utils/getUuid.ts'

import useEditorActions from './useEditorActions.ts'

import type { EditorContentType } from './types.ts'
import type { EditorButton } from './useEditorActions.ts'
import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
  contentType: EditorContentType
}>()

const editor = toRef(props, 'editor')

const { isActive, focused, canExecute } = useEditorActions(
  editor,
  props.contentType,
  [],
)

const { popover, open, close, popoverTarget, isOpen } = usePopover()

const setPopoverTarget = () => {
  if (!editor.value) return

  const nearestTableParent = findParentNodeClosestToPos(
    editor.value.state.selection.$anchor,
    (node) => node.type.name === 'table',
  )

  if (!nearestTableParent) {
    popoverTarget.value = undefined
    if (isOpen.value) close()
    return
  }

  if (nearestTableParent) {
    const wrapperDomNode = editor.value.view.nodeDOM(nearestTableParent.pos) as
      | HTMLElement
      | null
      | undefined

    const tableDomNode = wrapperDomNode?.querySelector('table')
    if (tableDomNode) {
      popoverTarget.value = tableDomNode
    }
    if (popoverTarget.value && !isOpen.value) {
      nextTick(() => {
        open()
      })
    }
  }
}

const isCurrentFocusedEditorWithTable = (element: HTMLElement | null) => {
  // `ID` gets set on each editor, so we can distinguish between them

  return (
    element?.closest(`#${editor.value?.view.dom.id}`) &&
    editor.value?.isFocused &&
    isActive('table')
  )
}

onKeyUp(['ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight'], (e) => {
  if (isCurrentFocusedEditorWithTable(e.target as HTMLElement)) {
    setPopoverTarget()
  } else if (isOpen.value) {
    close()
  }
})

useEventListener('click', (e) => {
  if (isCurrentFocusedEditorWithTable(e.target as HTMLElement)) {
    setPopoverTarget()
  }
})

const getActionsList = (): EditorButton[] => {
  if (!editor.value) return []

  return [
    {
      id: getUuid(),
      name: 'insertRowAbove',
      contentType: ['text/html'],
      label: i18n.t('Insert row above'),
      icon: 'insert-row-before',
      command: focused((c) => c.addRowBefore()),
      disabled: !canExecute('addRowBefore'),
    },
    {
      id: getUuid(),
      name: 'insertRowBelow',
      contentType: ['text/html'],
      label: i18n.t('Insert row below'),
      icon: 'insert-row-after',
      command: focused((c) => c.addRowAfter()),
      disabled: !canExecute('addRowAfter'),
    },
    {
      id: getUuid(),
      name: 'deleteRow',
      contentType: ['text/html'],
      label: i18n.t('Delete row'),
      icon: 'delete-row',
      command: focused((c) => c.deleteRow()),
      disabled: !canExecute('deleteRow'),
      showDivider: true,
    },
    {
      id: getUuid(),
      name: 'insertColumnBefore',
      contentType: ['text/html'],
      label: i18n.t('Insert column before'),
      icon: 'insert-column-before',
      command: focused((c) => c.addColumnBefore()),
      disabled: !canExecute('addColumnBefore'),
    },
    {
      id: getUuid(),
      name: 'insertColumnAfter',
      contentType: ['text/html'],
      label: i18n.t('Insert column after'),
      icon: 'insert-column-after',
      command: focused((c) => c.addColumnAfter()),
      disabled: !canExecute('addColumnAfter'),
    },
    {
      id: getUuid(),
      name: 'deleteColumn',
      contentType: ['text/html'],
      label: i18n.t('Delete column'),
      icon: 'delete-column',
      command: focused((c) => c.deleteColumn()),
      disabled: !canExecute('deleteColumn'),
      showDivider: true,
    },
    {
      id: getUuid(),
      name: 'splitCells',
      contentType: ['text/html'],
      label: i18n.t('Split cells'),
      icon: 'split-cells',
      command: focused((c) => c.splitCell()),
      disabled: !canExecute('splitCell'),
    },
    {
      id: getUuid(),
      name: 'mergeCells',
      contentType: ['text/html'],
      label: i18n.t('Merge cells'),
      icon: 'merge-cells',
      command: focused((c) => c.mergeCells()),
      disabled: !canExecute('mergeCells'),
      showDivider: true,
    },
    {
      id: getUuid(),
      name: 'toggleHeaderRow',
      contentType: ['text/html'],
      label: i18n.t('Toggle header row'),
      icon: 'toggle-header-row',
      command: focused((c) => c.toggleHeaderRow()),
      disabled: !canExecute('toggleHeaderRow'),
    },
    {
      id: getUuid(),
      name: 'toggleHeaderColumn',
      contentType: ['text/html'],
      label: i18n.t('Toggle header column'),
      icon: 'toggle-header-column',
      command: focused((c) => c.toggleHeaderColumn()),
      disabled: !canExecute('toggleHeaderColumn'),
    },
    {
      id: getUuid(),
      name: 'toggleHeaderCell',
      contentType: ['text/html'],
      label: i18n.t('Toggle header cell'),
      icon: 'toggle-header-cell',
      command: focused((c) => c.toggleHeaderCell()),
      disabled: !canExecute('toggleHeaderCell'),
      showDivider: true,
    },
    {
      id: getUuid(),
      name: 'deleteTable',
      contentType: ['text/html'],
      label: i18n.t('Delete table'),
      icon: 'delete-table',
      command: focused((c) => {
        close()
        return c.deleteTable()
      }),
      disabled: !canExecute('deleteTable'),
    },
  ]
}

const actions = computed(() => {
  return getActionsList().filter((action) => {
    return action.contentType.includes(props.contentType)
  })
})
</script>

<template>
  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    orientation="autoVertical"
    placement="start"
    no-auto-focus
    hide-arrow
  >
    <ActionBar :editor="editor" :actions="actions" no-gradient />
  </CommonPopover>
</template>
