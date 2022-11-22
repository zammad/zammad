<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { defineAsyncComponent } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'

const FieldEditor = defineAsyncComponent(() => import('./FieldEditorInput.vue'))

interface Props {
  context: FormFieldContext
}

defineProps<Props>()
</script>

<template>
  <Suspense>
    <FieldEditor :context="context" v-bind="$attrs" />
    <template #fallback>
      <div class="h-[96px]" />
    </template>
  </Suspense>
</template>
