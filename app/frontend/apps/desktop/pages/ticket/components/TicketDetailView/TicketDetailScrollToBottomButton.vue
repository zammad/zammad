<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  count: number
}

const props = defineProps<Props>()

defineEmits<{
  click: []
}>()

const countDisplay = computed(() => (props.count > 9 ? '9+' : props.count))
</script>

<template>
  <div class="z-20 flex w-full ltr:justify-start rtl:justify-end">
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
        class="pointer-events-none absolute -top-1.5 flex aspect-square size-5 max-w-10 items-center justify-center rounded-full! p-0! font-bold ltr:right-0.5 rtl:left-0.5"
        variant="highlight"
        :aria-label="$t('Unread messages count')"
        role="status"
      >
        {{ countDisplay }}
      </CommonBadge>
    </div>
  </div>
</template>
