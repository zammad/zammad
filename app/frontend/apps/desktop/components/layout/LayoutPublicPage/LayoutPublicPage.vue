<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, computed } from 'vue'

import CommonLogo from '#shared/components/CommonLogo/CommonLogo.vue'

import LayoutPublicPageBoxActions from './LayoutPublicPageBoxActions.vue'

import type { BoxSizes } from '../types'

export interface Props {
  title?: string
  showLogo?: boolean
  boxSize?: BoxSizes
  hideFooter?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  boxSize: 'medium',
})

const boxSizeMap: Record<BoxSizes, string> = {
  small: 'max-w-md',
  medium: 'max-w-lg',
  large: 'max-w-2xl',
}

const boxSizeClass = computed(() => {
  return boxSizeMap[props.boxSize]
})

const hoverPoweredByLogo = ref(false)
</script>

<template>
  <div
    class="flex min-h-screen flex-col items-center bg-neutral-950 text-stone-200 dark:text-neutral-500"
  >
    <div :class="boxSizeClass" class="m-auto w-full">
      <main
        class="flex flex-col gap-2.5 rounded-3xl bg-white p-5 text-black dark:bg-gray-500 dark:text-white"
      >
        <div v-if="showLogo" class="flex justify-center">
          <CommonLogo />
        </div>
        <h1 v-if="title" class="mb-5 text-center text-xl">
          {{ $t(title) }}
        </h1>
        <slot />

        <LayoutPublicPageBoxActions v-if="$slots.boxActions">
          <slot name="boxActions" />
        </LayoutPublicPageBoxActions>
      </main>

      <section
        v-if="$slots.bottomContent"
        :aria-label="$t('Additional information and links')"
        class="flex w-full flex-col items-center justify-center space-y-3 py-3 align-middle text-xs"
      >
        <slot name="bottomContent" />
      </section>
      <footer
        v-if="!hideFooter"
        class="flex w-full items-center justify-center py-3 align-middle text-xs"
      >
        <span class="ltr:mr-1 rtl:ml-1">{{ $t('Powered by') }}</span>
        <CommonLink
          link="https://zammad.org"
          open-in-new-tab
          external
          class="flex items-center gap-1 text-neutral-500"
          @focus="hoverPoweredByLogo = true"
          @blur="hoverPoweredByLogo = false"
          @mouseover="hoverPoweredByLogo = true"
          @mouseleave="hoverPoweredByLogo = false"
        >
          <div class="relative">
            <CommonIcon name="logo-flat" size="base" />
            <Transition name="fade">
              <CommonIcon
                v-if="hoverPoweredByLogo"
                class="absolute top-0"
                name="logo"
                size="base"
              />
            </Transition>
          </div>
          {{ $t('Zammad') }}
        </CommonLink>
      </footer>
    </div>
  </div>
</template>
