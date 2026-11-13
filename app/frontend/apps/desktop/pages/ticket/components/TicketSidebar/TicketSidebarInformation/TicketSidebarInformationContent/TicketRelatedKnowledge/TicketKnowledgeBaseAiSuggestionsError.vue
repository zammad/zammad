<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

defineProps<{
  errorDetail: string | null
}>()

defineEmits<{
  retry: []
}>()
</script>

<template>
  <div class="flex flex-col items-end gap-3">
    <CommonAlert class="self-stretch" variant="danger">
      <div class="flex flex-col gap-1.5">
        <CommonLabel class="text-red-500 dark:text-red-500">
          {{
            $t(
              'The suggestions could not be generated. Please try again later or contact your administrator.',
            )
          }}
        </CommonLabel>
        <CommonLabel v-if="errorDetail" class="wrap-anywhere text-red-500 dark:text-red-500">
          {{ $t('API server error: %s', $t(errorDetail)) }}
        </CommonLabel>
      </div>
    </CommonAlert>
    <CommonButton variant="tertiary" @click="$emit('retry')">{{ $t('Retry') }}</CommonButton>
  </div>
</template>
