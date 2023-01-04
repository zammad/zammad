<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { RouteLocationRaw } from 'vue-router'
import CommonBackButton from '../CommonBackButton/CommonBackButton.vue'

export interface Props {
  title?: string
  titleClass?: string
  backTitle?: string
  backUrl?: RouteLocationRaw
  actionTitle?: string
  actionDisabled?: boolean
  onAction?(): void
}

defineProps<Props>()
</script>

<template>
  <header
    v-if="title || backUrl || (onAction && actionTitle)"
    class="grid h-[64px] grid-cols-3 border-b-[0.5px] border-white/10 px-4"
    data-test-id="appHeader"
  >
    <div class="flex items-center justify-self-start text-base">
      <CommonBackButton v-if="backUrl" :fallback="backUrl" :label="backTitle" />
    </div>
    <h1
      :class="[
        'flex flex-1 items-center justify-center text-center text-lg font-bold',
        titleClass,
      ]"
    >
      {{ $t(title) }}
    </h1>
    <div class="flex cursor-pointer items-center justify-self-end text-base">
      <button
        v-if="onAction && actionTitle"
        :class="actionDisabled ? 'text-blue/50' : 'text-blue'"
        :disabled="actionDisabled"
        @click="onAction?.()"
      >
        {{ $t(actionTitle) }}
      </button>
    </div>
  </header>
</template>
