<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AutoCompleteCustomerOption } from './types'

const props = defineProps<{
  option: AutoCompleteCustomerOption
}>()
</script>

<template>
  <CommonUserAvatar
    v-if="props.option.user"
    :entity="props.option.user"
    :class="{
      'opacity-30': props.option.disabled,
    }"
    size="small"
    class="mr-4"
  />
</template>
