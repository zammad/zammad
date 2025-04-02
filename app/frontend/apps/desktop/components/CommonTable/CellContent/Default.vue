<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { CellContentProps } from '../types.ts'

const props = defineProps<CellContentProps>()
</script>

<template>
  {{ props.value }}
</template>
