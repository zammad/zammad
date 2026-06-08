<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { textToHtml } from '#shared/utils/helpers.ts'

import type { ObjectAttributeTextarea } from './attributeTextareaTypes.ts'
import type { ObjectAttributeProps } from '../../types.ts'

defineProps<ObjectAttributeProps<ObjectAttributeTextarea, string>>()
</script>

<template>
  <!--      eslint-disable vue/no-v-html -->
  <div v-if="mode === 'view'" v-html="textToHtml(value)" />
  <template v-else>{{ value }}</template>
</template>
