<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

export interface Props {
  nextFetchCount: number
  disabled?: boolean
}

defineProps<Props>()

defineEmits<{
  'load-more': []
}>()
</script>

<template>
  <div class="flex justify-center">
    <div class="line-more-wrapper flex w-full max-w-md flex-col gap-3 px-5 text-center">
      <CommonButton
        variant="tertiary"
        class="self-center print:hidden"
        :disabled="disabled"
        @click="$emit('load-more')"
      >
        {{ $t('Load %s more', nextFetchCount) }}
      </CommonButton>

      <CommonLabel tag="p" class="hidden! print:block!">
        {{ $t('Hidden articles: %s', nextFetchCount) }}
      </CommonLabel>
    </div>
  </div>
</template>

<style scoped>
.line-more-wrapper::before,
.line-more-wrapper::after {
  content: '';
  display: block;
  height: 0.375rem;
  background-origin: content-box;
  background-image: url('data:image/svg+xml;utf8,<svg width="20" height="6" viewBox="0 0 20 6" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M0 4.99995C6 4.99995 4 1 10 1C16 1 14 4.99927 20 4.99927" stroke="rgb(160, 163, 166)"/></svg>');
  background-repeat: repeat-x;
}

[data-theme='dark'] .line-more-wrapper::before,
[data-theme='dark'] .line-more-wrapper::after {
  background-image: url('data:image/svg+xml;utf8,<svg width="20" height="6" viewBox="0 0 20 6" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M0 4.99995C6 4.99995 4 1 10 1C16 1 14 4.99927 20 4.99927" stroke="rgb(153, 153, 153)"/></svg>');
}

.line-more-wrapper::before {
  background-position-x: left;
}

.line-more-wrapper::after {
  background-position-x: right;
}
</style>
