<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div
    class="indicator absolute -top-[3px] h-1.5 w-1.5 animate-pulse rounded-full bg-pink-500 ltr:-right-[3px] rtl:-left-[3px]"
    role="status"
    aria-live="polite"
    :aria-label="$t('Has update')"
  ></div>
</template>

<style scoped>
.router-link-active > * > .indicator {
  @apply bg-white;
}
</style>
