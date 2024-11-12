// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ModelRef, type Ref } from 'vue'

import type { TableItem } from '#desktop/components/CommonSimpleTable/types.ts'

export const useTableCheckboxes = (
  checkedRowItems: ModelRef<TableItem[]>,
  items: Ref<TableItem[]>,
) => {
  const allCheckboxRowsSelected = computed(
    () => checkedRowItems.value.length >= items.value.length,
  )

  const selectAllRowCheckboxes = (value?: boolean) => {
    if (allCheckboxRowsSelected.value === value) return

    if (value) {
      checkedRowItems.value = items.value
    } else {
      checkedRowItems.value = items.value.filter(
        (item) => item.disabled && item.checked,
      )
    }
  }

  const handleCheckboxUpdate = (item: TableItem) => {
    const isChecked = checkedRowItems.value.some(
      (selectedItem) => selectedItem.id === item.id,
    )

    if (!isChecked) {
      // Overwrite entire array to trigger reactivity since defineModel default value is not reactive.
      checkedRowItems.value = [...checkedRowItems.value, item]
    } else {
      checkedRowItems.value = checkedRowItems.value.filter(
        (selectedItem) => item.id.toString() !== selectedItem.id.toString(),
      )
    }
  }

  const hasCheckboxId = (itemId: string | number) =>
    checkedRowItems.value.some(
      (selectedItem) => selectedItem.id.toString() === itemId.toString(),
    )

  return {
    allCheckboxRowsSelected,
    selectAllRowCheckboxes,
    handleCheckboxUpdate,
    hasCheckboxId,
  }
}
