<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  disabled?: boolean
}

defineProps<Props>()
</script>

<template>
  <div class="flex items-center gap-3 px-5 text-center">
    <div class="line-more grow"></div>
    <CommonButton class="shrink-0" :disabled="disabled">
      {{ $t('See more') }}
    </CommonButton>
    <div class="line-more grow"></div>
  </div>
</template>

<style scoped>
.line-more {
  height: 6px;
  background-origin: content-box;
  background-image: url('data:image/svg+xml;utf8,<svg width="20" height="6" viewBox="0 0 20 6" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M0 4.99995C6 4.99995 4 1 10 1C16 1 14 4.99927 20 4.99927" stroke="rgb(160, 163, 166)"/></svg>');
  background-repeat: repeat-x;
  background-position-x: right;
  width: 20px;
}

[data-theme='dark'] .line-more {
  background-image: url('data:image/svg+xml;utf8,<svg width="20" height="6" viewBox="0 0 20 6" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M0 4.99995C6 4.99995 4 1 10 1C16 1 14 4.99927 20 4.99927" stroke="rgb(153, 153, 153)"/></svg>');
}

.line-more:first-child {
  background-position-x: left;
}

.line-more:last-child {
  background-position-x: right;
}
</style>
