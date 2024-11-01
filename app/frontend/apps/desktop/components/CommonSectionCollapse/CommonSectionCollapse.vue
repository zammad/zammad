<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import { useCollapseHandler } from '#desktop/components/CollapseButton/composables/useCollapseHandler.ts'
import { useTransitionCollapse } from '#desktop/composables/useTransitionCollapse.ts'

export interface Props {
  id: string
  title?: string
  size?: 'small' | 'large'
  noCollapse?: boolean
  noNegativeMargin?: boolean
  noHeader?: boolean
  scrollable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'small',
})

const emit = defineEmits<{
  collapse: [boolean]
  expand: [boolean]
}>()

const headerId = computed(() => `${props.id}-header`)

const { userId } = useSessionStore()

const { toggleCollapse, isCollapsed } = useCollapseHandler(emit, {
  storageKey: `${userId}-${props.id}-section-collapsed`,
})

const { collapseDuration, collapseEnter, collapseAfterEnter, collapseLeave } =
  useTransitionCollapse()
</script>

<template>
  <!--  eslint-disable vuejs-accessibility/no-static-element-interactions-->
  <div class="flex flex-col gap-1" :class="{ 'overflow-y-auto': scrollable }">
    <header
      v-if="!noHeader"
      :id="headerId"
      class="group flex cursor-default items-center justify-between text-stone-200 dark:text-neutral-500"
      :class="{
        'cursor-pointer rounded-md focus-within:outline focus-within:outline-1 focus-within:outline-offset-1 focus-within:outline-blue-800 hover:bg-blue-600 hover:text-black dark:hover:bg-blue-900 hover:dark:text-white':
          !noCollapse,
        'px-1 py-0.5': size === 'small',
        '-mx-1': size === 'small' && !noNegativeMargin,
        'px-2 py-2.5': size === 'large',
        '-mx-2': size === 'large' && !noNegativeMargin,
      }"
      @click="!noCollapse && toggleCollapse()"
      @keydown.enter="!noCollapse && toggleCollapse()"
    >
      <slot name="title">
        <CommonLabel
          class="grow select-none text-current"
          :size="size"
          tag="h3"
        >
          {{ $t(title) }}
        </CommonLabel>
      </slot>

      <CollapseButton
        v-if="!noCollapse"
        :collapsed="isCollapsed"
        :owner-id="id"
        no-padded
        class="focus-visible:bg-transparent focus-visible:text-black group-hover:text-black group-hover:opacity-100 dark:focus-visible:text-white dark:group-hover:text-white"
        :class="{ 'opacity-100': isCollapsed }"
        orientation="vertical"
        @keydown.enter="toggleCollapse()"
      />
    </header>
    <Transition
      name="collapse"
      :duration="collapseDuration"
      @enter="collapseEnter"
      @after-enter="collapseAfterEnter"
      @leave="collapseLeave"
    >
      <div
        v-show="!isCollapsed || noHeader"
        :id="id"
        :class="{ 'overflow-y-auto': scrollable }"
      >
        <slot :header-id="headerId" />
      </div>
    </Transition>
  </div>
</template>
