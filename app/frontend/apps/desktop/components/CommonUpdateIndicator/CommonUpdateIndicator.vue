<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div
    class="indicator absolute -top-[3px] h-1.5 w-1.5 animate-pulse rounded-full bg-pink-500 ltr:-right-[3px] rtl:-left-[3px]"
    role="status"
    aria-live="polite"
    :aria-label="$t('Has update')"
  />
</template>

<style scoped>
.router-link-active > * > .indicator {
  background-color: var(--color-white);
}
</style>
