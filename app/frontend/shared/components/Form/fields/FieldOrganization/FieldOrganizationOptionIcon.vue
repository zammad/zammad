<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { AutoCompleteOrganizationOption } from './types'

const props = defineProps<{
  option: AutoCompleteOrganizationOption
}>()
</script>

<template>
  <CommonOrganizationAvatar
    v-if="props.option.organization"
    :entity="props.option.organization"
    :class="{
      'opacity-30': props.option.disabled,
    }"
    size="small"
    class="mr-4"
  />
</template>
