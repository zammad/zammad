<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { computed, toRef, useTemplateRef, type Ref } from 'vue'

import type { Organization } from '#shared/graphql/types.ts'

import { useStickyTopCalculator } from '#desktop/components/Form/fields/FieldEditor/useStickyTopCalculator.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { useOffsetBottomWithin } from '#desktop/composables/useOffsetBottomWithin.ts'
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

const titleLineBottom = useOffsetBottomWithin(
  () => headerWithHiddenDetailsElement.value?.titleLine,
  headerWithHiddenDetailsElement,
)

// The compact header is stacked above the full header, so it takes over as soon as any of its title
// line is in view, before it has fully slid into place - content may be too short to scroll that far.
// Interactivity/a11y exposure switches at the same point, so exactly one header is ever exposed.
const isCompactHeaderVisible = computed(
  () => hasMeasuredHeaderHeights.value && compactHeaderOffset.value + titleLineBottom.value > 0,
)

const absoluteContainerOffset = computed(() => `${Math.min(0, compactHeaderOffset.value)}px`)

const stickyContainerTop = computed(() => {
  if (y.value < headerWithDetailsHeight.value) return `-${y.value}px`
  return `-${headerWithDetailsHeight.value}px`
})

// 7px is needed to compensate some overlap
useStickyTopCalculator(headerWithHiddenDetailsHeight, { offset: 7 })
</script>

<template>
  <TopBarHeaderCompact
    ref="header-with-hidden-details"
    class="absolute inset-x-0 top-0 z-30 bg-neutral-50/80 backdrop-blur-2xs dark:bg-gray-500/80"
    :inert="!isCompactHeaderVisible"
    :organization="organization"
    :organization-display-name="organizationDisplayName"
    data-test-id="organization-detail-top-bar-clipped-details"
    :style="{
      transform: `translateY(${absoluteContainerOffset})`,
      width: containerWidth,
    }"
  />

  <TopBarHeaderFull
    ref="header-with-details"
    class="sticky z-20 bg-neutral-50/80 backdrop-blur-2xs dark:bg-gray-500/80"
    :inert="isCompactHeaderVisible"
    :organization="organization"
    :organization-display-name="organizationDisplayName"
    data-test-id="organization-detail-top-bar-full-details"
    :style="{
      top: stickyContainerTop,
    }"
  />
</template>
