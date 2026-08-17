<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  count: number
}

const props = defineProps<Props>()
</script>

<template>
  <section class="w-full max-w-7xl shrink-0 px-5.5 py-3 pb-6">
    <ol class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4">
      <li
        v-for="i in props.count"
        :key="i"
        class="flex min-h-42 flex-col items-center justify-center rounded-xl bg-blue-200 px-3 pt-6 dark:bg-gray-500"
        :class="{
          'hidden sm:flex': i === 2,
          'hidden lg:flex': i === 3,
          'hidden 2xl:flex': i === 4,
        }"
      >
        <div class="flex w-full flex-col items-center gap-3">
          <CommonSkeleton class="size-8" rounded alternative-background />
          <div class="mb-3 flex min-h-11 w-full items-center justify-center">
            <CommonSkeleton
              :style="{ 'animation-delay': '0.1s' }"
              class="h-3.5 w-2/3"
              alternative-background
            />
          </div>
        </div>

        <CommonDivider />

        <div class="flex w-full items-center justify-between py-2">
          <div class="flex items-center gap-3">
            <div class="flex gap-1">
              <CommonSkeleton
                :style="{ 'animation-delay': '0.3s' }"
                class="size-5"
                rounded
                alternative-background
              />
              <CommonSkeleton
                :style="{ 'animation-delay': '0.3s' }"
                class="size-5"
                rounded
                alternative-background
              />
            </div>
          </div>
        </div>
      </li>
    </ol>
  </section>
</template>
