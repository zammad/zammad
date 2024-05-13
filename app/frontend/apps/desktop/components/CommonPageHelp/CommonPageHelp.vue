<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'

const pageHelpDialog = useDialog({
  name: 'page-help',
  component: () => import('./CommonPageHelpDialog.vue'),
})
</script>

<template>
  <CommonButton
    prefix-icon="question-circle"
    size="medium"
    @click="pageHelpDialog.open({ content: $slots.default })"
    >{{ $t('Help') }}</CommonButton
  >
</template>
