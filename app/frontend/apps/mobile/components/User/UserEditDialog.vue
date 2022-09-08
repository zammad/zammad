<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'

interface Props {
  name: string
}

defineProps<Props>()
</script>

<template>
  <CommonDialog name="user-edit">placeholder</CommonDialog>
</template>
