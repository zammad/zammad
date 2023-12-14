<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, computed } from 'vue'
import CommonLogo from '#shared/components/CommonLogo/CommonLogo.vue'
import type { BoxSizes } from './types'

export interface Props {
  title: string
  showLogo: boolean
  boxSize?: BoxSizes
}

const props = withDefaults(defineProps<Props>(), {
  boxSize: 'medium',
})

const boxSizeMap: Record<BoxSizes, string> = {
  small: 'max-w-md',
  medium: 'max-w-lg',
}

const boxSizeClass = computed(() => {
  return boxSizeMap[props.boxSize]
})

const hoverPoweredByLogo = ref(false)
</script>

<template>
  <div
    class="min-h-screen flex flex-col items-center bg-neutral-950 text-stone-200 dark:text-neutral-500"
  >
    <div :class="boxSizeClass" class="w-full m-auto">
      <main
        class="flex flex-col gap-2.5 p-5 bg-white dark:bg-gray-500 text-black dark:text-white rounded-3xl"
      >
        <div v-if="showLogo" class="flex justify-center">
          <CommonLogo />
        </div>
        <h1 class="mb-5 flex justify-center text-xl">
          {{ $t(title) }}
        </h1>
        <slot />
      </main>

      <div
        v-if="$slots.bottomContent"
        class="flex flex-col space-y-3 w-full items-center justify-center py-3 align-middle text-xs"
      >
        <slot name="bottomContent" />
      </div>
      <footer
        class="flex w-full items-center justify-center py-3 align-middle text-xs"
      >
        <span class="ltr:mr-1 rtl:ml-1">{{ $t('Powered by') }}</span>
        <CommonLink
          link="https://zammad.org"
          open-in-new-tab
          external
          class="text-neutral-500 flex items-center gap-1"
          @mouseover="hoverPoweredByLogo = true"
          @mouseleave="hoverPoweredByLogo = false"
        >
          <CommonIcon
            :name="hoverPoweredByLogo ? 'logo' : 'logo-flat'"
            size="base"
          />
          {{ $t('Zammad') }}
        </CommonLink>
      </footer>
    </div>
  </div>
</template>
