<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ObjectAttributeTimeUnit } from './attributeTimeUnitTypes.ts'
import type { ObjectAttributeProps } from '../../types.ts'

defineProps<ObjectAttributeProps<ObjectAttributeTimeUnit, number>>()
</script>

<template>{{ value?.toFixed(2) }}</template>
