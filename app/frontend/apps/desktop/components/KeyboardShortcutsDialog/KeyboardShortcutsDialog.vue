<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { partition } from 'lodash-es'
import { computed } from 'vue'

import {
  isKeyboardShortcutAvailable,
  keyboardShortcutCatalogue,
} from '#shared/composables/useKeyboardShortcut/keyboardShortcutCatalogue.ts'
import { useKeyboardShortcutsEnabled } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcutsEnabled.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'

import KeyboardShortcutsDialogGroup from './KeyboardShortcutsDialogGroup.vue'
import { KEYBOARD_SHORTCUTS_DIALOG_NAME } from './useKeyboardShortcutsDialog.ts'

const { isEnabled } = useKeyboardShortcutsEnabled()

const SECOND_COLUMN_GROUPS = new Set(['tickets', 'text-editing'])

const groups = computed(() =>
  keyboardShortcutCatalogue
    .map(({ key, headline, subGroups }) => ({
      key,
      headline,
      subGroups: subGroups
        .map(({ key: subGroupKey, where, entries }) => ({
          key: subGroupKey,
          where,
          entries: entries.filter(isKeyboardShortcutAvailable),
        }))
        .filter((subGroup) => subGroup.entries.length),
    }))
    .filter((group) => group.subGroups.length),
)

const columns = computed(() =>
  partition(groups.value, (group) => !SECOND_COLUMN_GROUPS.has(group.key)).filter(
    (column) => column.length,
  ),
)
</script>

<template>
  <CommonDialog
    :name="KEYBOARD_SHORTCUTS_DIALOG_NAME"
    class="@container -mx-1 flex max-h-[calc(100dvh-8rem)] w-2xl max-w-[calc(100%+(--spacing(2)))] flex-col gap-3 overflow-y-auto px-1 pt-0! pb-1! text-start!"
    :header-title="__('Keyboard shortcuts')"
    header-icon="keyboard"
    wrapper-tag="article"
    hide-footer
    global
    fullscreen
  >
    <FormKit
      v-model="isEnabled"
      type="toggle"
      :label="__('Enable keyboard shortcuts')"
      :variants="{ true: 'True', false: 'False' }"
    />
    <!-- The switch does not reach the keys of the editor and the lists, the design mutes them all the same. -->
    <div
      class="grid grid-cols-1 gap-x-4 gap-y-6"
      :class="{ '@lg:grid-cols-2': columns.length > 1, 'opacity-50': !isEnabled }"
      data-test-id="keyboard-shortcuts-list"
    >
      <div v-for="(column, columnIndex) in columns" :key="columnIndex" class="flex flex-col gap-6">
        <KeyboardShortcutsDialogGroup v-for="group in column" :key="group.key" :group="group" />
      </div>
    </div>
  </CommonDialog>
</template>
