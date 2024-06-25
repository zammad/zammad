<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  entities: unknown[]
  totalCount: number
  disabled?: boolean
}

defineProps<Props>()
</script>

<template>
  <CommonButton
    v-if="entities.length < totalCount"
    type="button"
    :disabled="disabled"
  >
    {{ $t('Show %s more', totalCount - entities.length) }}
  </CommonButton>
</template>
