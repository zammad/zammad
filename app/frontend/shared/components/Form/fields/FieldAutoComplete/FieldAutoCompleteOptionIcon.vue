<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AutoCompleteOption } from './types'

const props = defineProps<{
  option: AutoCompleteOption
}>()
</script>

<template>
  <CommonIcon
    v-if="props.option.icon"
    :name="props.option.icon"
    :class="{
      'opacity-30': props.option.disabled,
    }"
    class="mr-4"
  />
</template>
