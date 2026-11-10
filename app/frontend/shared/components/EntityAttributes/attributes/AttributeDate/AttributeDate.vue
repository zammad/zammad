<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'

import type { EntityAttributeProps } from '../../types.ts'
import type { EntityAttributeDate } from './attributeDateTypes.ts'

defineProps<EntityAttributeProps<EntityAttributeDate, string>>()
</script>

<template>
  <CommonDateTime
    :date-time="value"
    :type="attribute.dataType === 'date' ? 'absolute' : 'configured'"
    :absolute-format="attribute.dataType"
  />
</template>
