<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, useTemplateRef } from 'vue'

import useEditorActionHelper from '#shared/components/Form/fields/FieldEditor/composables/useEditorActionHelper.ts'
import FieldEditorActionMenu from '#shared/components/Form/fields/FieldEditor/FieldEditorActionMenu/FieldEditorActionMenu.vue'
import { i18n } from '#shared/i18n.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { useTableMenu } from './useTableMenu.ts'

import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
  targetId?: string
}>()

const editor = toRef(props, 'editor')

const { focused, canExecute } = useEditorActionHelper(editor)

const {
  selectedRows,
  selectedCols,
  canSplitCell,
  canMergeCells,
  cellsCountToMerge,
  canDeleteRow,
  canDeleteColumn,
} = useTableMenu(editor)

const actionMenuInstance = useTemplateRef('action-menu')

const actions = computed(() => [
  {
    id: getUuid(),
    name: 'insertRowAbove',
    contentType: ['text/html'],
    label: __('Insert row above'),
    icon: 'insert-row-before',
    command: focused((c) => c.addRowBefore()),
    show: () => canExecute('addRowBefore'),
  },
  {
    id: getUuid(),
    name: 'insertRowBelow',
    contentType: ['text/html'],
    label: __('Insert row below'),
    icon: 'insert-row-after',
    command: focused((c) => c.addRowAfter()),
    show: () => canExecute('addRowAfter'),
  },
  {
    id: getUuid(),
    name: 'deleteRow',
    contentType: ['text/html'],
    label: selectedRows.value > 1 ? i18n.t('Delete %s rows', selectedRows.value) : __('Delete row'),
    icon: 'delete-row',
    command: focused((c) => c.deleteRow()),
    show: () => canExecute('deleteRow') && canDeleteRow.value,
    showDivider: true,
  },
  {
    id: getUuid(),
    name: 'insertColumnBefore',
    contentType: ['text/html'],
    label: __('Insert column before'),
    icon: 'insert-column-before',
    command: focused((c) => c.addColumnBefore()),
    show: () => canExecute('addColumnBefore'),
  },
  {
    id: getUuid(),
    name: 'insertColumnAfter',
    contentType: ['text/html'],
    label: __('Insert column after'),
    icon: 'insert-column-after',
    command: focused((c) => c.addColumnAfter()),
    show: () => canExecute('addColumnAfter'),
  },
  {
    id: getUuid(),
    name: 'deleteColumn',
    contentType: ['text/html'],
    label:
      selectedCols.value > 1
        ? i18n.t('Delete %s columns', selectedCols.value)
        : __('Delete column'),
    icon: 'delete-column',
    command: focused((c) => c.deleteColumn()),
    show: () => canExecute('deleteColumn') && canDeleteColumn.value,
    showDivider: true,
  },
  {
    id: getUuid(),
    name: 'splitCells',
    contentType: ['text/html'],
    label: __('Split cells'),
    icon: 'split-cells',
    command: focused((c) => c.splitCell()),
    show: () => canExecute('splitCell') && canSplitCell.value,
  },
  {
    id: getUuid(),
    name: 'mergeCells',
    contentType: ['text/html'],
    label:
      cellsCountToMerge.value > 1
        ? i18n.t('Merge %s cells', cellsCountToMerge.value)
        : __('Merge cells'),
    icon: 'merge-cells',
    command: focused((c) => c.mergeCells()),
    show: () => canExecute('mergeCells') && canMergeCells.value,
    showDivider: true,
  },
  {
    id: getUuid(),
    name: 'toggleHeaderRow',
    contentType: ['text/html'],
    label: __('Toggle header row'),
    icon: 'toggle-header-row',
    command: focused((c) => c.toggleHeaderRow()),
    show: () => canExecute('toggleHeaderRow'),
  },
  {
    id: getUuid(),
    name: 'toggleHeaderColumn',
    contentType: ['text/html'],
    label: __('Toggle header column'),
    icon: 'toggle-header-column',
    command: focused((c) => c.toggleHeaderColumn()),
    show: () => canExecute('toggleHeaderColumn'),
  },
  {
    id: getUuid(),
    name: 'toggleHeaderCell',
    contentType: ['text/html'],
    label: __('Toggle header cell'),
    icon: 'toggle-header-cell',
    command: focused((c) => c.toggleHeaderCell()),
    show: () => canExecute('toggleHeaderCell'),
    showDivider: true,
  },
  {
    id: getUuid(),
    name: 'deleteTable',
    contentType: ['text/html'],
    label: __('Delete table'),
    icon: 'delete-table',
    command: focused((c) => {
      actionMenuInstance.value?.close()
      return c.deleteTable()
    }),
    show: () => canExecute('deleteTable'),
  },
])
</script>

<template>
  <FieldEditorActionMenu
    ref="action-menu"
    :target-id="targetId"
    type-name="table"
    content-type="text/html"
    :editor="editor"
    :actions="actions"
  />
</template>
