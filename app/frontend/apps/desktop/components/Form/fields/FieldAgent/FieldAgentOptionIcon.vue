<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AutoCompleteAgentOption } from '#shared/components/Form/fields/FieldAgent/types'

defineProps<{
  option: AutoCompleteAgentOption
}>()
</script>

<template>
  <CommonUserAvatar
    v-if="option.user"
    :entity="option.user"
    :class="{
      'opacity-30': option.disabled,
    }"
    size="xs"
  />
</template>
