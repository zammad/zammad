<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { computed, toRef, useTemplateRef, type Ref } from 'vue'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import { useTicketChannel } from '#shared/entities/ticket/composables/useTicketChannel.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import { useStickyTopCalculator } from '#desktop/components/Form/fields/FieldEditor/useStickyTopCalculator.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { useTopBarHeaderHover } from '#desktop/composables/useTopBarHeaderHover.ts'
import TopBarHeader from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  contentContainerElement: HTMLDivElement | null
}

const props = defineProps<Props>()

const { ticket } = useTicketInformation()
const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
const { hasChannelAlert, channelAlert } = useTicketChannel(ticket)

const headerElement = useTemplateRef('header')
const headerWithHiddenDetails = useTemplateRef('header-with-hidden-details')

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
const wrapperWithHiddenDetails = useTemplateRef('wrapper-with-hidden-details')

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

const { containerEventHandlers, isHovering, updateIsHovering } = useTopBarHeaderHover(
  [wrapperElement, headerElement],
  {
    focusedElementSelector: 'input:focus',
    initialHovering: true,
  },
)

const containerWidth = computed(() => (width.value ? `${width.value}px` : 'auto'))

const absoluteContainerOffset = computed(() => {
  const totalHeight = shouldShowChannelAlert.value
    ? wrapperHeight.value + alertHeight.value + NEGATIVE_PADDING
    : headerHeight.value + NEGATIVE_PADDING
  const offset = y.value - totalHeight

  return `${offset > 0 ? 0 : offset}px`
})

const stickyContainerTop = computed(() => {
  const threshold = shouldShowChannelAlert.value
    ? wrapperHeight.value + NEGATIVE_PADDING + alertHeight.value
    : headerHeight.value

  if (isHovering.value) return '0px'
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
  if (shouldShowChannelAlert.value) {
    return isHovering.value ? wrapperHeight.value : wrapperWithHiddenDetailsHeight.value
  }

  return isHovering.value ? headerHeight.value : headerWithHiddenDetailsHeight.value
})

useStickyTopCalculator(currentVisibleHeaderHeight)

defineExpose({
  hideDetails: () => updateIsHovering(false),
})
</script>

<template>
  <template v-if="shouldShowChannelAlert">
    <div
      ref="wrapper-with-hidden-details"
      class="absolute top-0 right-0 left-0 z-10"
      data-test-id="ticket-detail-top-bar-clipped-details"
      :style="{
        transform: `translateY(${absoluteContainerOffset})`,
        width: containerWidth,
      }"
      v-on="containerEventHandlers"
    >
      <TopBarHeader
        :class="[headerBaseClasses, headerBackgroundClasses(true), 'p-3']"
        aria-hidden="true"
        :hide-details="true"
      />
      <CommonAlert :class="alertWithBlurClasses" :variant="channelAlert?.variant">
        {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
      </CommonAlert>
    </div>

    <div
      ref="wrapper"
      class="sticky top-0 right-0 left-0 z-30 w-full"
      data-test-id="ticket-detail-top-bar-full-details"
      :style="{
        top: stickyContainerTop,
      }"
      v-on="containerEventHandlers"
    >
      <TopBarHeader
        :class="[headerBaseClasses, headerBackgroundClasses(false), 'p-3']"
        :hide-details="false"
      />
      <CommonAlert ref="alert" :class="alertBaseClasses" :variant="channelAlert?.variant">
        {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
      </CommonAlert>
    </div>
  </template>

  <template v-else>
    <TopBarHeader
      ref="header-with-hidden-details"
      class="absolute top-0 right-0 left-0 z-30 p-3"
      :class="[
        headerBaseClasses,
        headerBackgroundClasses(true),
        { '-z-10! opacity-0': isHovering },
      ]"
      aria-hidden="true"
      :hide-details="true"
      data-test-id="ticket-detail-top-bar-clipped-details"
      :style="{
        transform: `translateY(${absoluteContainerOffset})`,
        width: containerWidth,
      }"
      v-on="containerEventHandlers"
    />
    <TopBarHeader
      ref="header"
      class="sticky top-0 right-0 left-0 z-10 w-full p-3"
      :class="[
        headerBaseClasses,
        headerBackgroundClasses(true),
        { 'transition-[top]': isHovering },
      ]"
      :hide-details="false"
      data-test-id="ticket-detail-top-bar-full-details"
      :style="{
        top: stickyContainerTop,
      }"
      v-on="containerEventHandlers"
    />
  </template>
</template>
