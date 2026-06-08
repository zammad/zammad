<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts">
export const triggerId = 'table-menu-trigger'
</script>

<script setup lang="ts">
import { getFieldEditorClasses } from '#shared/components/Form/initializeFieldEditor.ts'
import stopEvent from '#shared/utils/events.ts'

import TableMenuPopover from './TableMenuPopover.vue'

import type { Editor } from '@tiptap/vue-3'

interface Props {
  editor: Editor
}

defineProps<Props>()

const classes = getFieldEditorClasses()

// Showing the Popover is handled through the the FieldEditorActionMenu global click handler through the targe ID
// Both desktop and mobile rely on this mechanism

// :TODO Trigger button is not accessible via keyboard right now
</script>

<template>
  <button
    v-bind="$attrs"
    :id="triggerId"
    :aria-label="$t('Table options')"
    class="absolute z-10"
    :class="classes.tableMenu.triggerButton"
    type="button"
    @mousedown="stopEvent"
  >
    <CommonIcon decorative size="tiny" name="three-dots-vertical" />
  </button>

  <TableMenuPopover :target-id="triggerId" :editor="editor" />
</template>
