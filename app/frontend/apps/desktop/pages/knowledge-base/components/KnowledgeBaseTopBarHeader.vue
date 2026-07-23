<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementSize } from '@vueuse/core'
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed, toRef, useTemplateRef, type ComponentPublicInstance, type Ref } from 'vue'
import { useRouter } from 'vue-router'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import TopBarHeaderCompact from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderCompact.vue'
import TopBarHeaderFull from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFull.vue'
import TopBarHeaderFullSkeleton from '#desktop/pages/knowledge-base/components/KnowledgeBaseTopBarHeader/TopBarHeaderFullSkeleton.vue'

import { useKnowledgeBaseAccess } from '../../../entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import { useKnowledgeBaseStore } from '../../../entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBasePreviewUrl } from '../composables/useKnowledgeBasePreviewUrl.ts'
import { useKnowledgeBaseVisibility } from '../composables/useKnowledgeBaseVisibility.ts'

import type { CategoryBreadcrumb } from '../types.ts'
import type { TopBarHeaderProps } from './KnowledgeBaseTopBarHeader/types.ts'

type Props = {
  contentContainerElement: HTMLElement | null
  categoryBreadcrumb?: CategoryBreadcrumb
  // Whether the opened category shows public content in the current locale, so
  //   the header can offer its public-site link while browsing that category.
  categoryVisiblePublicly?: boolean
  // Whether the opened category has no own translation in the browsed locale, so
  //   the header can dock a warning alert below itself (full and compact alike).
  categoryTranslationMissing?: boolean
  // The page's content-loading state (a fresh, uncached category load), so the
  //   header can skeleton in lockstep instead of flashing a stale title.
  loading?: boolean
}

const props = defineProps<Props>()

const router = useRouter()

const headerWithDetailsElement = useTemplateRef<ComponentPublicInstance>('header-full')
const headerWithHiddenDetailsElement = useTemplateRef<ComponentPublicInstance>('header-compact')

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

// When the translation alert docks below the header, the whole header+alert
//   block is what slides and sticks — so its height (not the bare header's)
//   drives the scroll thresholds, mirroring the ticket detail top bar.
const wrapperElement = useTemplateRef('wrapper')

const { height: wrapperHeight } = useElementSize(wrapperElement, undefined, {
  box: 'border-box',
})
const { height: alertHeight } = useElementSize(useTemplateRef('alert'), undefined, {
  box: 'border-box',
})

const { activeLocale, knowledgeBase, loading: baseLoading } = storeToRefs(useKnowledgeBaseStore())

// Skeleton on the initial base load and again on a fresh (uncached) category
//   load, so the header never flashes a stale title before the new breadcrumb
//   resolves.
const loading = computed(() => baseLoading.value || Boolean(props.loading))

// Only dock the alert once the category has resolved; while loading the header
//   skeletons and there is no settled translation state to warn about yet.
const showTranslationAlert = computed(
  () => Boolean(props.categoryTranslationMissing) && !loading.value,
)

const title = computed(() => props.categoryBreadcrumb?.at(-1)?.title ?? __('Knowledge Base'))

const { canEdit, canRead } = useKnowledgeBaseAccess()

// Deep-link the "view public knowledge base" button to what is being browsed:
//   the opened category, or the base root. The link is only for internal users
//   (reader/editor) — never public visitors — and is offered when that node
//   shows public content in the current locale, or the user is an editor (who
//   can preview unpublished content); undefined otherwise hides the button.
const previewUrl = computed(() => {
  const locale = activeLocale.value
  if (!locale || !canRead.value) return undefined

  const openedCategory = props.categoryBreadcrumb?.at(-1)

  if (openedCategory) {
    if (!props.categoryVisiblePublicly && !canEdit.value) return undefined
    return knowledgeBasePreviewUrl('KnowledgeBaseCategory', openedCategory.id, locale)
  }

  const base = knowledgeBase.value
  if (!base || (!base.isVisiblePublicly && !canEdit.value)) return undefined
  return knowledgeBasePreviewUrl('KnowledgeBase', base.id, locale)
})

const metaTitle = computed(() => {
  const categoryTitle = props.categoryBreadcrumb?.at(-1)?.title

  const kbTitle = knowledgeBase.value?.title ?? __('Knowledge Base')

  return categoryTitle ? `${kbTitle} - ${categoryTitle}` : kbTitle
})

usePage({
  metaTitle,
})

const { y } = useElementScroll(toRef(props, 'contentContainerElement') as Ref<HTMLDivElement>)

// Show the header earlier to always have it visible
const NEGATIVE_PADDING = -30

// The full block's height that the compact header must clear before docking —
//   the header alone, or the header plus its alert when one is shown.
const fullBlockHeight = computed(() =>
  showTranslationAlert.value
    ? wrapperHeight.value + alertHeight.value
    : headerWithDetailsHeight.value,
)

const compactHeaderOffset = computed(() => y.value - (fullBlockHeight.value + NEGATIVE_PADDING))

const hasMeasuredHeaderHeights = computed(() => {
  if (showTranslationAlert.value) return wrapperHeight.value > 0 && alertHeight.value > 0

  return headerWithDetailsHeight.value > 0 && headerWithHiddenDetailsHeight.value > 0
})

// The compact header is stacked above the full header (higher z-index), so once it has fully
// slid into place it visually covers the full header. Interactivity/a11y exposure is switched
// over at the exact same point, so exactly one header is ever focusable/clickable/announced.
const isCompactHeaderVisible = computed(
  () => hasMeasuredHeaderHeights.value && compactHeaderOffset.value > 0,
)

const absoluteContainerOffset = computed(
  () => `${isCompactHeaderVisible.value ? 0 : compactHeaderOffset.value}px`,
)

const stickyContainerTop = computed(() => {
  // With an alert the sticky block also carries the negative padding, so both
  //   headers slide in lockstep; without it the bare header keeps its behavior.
  const threshold = showTranslationAlert.value
    ? fullBlockHeight.value + NEGATIVE_PADDING
    : headerWithDetailsHeight.value

  if (y.value < threshold) return `-${y.value}px`

  return `-${threshold}px`
})

const alertBaseClasses = 'rounded-none md:grid-cols-none md:justify-center'
const alertWithBlurClasses = `${alertBaseClasses} opacity-95 backdrop-blur-2xs`

const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  const categoryBreadcrumb = props.categoryBreadcrumb ?? []

  const items: BreadcrumbItem[] = [
    {
      label: __('Knowledge Base') as string,
      icon: 'book',
      iconOnly: true,
      // Link back to the localized root only while browsing a category.
      route:
        categoryBreadcrumb.length && activeLocale.value
          ? knowledgeBaseBrowseRoute(activeLocale.value)
          : undefined,
    },
  ]

  categoryBreadcrumb.forEach((category, index) => {
    const isLast = index === categoryBreadcrumb.length - 1

    const { currentMetaClass } = useKnowledgeBaseVisibility(category.visibility)

    items.push({
      label: category.title ?? '',
      // :TODO: Category icon
      // icon: 'category.categoryIcon,
      icon: 'folder',
      iconClass: currentMetaClass.value,
      route:
        isLast || !activeLocale.value
          ? undefined
          : knowledgeBaseBrowseRoute(activeLocale.value, category.id),
    })
  })

  return items
})

const localeItems = computed<DropdownItem[]>(
  () =>
    knowledgeBase.value?.kbLocales?.map((kbLocale) => ({
      key: kbLocale.id,
      label: kbLocale.systemLocale.name,
    })) ?? [],
)

const activeKbLocale = computed(() =>
  knowledgeBase.value?.kbLocales?.find(
    (kbLocale) => kbLocale.systemLocale.locale === activeLocale.value,
  ),
)

const selectedLocaleItem = computed<DropdownItem | undefined>({
  get: () =>
    activeKbLocale.value
      ? { key: activeKbLocale.value.id, label: activeKbLocale.value.systemLocale.name }
      : undefined,
  set: (item) => {
    const match = knowledgeBase.value?.kbLocales?.find((kbLocale) => kbLocale.id === item?.key)

    if (!match) return

    const localeCode = match.systemLocale.locale
    const currentCategory = props.categoryBreadcrumb?.at(-1)

    // The locale is part of the URL on both the root listing and category
    //   pages, so switch languages by navigating; the route change is what
    //   syncs the store, keeping URL and selector in lockstep. Stay in the open
    //   category when there is one, otherwise land on the localized root.
    router.push(knowledgeBaseBrowseRoute(localeCode, currentCategory?.id))
  },
})

const selectedLocaleCode = computed(
  () => activeKbLocale.value?.systemLocale.locale.toUpperCase() ?? '',
)

const headerProps = computed<TopBarHeaderProps>((currentProps) => {
  const updatedProps = {
    title: title.value,
    locales: localeItems.value,
    breadcrumbs: breadcrumbItems.value,
    localeCode: selectedLocaleCode.value,
    previewUrl: previewUrl.value,
  }

  if (currentProps && isEqual(currentProps, updatedProps)) return currentProps

  return updatedProps
})
</script>

<template>
  <!-- Opened category untranslated in the browsed locale: dock a warning alert
       below the header. Header and alert form one block that slides and sticks
       together for both the full and the compact header, like the ticket detail
       top bar's channel alert. -->
  <template v-if="showTranslationAlert">
    <div
      class="absolute inset-x-0 top-0 z-30 print:hidden"
      data-test-id="knowledge-base-header-compact"
      :style="{
        transform: `translateY(${absoluteContainerOffset})`,
      }"
    >
      <TopBarHeaderCompact
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :inert="!isCompactHeaderVisible"
      />
      <CommonAlert class="px-5.5!" :class="alertWithBlurClasses" variant="warning">
        {{ $t('No translation for this locale available') }}
      </CommonAlert>
    </div>

    <div
      ref="wrapper"
      class="sticky inset-x-0 top-0 z-10 w-full print:static"
      data-test-id="knowledge-base-header-full"
      :style="{
        top: stickyContainerTop,
      }"
    >
      <TopBarHeaderFull
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        :inert="isCompactHeaderVisible"
      />
      <div class="flex justify-center bg-yellow-50 px-5.5 dark:bg-yellow-900">
        <CommonAlert
          ref="alert"
          class="max-w-[calc(var(--container-7xl)-2.750rem)] basis-full px-0! print:hidden"
          :class="alertBaseClasses"
          variant="warning"
        >
          {{ $t('No translation for this locale available') }}
        </CommonAlert>
      </div>
    </div>
  </template>

  <template v-else>
    <TopBarHeaderCompact
      v-if="!loading"
      ref="header-compact"
      v-model:selected-locale="selectedLocaleItem"
      v-bind="headerProps"
      class="absolute inset-x-0 top-0 z-30 print:hidden"
      data-test-id="user-detail-header-compact"
      :inert="!isCompactHeaderVisible"
      :style="{
        transform: `translateY(${absoluteContainerOffset})`,
      }"
    />
    <CommonLoader class="w-full" :loading="loading">
      <TopBarHeaderFull
        ref="header-full"
        v-model:selected-locale="selectedLocaleItem"
        v-bind="headerProps"
        class="sticky inset-x-0 top-0 z-10 w-full print:static"
        data-test-id="user-detail-header-full"
        :inert="isCompactHeaderVisible"
        :style="{
          top: stickyContainerTop,
        }"
      />

      <template #skeleton>
        <TopBarHeaderFullSkeleton
          class="sticky inset-x-0 top-0 z-10 w-full"
          :style="{
            top: stickyContainerTop,
          }"
        />
      </template>
    </CommonLoader>
  </template>
</template>
