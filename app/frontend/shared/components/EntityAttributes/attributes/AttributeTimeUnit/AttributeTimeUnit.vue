<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EntityAttributeTimeUnit } from './attributeTimeUnitTypes.ts'
import type { EntityAttributeProps } from '../../types.ts'

defineProps<EntityAttributeProps<EntityAttributeTimeUnit, number>>()
</script>

<template>{{ value?.toFixed(2) }}</template>
