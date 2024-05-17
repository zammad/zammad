<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonInputSearch, {
  type CommonInputSearchProps,
} from '#shared/components/CommonInputSearch/CommonInputSearch.vue'

import useValue from '../../composables/useValue.ts'

import type { FormFieldContext } from '../../types/field.ts'

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
    :class="context.classes.input"
    @blur="context.handlers.blur"
  />
</template>
