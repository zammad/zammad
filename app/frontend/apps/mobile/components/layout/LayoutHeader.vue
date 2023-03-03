<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import CommonButton from '../CommonButton/CommonButton.vue'
import CommonBackButton from '../CommonBackButton/CommonBackButton.vue'

export interface Props {
  title?: string
  titleClass?: string
  backTitle?: string
  backUrl?: RouteLocationRaw
  backAvoidHomeButton?: boolean
  actionTitle?: string
  actionHidden?: boolean
  onAction?(): void
}

const headerElement = ref()

defineExpose({
  headerElement,
})

defineProps<Props>()
</script>

<template>
  <header
    v-if="title || backUrl || (onAction && actionTitle)"
    ref="headerElement"
    class="grid h-[64px] shrink-0 grid-cols-[75px_auto_75px] border-b-[0.5px] border-white/10 bg-black px-4"
    data-test-id="appHeader"
  >
    <div class="flex items-center justify-self-start text-base">
      <CommonBackButton
        v-if="backUrl"
        :fallback="backUrl"
        :label="backTitle"
        :avoid-home-button="backAvoidHomeButton"
      />
    </div>
    <h1
      :class="[
        'flex items-center justify-center text-center text-lg font-bold',
        titleClass,
      ]"
    >
      {{ $t(title) }}
    </h1>
    <div class="flex cursor-pointer items-center justify-self-end text-base">
      <CommonButton
        v-if="onAction && actionTitle && !actionHidden"
        variant="primary"
        transparent-background
        @click="onAction?.()"
      >
        {{ $t(actionTitle) }}
      </CommonButton>
    </div>
  </header>
</template>
