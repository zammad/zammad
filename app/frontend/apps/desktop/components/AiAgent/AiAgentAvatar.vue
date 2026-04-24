<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div
    class="before:motion-reduce:animation-none relative size-8 rounded-full before:absolute before:inset-0 before:-z-1 before:size-full before:w-full before:animate-spin before:rounded-full before:bg-linear-to-r before:from-blue-800 before:to-pink-200 before:[animation-duration:2s]"
  >
    <div
      class="flex h-full rounded-[inherit] border border-transparent bg-neutral-50 bg-clip-padding p-1 dark:bg-gray-500"
    >
      <CommonIcon class="text-blue-800" size="base" name="ai-agent" :label="__('AI agent')" />
    </div>

    <slot />
  </div>
</template>
