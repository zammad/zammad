<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { Comment, computed, useSlots } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

export interface Props {
  label?: string
  orientation?: 'horizontal' | 'vertical'
  size?: 'normal' | 'large'
  isReachingBottom?: boolean
  isReachingTop?: boolean
  hidePrimaryAction?: boolean
  unreadCount?: number
  unreadTooltip?: string
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'vertical',
  unreadCount: 0,
  unreadTooltip: __('Scroll to unread item'),
  label: __('Scroll actions'),
})

const emit = defineEmits<{
  'scroll-to-start': []
  'scroll-to-end': []
  'scroll-to-unread': []
}>()

const slots = useSlots()

const countDisplay = computed(() => (props.unreadCount > 9 ? '9+' : props.unreadCount))

const showUnreadCount = computed(() => props.unreadCount > 0)

// Generic actions replace the scroll controls, they are always visible.
//   Comment-only slot content does not count, some consumers pass placeholder comments.
const hasGenericActions = computed(() =>
  Boolean(slots.default?.().some((vnode) => vnode.type !== Comment)),
)

// A primary action is not a scroll affordance, so it must not disappear with them: it is the
//   only entry point some views offer - the knowledge base reader's edit button is the way into
//   the edit view - and content short enough to need no scrolling is exactly when they vanished.
const hasPrimaryAction = computed(
  () =>
    !props.hidePrimaryAction &&
    Boolean(slots['primary-action']?.().some((vnode) => vnode.type !== Comment)),
)

const showElement = computed(
  () =>
    hasGenericActions.value ||
    hasPrimaryAction.value ||
    !props.isReachingBottom ||
    !props.isReachingTop ||
    showUnreadCount.value,
)

const { transitions } = useTransitionConfig()
</script>

<template>
  <div
    v-if="showElement"
    role="toolbar"
    :aria-orientation="orientation"
    :aria-label="label"
    class="grid w-fit gap-1 rounded-(--toolbar-radius) border border-neutral-100 bg-neutral-75/80 p-(--toolbar-p) backdrop-blur-xs [--toolbar-p:0.25rem] [--toolbar-radius:0.75rem] dark:border-gray-900 dark:bg-gray-500/80"
    :class="{ 'grid-flow-col items-center': orientation === 'horizontal' }"
  >
    <slot />

    <Transition v-if="!hasGenericActions" :name="transitions.collapseHeight">
      <div v-if="hasPrimaryAction" class="flex">
        <slot name="primary-action" />
      </div>
    </Transition>

    <Transition v-if="!hasGenericActions" :name="transitions.collapseHeight">
      <div v-if="!isReachingTop">
        <div class="flex min-h-0">
          <CommonButton
            ref="scroll-up-button"
            v-tooltip="$t('Scroll to start')"
            size="medium"
            variant="tertiary"
            icon="arrow-up-short"
            class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400"
            @click="emit('scroll-to-start')"
          />
        </div>
      </div>
    </Transition>

    <Transition v-if="!hasGenericActions" :name="transitions.collapseHeight">
      <div v-if="!isReachingBottom">
        <div class="relative flex min-h-0">
          <CommonButton
            ref="scroll-down-button"
            v-tooltip="showUnreadCount ? unreadTooltip : $t('Scroll to end')"
            size="medium"
            variant="tertiary"
            icon="arrow-down-short"
            class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400"
            @click="showUnreadCount ? emit('scroll-to-unread') : emit('scroll-to-end')"
          />

          <CommonBadge
            v-if="showUnreadCount"
            size="xs"
            class="pointer-events-none absolute inset-e-0 -top-1.5 aspect-square size-4 p-0! ltr:translate-x-1/2 rtl:-translate-x-1/2"
            variant="highlight"
            rounded
            :aria-label="$t('Unread messages count')"
            role="status"
          >
            {{ countDisplay }}
          </CommonBadge>
        </div>
      </div>
    </Transition>
  </div>
</template>
