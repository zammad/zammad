<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { computed, toRef, useTemplateRef, type Ref } from 'vue'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import type { Organization } from '#shared/graphql/types.ts'

import { useStickyTopCalculator } from '#desktop/components/Form/fields/FieldEditor/useStickyTopCalculator.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import TopBarHeaderCompact from '#desktop/pages/organization/components/OrganizationDetailTopBar/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '#desktop/pages/organization/components/OrganizationDetailTopBar/TopBarHeaderFull.vue'

interface Props {
  organization: Organization
  organizationDisplayName: string
  contentContainerElement: HTMLElement | null
}

const props = defineProps<Props>()

const { y } = useElementScroll(toRef(props, 'contentContainerElement') as Ref<HTMLDivElement>)
const { width } = useElementSize(toRef(props, 'contentContainerElement'))

const headerWithDetailsElement = useTemplateRef('header-with-details')
const headerWithHiddenDetailsElement = useTemplateRef('header-with-hidden-details')

const { height: headerWithDetailsHeight } = useElementSize(headerWithDetailsElement, undefined, {
  box: 'border-box',
})

const { height: headerWithHiddenDetailsHeight } = useElementSize(
  headerWithHiddenDetailsElement,
  undefined,
  {
    box: 'border-box',
  },
)

const containerWidth = computed(() => (width.value ? `${width.value}px` : 'auto'))

// Show the header earlier to always have it visible
const NEGATIVE_PADDING = -30

const compactHeaderOffset = computed(
  () => y.value - (headerWithDetailsHeight.value + NEGATIVE_PADDING),
)

const hasMeasuredHeaderHeights = computed(
  () => headerWithDetailsHeight.value > 0 && headerWithHiddenDetailsHeight.value > 0,
)

// The compact header is stacked above the full header (higher z-index), so once it has fully
// slid into place it visually covers the full header. Interactivity/a11y exposure is switched
// over at the exact same point, so exactly one header is ever focusable/clickable/announced.
const isCompactHeaderVisible = computed(
  () => hasMeasuredHeaderHeights.value && compactHeaderOffset.value > 0,
)

const absoluteContainerOffset = computed(
  () => `${isCompactHeaderVisible.value ? 0 : Math.min(0, compactHeaderOffset.value)}px`,
)

const stickyContainerTop = computed(() => {
  if (y.value < headerWithDetailsHeight.value) return `-${y.value}px`
  return `-${headerWithDetailsHeight.value}px`
})

// 7px is needed to compensate some overlap
useStickyTopCalculator(headerWithHiddenDetailsHeight, { offset: 7 })

const { hasReducedMotion } = useReducedMotion()
</script>

<template>
  <TopBarHeaderCompact
    ref="header-with-hidden-details"
    class="absolute top-0 right-0 left-0 z-30 bg-neutral-50/80 backdrop-blur-2xs dark:bg-gray-500/80"
    :inert="!isCompactHeaderVisible"
    :organization="organization"
    :organization-display-name="organizationDisplayName"
    :style="{
      transform: `translateY(${absoluteContainerOffset})`,
      width: containerWidth,
    }"
  />

  <TopBarHeaderFull
    ref="header-with-details"
    class="sticky z-20 bg-neutral-50/80 backdrop-blur-2xs dark:bg-gray-500/80"
    :class="{ 'transition-[top]': !hasReducedMotion }"
    :inert="isCompactHeaderVisible"
    :organization="organization"
    :organization-display-name="organizationDisplayName"
    data-test-id="organization-detail-top-bar-full-details"
    :style="{
      top: stickyContainerTop,
    }"
  />
</template>
