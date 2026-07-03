<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { computed, toRef, useTemplateRef, type Ref } from 'vue'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import { useTicketChannel } from '#shared/entities/ticket/composables/useTicketChannel.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import { useStickyTopCalculator } from '#desktop/components/Form/fields/FieldEditor/useStickyTopCalculator.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import TopBarHeaderCompact from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/TopBarHeaderFull.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  contentContainerElement: HTMLDivElement | null
}

const props = defineProps<Props>()

const { ticket } = useTicketInformation()
const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
const { hasChannelAlert, channelAlert } = useTicketChannel(ticket)

const headerElement = useTemplateRef('header')
const headerWithHiddenDetails = useTemplateRef('header-compact')

const { height: headerHeight } = useElementSize(headerElement, undefined, {
  box: 'border-box',
})
const { height: headerWithHiddenDetailsHeight } = useElementSize(
  headerWithHiddenDetails,
  undefined,
  {
    box: 'border-box',
  },
)

const wrapperElement = useTemplateRef('wrapper')
const wrapperWithHiddenDetails = useTemplateRef('wrapper-compact')

const { height: wrapperHeight } = useElementSize(wrapperElement, undefined, {
  box: 'border-box',
})
const { height: wrapperWithHiddenDetailsHeight } = useElementSize(
  wrapperWithHiddenDetails,
  undefined,
  {
    box: 'border-box',
  },
)
const { height: alertHeight } = useElementSize(useTemplateRef('alert'), undefined, {
  box: 'border-box',
})

// Show the header earlier to always have it visible
const NEGATIVE_PADDING = -30

const shouldShowChannelAlert = computed(
  () => isTicketAgent.value && isTicketEditable.value && hasChannelAlert.value,
)

const { width } = useElementSize(toRef(props, 'contentContainerElement'))
const { y } = useElementScroll(toRef(props, 'contentContainerElement') as Ref<HTMLDivElement>)

const containerWidth = computed(() => (width.value ? `${width.value}px` : 'auto'))

const compactHeaderOffset = computed(() => {
  const totalHeight = shouldShowChannelAlert.value
    ? wrapperHeight.value + alertHeight.value + NEGATIVE_PADDING
    : headerHeight.value + NEGATIVE_PADDING

  return y.value - totalHeight
})

const hasMeasuredCompactHeaderThreshold = computed(() => {
  if (shouldShowChannelAlert.value) return wrapperHeight.value > 0 && alertHeight.value > 0

  return headerHeight.value > 0
})

// The compact header ends up as the persistent, fully docked header once scrolled far enough,
// while the full header slides away. Interactivity/a11y exposure is switched over at the exact
// same point, so exactly one header is ever focusable/clickable/announced at a time.
const isCompactHeaderVisible = computed(
  () => hasMeasuredCompactHeaderThreshold.value && compactHeaderOffset.value > 0,
)

const absoluteContainerOffset = computed(
  () => `${isCompactHeaderVisible.value ? 0 : compactHeaderOffset.value}px`,
)

const stickyContainerTop = computed(() => {
  const threshold = shouldShowChannelAlert.value
    ? wrapperHeight.value + NEGATIVE_PADDING + alertHeight.value
    : headerHeight.value

  if (y.value < threshold) return `-${y.value}px`

  return `-${threshold}px`
})

const headerBaseClasses = 'border-b border-neutral-100 dark:border-gray-900'
const headerBackgroundClasses = (withBlur: boolean) =>
  withBlur
    ? 'bg-neutral-50/80 backdrop-blur-2xs dark:bg-gray-500/80'
    : 'bg-neutral-50 dark:bg-gray-500'

const alertBaseClasses = 'rounded-none px-14 md:grid-cols-none md:justify-center'

const alertWithBlurClasses = `${alertBaseClasses} opacity-95 backdrop-blur-2xs`

const currentVisibleHeaderHeight = computed(() => {
  if (shouldShowChannelAlert.value) return wrapperWithHiddenDetailsHeight.value

  return headerWithHiddenDetailsHeight.value
})

useStickyTopCalculator(currentVisibleHeaderHeight, { offset: -1 }) // avoid joining with the top bar bottom border

const { hasReducedMotion } = useReducedMotion()
</script>

<template>
  <template v-if="shouldShowChannelAlert">
    <div
      ref="wrapper-compact"
      class="absolute inset-x-0 top-0 z-10 print:hidden"
      data-test-id="ticket-detail-top-bar-clipped-details"
      :style="{
        transform: `translateY(${absoluteContainerOffset})`,
        width: containerWidth,
      }"
    >
      <TopBarHeaderCompact
        :class="[headerBaseClasses, headerBackgroundClasses(true), 'p-3']"
        :inert="!isCompactHeaderVisible"
      />
      <CommonAlert :class="alertWithBlurClasses" :variant="channelAlert?.variant">
        {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
      </CommonAlert>
    </div>

    <div
      ref="wrapper"
      class="sticky inset-x-0 top-0 z-30 w-full"
      data-test-id="ticket-detail-top-bar-full-details"
      :style="{
        top: stickyContainerTop,
      }"
    >
      <TopBarHeaderFull
        :class="[headerBaseClasses, headerBackgroundClasses(false), 'p-3']"
        :inert="isCompactHeaderVisible"
      />
      <CommonAlert
        ref="alert"
        class="print:hidden"
        :class="alertBaseClasses"
        :variant="channelAlert?.variant"
      >
        {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
      </CommonAlert>
    </div>
  </template>

  <template v-else>
    <TopBarHeaderCompact
      ref="header-compact"
      class="absolute inset-x-0 top-0 z-30 print:hidden"
      :class="[headerBaseClasses, headerBackgroundClasses(true)]"
      :inert="!isCompactHeaderVisible"
      data-test-id="ticket-detail-top-bar-clipped-details"
      :style="{
        transform: `translateY(${absoluteContainerOffset})`,
        width: containerWidth,
      }"
    />
    <TopBarHeaderFull
      ref="header"
      class="sticky inset-x-0 top-0 z-10 w-full print:static"
      :class="[
        headerBaseClasses,
        headerBackgroundClasses(true),
        { 'transition-[top]': !hasReducedMotion },
      ]"
      :inert="isCompactHeaderVisible"
      data-test-id="ticket-detail-top-bar-full-details"
      :style="{
        top: stickyContainerTop,
      }"
    />
  </template>
</template>
