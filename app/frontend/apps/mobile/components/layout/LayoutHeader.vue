<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import CommonButton from '../CommonButton/CommonButton.vue'
import CommonBackButton from '../CommonBackButton/CommonBackButton.vue'
import CommonRefetch from '../CommonRefetch/CommonRefetch.vue'

export interface Props {
  title?: string
  titleClass?: string
  backTitle?: string
  backIgnore?: string[]
  backUrl?: RouteLocationRaw
  backAvoidHomeButton?: boolean
  refetch?: boolean
  actionTitle?: string
  actionHidden?: boolean
  onAction?(): void
}

const headerElement = ref()

defineExpose({
  headerElement,
})

const props = withDefaults(defineProps<Props>(), {
  refetch: false,
})

const headerClass = computed(() => {
  return [
    'flex items-center justify-center text-center text-lg font-bold',
    props.titleClass,
  ]
})
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
        :ignore="backIgnore"
        :avoid-home-button="backAvoidHomeButton"
      />
    </div>
    <div class="flex flex-1 items-center justify-center">
      <CommonRefetch :refetch="refetch">
        <h1 :class="headerClass">
          {{ $t(title) }}
        </h1>
      </CommonRefetch>
    </div>
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
