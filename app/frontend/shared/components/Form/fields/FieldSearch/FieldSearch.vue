<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonInputSearch, {
  type CommonInputSearchProps,
} from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import { toRef } from 'vue'
import useValue from '../../composables/useValue'
import type { FormFieldContext } from '../../types/field'

export interface FieldSearchProps {
  context: FormFieldContext<CommonInputSearchProps>
}

const props = defineProps<FieldSearchProps>()

const { localValue } = useValue(toRef(props, 'context'))
</script>

<template>
  <CommonInputSearch
    :id="props.context.id"
    v-model="localValue"
    no-border
    :disabled="props.context.disabled"
    @blur="context.handlers.blur"
  />
</template>
