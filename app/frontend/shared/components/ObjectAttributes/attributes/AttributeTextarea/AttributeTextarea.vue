<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { textToHtml } from '#shared/utils/helpers.ts'

import type { ObjectAttributeTextarea } from './attributeTextareaTypes.ts'
import type { ObjectAttributeProps } from '../../types.ts'

defineProps<ObjectAttributeProps<ObjectAttributeTextarea, string>>()
</script>

<template>
  <div v-html="textToHtml(value)" />
</template>
