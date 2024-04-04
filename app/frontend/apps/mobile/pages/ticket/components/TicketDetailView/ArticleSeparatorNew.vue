<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div class="line-new select-none text-center">
    <span class="text-blue bg-black px-2">{{ $t('new') }}</span>
  </div>
</template>

<style scoped>
.line-new {
  background: linear-gradient(
    180deg,
    rgba(0, 0, 0, 0) calc(50% - 1px),
    #23a2cd calc(50%),
    rgba(0, 0, 0, 0) calc(50% + 1px)
  );
}
</style>
