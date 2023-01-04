<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

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
    :disabled="props.context.disabled"
    :placeholder="props.context.placeholder || props.context.attrs.placeholder"
    :wrapper-class="props.context.wrapperClass"
    no-border
    @blur="context.handlers.blur"
  />
</template>
