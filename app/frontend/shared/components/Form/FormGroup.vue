<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<!-- TODO: needed because of vue-tsc issue: https://github.com/johnsoncodehk/volar/issues/1452 -->
<script setup lang="ts"></script>

<template>
  <div class="form-group mb-4 rounded-xl bg-gray-500">
    <slot />
  </div>
</template>

<style lang="scss">
.form-group {
  .formkit-outer:not(:last-child) {
    .formkit-inner {
      @apply border-b border-white/10;
    }
  }
}
</style>
