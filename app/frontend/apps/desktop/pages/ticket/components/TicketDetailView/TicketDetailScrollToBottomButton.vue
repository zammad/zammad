<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  count: number
}

defineProps<Props>()

defineEmits<{
  click: []
}>()
</script>

<template>
  <div class="sticky bottom-4 z-20 flex w-full ltr:justify-start rtl:justify-end">
    <div class="relative w-fit">
      <CommonButton
        v-tooltip="$t('Scroll to bottom')"
        class="mx-2.5"
        size="large"
        variant="subtle"
        icon="arrow-sm"
        @click="$emit('click')"
      />

      <CommonBadge
        size="xs"
        class="pointer-events-none absolute -top-1.5 block! max-w-10 min-w-4 truncate rounded-full! px-1! py-0! font-bold ltr:right-0.5 rtl:left-0.5"
        variant="highlight"
        :aria-label="$t('Unread messages count')"
        role="status"
      >
        {{ count }}
      </CommonBadge>
    </div>
  </div>
</template>
