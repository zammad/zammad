<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div class="mobile-group mb-4 rounded-xl bg-gray-500">
    <slot />
  </div>
</template>

<style lang="scss">
.mobile-group {
  .formkit-outer:not(:last-child) {
    .formkit-inner {
      @apply border-b border-white/10;
    }
  }
}
</style>
