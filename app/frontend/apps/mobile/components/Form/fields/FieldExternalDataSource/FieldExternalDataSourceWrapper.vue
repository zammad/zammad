<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { defineAsyncComponent, toRef } from 'vue'

import type { ExternalDataSourceProps as Props } from '#shared/components/Form/fields/FieldExternalDataSource/types.ts'
import { useFieldExternalDataSourceWrapper } from '#shared/components/Form/fields/FieldExternalDataSource/useFieldExternalDataSourceWrapper.ts'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

const props = defineProps<Props>()

Object.assign(
  props.context,
  useFieldExternalDataSourceWrapper(toRef(props, 'context')),
)
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
