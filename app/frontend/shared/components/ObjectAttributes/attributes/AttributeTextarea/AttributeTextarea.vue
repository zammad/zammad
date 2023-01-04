<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { textToHtml } from '@shared/utils/helpers'
import type { ObjectAttributeTextarea } from './attributeTextareaTypes'

defineProps<{
  attribute: ObjectAttributeTextarea
  value: string
}>()
</script>

<template>
  <div v-html="textToHtml(value)" />
</template>
