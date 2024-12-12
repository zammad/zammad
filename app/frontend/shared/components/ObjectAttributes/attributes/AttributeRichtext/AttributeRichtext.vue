<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */
import type { ObjectAttributeRichtext } from './attributeRichtextTypes.ts'
import type { ObjectAttributeProps } from '../../types.ts'

defineProps<ObjectAttributeProps<ObjectAttributeRichtext, string>>()
</script>

<template>
  <div v-html="value" />
</template>
