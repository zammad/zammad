<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'

interface Props {
  invisibleActions: EditorButton[]
  actions: EditorButton[]
  index: number
}

const props = defineProps<Props>()

const hideDivider = computed(() =>
  props.invisibleActions.some(
    (action) => action.name === props.actions[props.index + 1]?.name, // keep divider in dom to avoid flickering UI at the edge point of overflow
  ),
)
</script>

<template>
  <slot :hide-divider="hideDivider" />
</template>
