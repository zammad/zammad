<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { RouteLocationRaw } from 'vue-router'

export interface Props {
  title?: string
  titleClass?: string
  backTitle?: string
  backUrl?: RouteLocationRaw
  actionTitle?: string
  backButton?: boolean
  onAction?(): void
}

defineProps<Props>()
</script>

<template>
  <header
    v-if="
      title || (backUrl && backTitle) || backButton || (onAction && actionTitle)
    "
    class="grid h-[64px] grid-cols-3 border-b-[0.5px] border-white/10 px-4"
    data-test-id="appHeader"
  >
    <div class="flex items-center justify-self-start text-base">
      <component
        :is="backUrl ? 'CommonLink' : 'div'"
        v-if="(backUrl && backTitle) || backButton"
        :link="backUrl"
        class="flex cursor-pointer gap-2"
        @click="backButton && $router.back()"
      >
        <CommonIcon name="arrow-left" size="small" />
        <span>{{ $t(backTitle) }}</span>
      </component>
    </div>
    <div
      :class="[
        'flex flex-1 items-center justify-center text-center text-lg font-bold',
        titleClass,
      ]"
    >
      {{ $t(title) }}
    </div>
    <div class="flex cursor-pointer items-center justify-self-end text-base">
      <button
        v-if="onAction && actionTitle"
        class="text-blue"
        @click="onAction?.()"
      >
        {{ $t(actionTitle) }}
      </button>
    </div>
  </header>
</template>
