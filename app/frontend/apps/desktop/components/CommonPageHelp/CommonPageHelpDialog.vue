<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Slot } from 'vue'
import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'

interface Props {
  content: Slot
}

defineProps<Props>()
</script>

<template>
  <CommonDialog
    name="page-help"
    :header-title="__('Help')"
    header-icon="question-circle"
    :footer-action-options="{
      hideCancelButton: true,
    }"
  >
    <component :is="content"></component>
  </CommonDialog>
</template>
