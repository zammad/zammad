// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  cellNear,
  selectedRect as getSelectedRect,
  selectionCell,
  type Rect,
} from '@tiptap/pm/tables'
import { computed, type MaybeRefOrGetter, toValue } from 'vue'

import type { Editor } from '@tiptap/vue-3'

export const useTableMenu = (editorInstance: MaybeRefOrGetter<Editor | undefined>) => {
  const getTableInfo = () => {
    const editor = toValue(editorInstance)
    if (!editor)
      return {
        selectedRect: null,
        cell: null,
      }

    try {
      const rect = getSelectedRect(editor.state)
      const cell = cellNear(selectionCell(editor.state))?.nodeAfter

      return { selectedRect: rect, cell }
    } catch {
      return { selectedRect: null, cell: null }
    }
  }

  const selectedRect = computed<Rect | null>(() => getTableInfo().selectedRect)

  const cellInfo = computed(() => {
    const { cell } = getTableInfo()

    return {
      cellType: cell?.type.name ?? null,
      rowspan: cell?.attrs.rowspan ?? 1,
      colspan: cell?.attrs.colspan ?? 1,
      align: cell?.attrs.align ?? null,
    }
  })

  const selectedDimensions = computed(() => {
    const rect = selectedRect.value
    if (!rect)
      return {
        selectedRows: 1,
        selectedCols: 1,
        totalRows: 0,
        totalCols: 0,
      }

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-expect-error
    const { map } = rect

    return {
      selectedRows: rect.bottom - rect.top,
      selectedCols: rect.right - rect.left,
      totalRows: map?.height ?? 0,
      totalCols: map?.width ?? 0,
    }
  })

  const isTableBodyCell = computed(() => cellInfo.value.cellType === 'tableCell')
  const isTableHeaderCell = computed(() => cellInfo.value.cellType === 'tableHeader')
  const isInTable = computed(() => cellInfo.value.cellType !== null)

  const canSplitCell = computed(() => {
    const { rowspan, colspan } = cellInfo.value
    const { selectedRows, selectedCols } = selectedDimensions.value

    return selectedRows === rowspan && selectedCols === colspan && (rowspan > 1 || colspan > 1)
  })

  const canMergeCells = computed(() => {
    const { rowspan, colspan } = cellInfo.value
    const { selectedRows, selectedCols } = selectedDimensions.value

    return selectedRows !== rowspan || selectedCols !== colspan
  })

  const cellsCountToMerge = computed(() => {
    const { rowspan, colspan } = cellInfo.value
    const { selectedRows, selectedCols } = selectedDimensions.value

    return (selectedRows - rowspan + 1) * (selectedCols - colspan + 1)
  })

  const canDeleteRow = computed(() => {
    const { selectedRows, totalRows } = selectedDimensions.value

    return totalRows > selectedRows + 1 && isTableBodyCell.value
  })

  const canDeleteColumn = computed(() => {
    const { selectedCols, totalCols } = selectedDimensions.value

    return totalCols > selectedCols
  })

  return {
    isInTable,
    isTableBodyCell,
    isTableHeaderCell,

    // Cell info
    cellType: computed(() => cellInfo.value.cellType),
    rowspan: computed(() => cellInfo.value.rowspan),
    colspan: computed(() => cellInfo.value.colspan),
    align: computed(() => cellInfo.value.align),

    // Dimensions
    selectedRows: computed(() => selectedDimensions.value.selectedRows),
    selectedCols: computed(() => selectedDimensions.value.selectedCols),
    totalRows: computed(() => selectedDimensions.value.totalRows),
    totalCols: computed(() => selectedDimensions.value.totalCols),

    // Actions availability
    canSplitCell,
    canMergeCells,
    cellsCountToMerge,
    canDeleteRow,
    canDeleteColumn,
  }
}
