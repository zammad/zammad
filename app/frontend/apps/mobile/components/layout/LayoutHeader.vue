<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef, useSlots } from 'vue'

import CommonBackButton from '#mobile/components/CommonBackButton/CommonBackButton.vue'
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import type { CommonButtonProps } from '#mobile/components/CommonButton/types.ts'
import CommonRefetch from '#mobile/components/CommonRefetch/CommonRefetch.vue'

import type { RouteLocationRaw } from 'vue-router'

export interface Props {
  containerTag?: 'header' | 'div'
  title?: string
  titleClass?: string
  backTitle?: string
  backIgnore?: string[]
  backUrl?: RouteLocationRaw
  backAvoidHomeButton?: boolean
  defaultAttrs?: Record<string, unknown>
  refetch?: boolean
  actionTitle?: string
  actionHidden?: boolean
  actionButtonProps?: CommonButtonProps

  onAction?(): void
}

const headerElement = useTemplateRef<HTMLElement>('header')

defineExpose({
  headerElement,
})

const props = withDefaults(defineProps<Props>(), {
  refetch: false,
  containerTag: 'header',
})
const slots = useSlots()

const hasSlots = computed(() => Object.keys(slots).length > 0)

const headerClass = computed(() => {
  return [
    'flex items-center justify-center text-center text-lg font-bold',
    props.titleClass,
  ]
})
</script>

<template>
  <component
    :is="containerTag"
    v-if="title || backUrl || (onAction && actionTitle) || hasSlots"
    ref="header"
    class="grid h-[64px] shrink-0 grid-cols-[75px_auto_75px] border-b-[0.5px] border-white/10 bg-black px-4"
    data-test-id="appHeader"
  >
    <div class="flex items-center justify-self-start text-base">
      <slot
        name="before"
        :data="{ backUrl, backTitle, backIgnore, backAvoidHomeButton }"
      >
        <CommonBackButton
          v-if="backUrl"
          :fallback="backUrl"
          :label="backTitle"
          :ignore="backIgnore"
          :avoid-home-button="backAvoidHomeButton"
        />
      </slot>
    </div>
    <div class="flex flex-1 items-center justify-center">
      <CommonRefetch v-bind="defaultAttrs" :refetch="refetch">
        <slot :data="{ defaultAttrs, refetch }">
          <h1 :class="headerClass">
            {{ $t(title) }}
          </h1>
        </slot>
      </CommonRefetch>
    </div>
    <div
      v-if="((onAction || actionTitle) && !actionHidden) || slots.after"
      class="flex items-center justify-self-end text-base"
    >
      <slot name="after" :data="{ actionButtonProps }">
        <CommonButton
          v-bind="{
            variant: 'primary',
            transparentBackground: true,
            ...actionButtonProps,
          }"
          @click="onAction?.()"
        >
          {{ $t(actionTitle) }}
        </CommonButton>
      </slot>
    </div>
  </component>
</template>
