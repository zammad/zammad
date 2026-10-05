<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { computed, toRef, useTemplateRef, type Ref } from 'vue'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useStickyTopCalculator } from '#desktop/components/Form/fields/FieldEditor/useStickyTopCalculator.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { useOffsetBottomWithin } from '#desktop/composables/useOffsetBottomWithin.ts'

import { HEADER_CONTENT_OUTER_CLASSES, HEADER_CONTENT_WIDTH_CLASSES } from './headerClasses.ts'
import { type HeaderContentWidth } from './types.ts'

interface Props {
  contentContainerElement: HTMLElement | null
  // The page's content-loading state, so the header can skeleton in lockstep
  //   instead of flashing stale data.
  loading?: boolean
  // Docks a warning alert below the header. Header and alert form one block that
  //   slides and sticks together for the full and the compact header alike, like
  //   the ticket detail top bar's channel alert.
  alertMessage?: string
  contentWidth?: HeaderContentWidth
  noTitle?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  contentWidth: 'wide',
})

const contentWidthClass = computed(() => HEADER_CONTENT_WIDTH_CLASSES[props.contentWidth])
const contentOuterClass = computed(() => HEADER_CONTENT_OUTER_CLASSES[props.contentWidth])

// Only dock the alert once the content has resolved; while loading the header
//   skeletons and there is no settled state to warn about yet.
const showAlert = computed(() => Boolean(props.alertMessage) && !props.loading)

const { height: fullBlockHeight } = useElementSize(useTemplateRef('full-wrapper'), undefined, {
  box: 'border-box',
})

const compactWrapperElement = useTemplateRef('compact-wrapper')

const { height: compactBlockHeight } = useElementSize(compactWrapperElement, undefined, {
  box: 'border-box',
})

const { y } = useElementScroll(toRef(props, 'contentContainerElement') as Ref<HTMLDivElement>)

// The compact header is absolutely positioned, and its containing block is not the
//   main content column: the nearest positioned ancestor is `#main-content`, which
//   spans the content sidebar too — and an absolutely positioned box is not clipped
//   by ancestors that are not its containing block. So pin it to the measured column
//   width, as the ticket detail top bar does; `left`/`right`/`width` together are
//   over-constrained, and the width wins.
const { width: contentContainerWidth } = useElementSize(toRef(props, 'contentContainerElement'))

const compactHeaderWidth = computed(() =>
  contentContainerWidth.value ? `${contentContainerWidth.value}px` : 'auto',
)

// Show the header earlier to always have it visible,
//   but account for the height of the displayed title beforehand.
const negativePadding = computed(() => (props.noTitle ? 0 : -30))

const compactHeaderOffset = computed(
  () => y.value - (fullBlockHeight.value + negativePadding.value),
)

const hasMeasuredHeaderHeights = computed(
  () => fullBlockHeight.value > 0 && compactBlockHeight.value > 0,
)

// The breadcrumb is the title line of the compact header, whichever header fills the slot.
const titleLineBottom = useOffsetBottomWithin(
  () => (props.loading ? null : compactWrapperElement.value?.querySelector('nav')),
  compactWrapperElement,
)

// The compact header is stacked above the full header (higher z-index), so it takes over as soon
// as any of its title line is in view, before it has fully slid into place - content may be too
// short to scroll that far. Interactivity/a11y exposure switches at the same point, so exactly
// one header is ever focusable/clickable/announced.
const isCompactHeaderVisible = computed(
  () => hasMeasuredHeaderHeights.value && compactHeaderOffset.value + titleLineBottom.value > 0,
)

const compactBlockTop = computed(() => Math.min(0, compactHeaderOffset.value))

const absoluteContainerOffset = computed(() => `${compactBlockTop.value}px`)

const fullBlockOffset = computed(() => Math.max(0, Math.min(y.value, fullBlockHeight.value)))

// Pull the whole block — header plus any docked alert — clear of the viewport, so
//   none of it lingers behind the compact header, whose background is translucent.
const stickyContainerTop = computed(() => `${-fullBlockOffset.value}px`)

const isFullBlockCovered = computed(
  () =>
    isCompactHeaderVisible.value &&
    compactBlockTop.value + compactBlockHeight.value >=
      fullBlockHeight.value - fullBlockOffset.value,
)

const alertBaseClasses = 'rounded-none bg-transparent! md:grid-cols-none md:justify-center'
const alertTranslucentClasses = getAlertClasses().translucent?.warning

useStickyTopCalculator(compactBlockHeight, { offset: -1 }) // avoid joining with the top bar bottom border
</script>

<template>
  <div
    ref="compact-wrapper"
    class="absolute inset-x-0 top-0 z-30 print:hidden"
    data-test-id="knowledge-base-header-compact"
    :style="{
      transform: `translateY(${absoluteContainerOffset})`,
      width: compactHeaderWidth,
    }"
  >
    <slot v-if="!loading" name="compact" :inert="!isCompactHeaderVisible" />

    <div
      v-if="showAlert"
      :class="alertTranslucentClasses"
      class="backdrop-blur-2xs"
      data-test-id="knowledge-base-header-alert-background"
    >
      <CommonAlert class="px-5.5!" :class="alertBaseClasses" variant="warning">
        {{ alertMessage }}
      </CommonAlert>
    </div>
  </div>

  <CommonLoader class="w-full" :loading="loading">
    <!-- The compact header covers this block before it has fully slid out, and its
         translucent background would let the remainder — most visibly a docked alert —
         show through. Hide it rather than shrink that head start, so the compact header
         still appears early, but not before the remainder is covered, or the content
         would flash through below the compact header. `visibility` keeps the block
         measured. -->
    <div
      ref="full-wrapper"
      class="sticky inset-x-0 top-0 z-10 w-full print:visible! print:static"
      :class="{ invisible: isFullBlockCovered }"
      data-test-id="knowledge-base-header-full"
      :style="{
        top: stickyContainerTop,
      }"
    >
      <slot name="full" :inert="isCompactHeaderVisible" />

      <div
        v-if="showAlert"
        :class="alertTranslucentClasses"
        class="flex justify-center px-5.5 backdrop-blur-2xs"
        data-test-id="knowledge-base-header-alert-background"
      >
        <CommonAlert
          class="basis-full px-0! print:hidden"
          :class="[alertBaseClasses, contentOuterClass, contentWidthClass]"
          variant="warning"
        >
          {{ alertMessage }}
        </CommonAlert>
      </div>
    </div>

    <template #skeleton>
      <div
        class="sticky inset-x-0 top-0 z-10 w-full"
        :style="{
          top: stickyContainerTop,
        }"
      >
        <slot name="skeleton" />
      </div>
    </template>
  </CommonLoader>
</template>
