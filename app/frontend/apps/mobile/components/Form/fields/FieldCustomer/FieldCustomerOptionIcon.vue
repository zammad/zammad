<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AutoCompleteCustomerUserOption } from '#shared/components/Form/fields/FieldCustomer/types.ts'

defineProps<{
  option: AutoCompleteCustomerUserOption
}>()
</script>

<template>
  <CommonUserAvatar
    v-if="option.user"
    :entity="option.user"
    :class="{
      'opacity-30': option.disabled,
    }"
    size="small"
    class="ltr:mr-4 rtl:ml-4"
  />
</template>
