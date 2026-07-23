<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, useTemplateRef } from 'vue'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { scrollIntoView } from '#shared/utils/dom.ts'

import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'
import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'
import { useIndicator } from '#desktop/components/CommonIndicator/useIndicator.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

// import AddCategoryCard from '../components/AddCategoryCard.vue'
import { useKnowledgeBaseAccess } from '../../../entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import CategoryCard from '../components/CategoryCard.vue'
import KnowledgeBaseAnswerList from '../components/KnowledgeBaseAnswerList.vue'
import KnowledgeBaseCategorySkeleton from '../components/KnowledgeBaseCategorySkeleton.vue'
import KnowledgeBaseTopBarHeader from '../components/KnowledgeBaseTopBarHeader.vue'
import { useKnowledgeBaseCategorySubcategories } from '../composables/useKnowledgeBaseCategorySubcategories.ts'

// The browsed locale and category come from the URL as route props (see
//   routes.ts). Both are absent on the locale-less entry until the section
//   shell resolves the default locale and normalizes the URL.
const props = defineProps<{
  localeCode?: string
  categoryInternalId?: string
}>()

const contentContainerElement = useTemplateRef('content-container')

const categoryId = computed(() =>
  props.categoryInternalId
    ? convertToGraphQLId('KnowledgeBase::Category', props.categoryInternalId)
    : undefined,
)

const {
  subcategories,
  breadcrumb,
  loading,
  directSubcategoryCount,
  visiblePublicly: categoryVisiblePublicly,
  translationMissing: categoryTranslationMissing,
} = useKnowledgeBaseCategorySubcategories({
  categoryId,
  locale: toRef(props, 'localeCode'),
})

// The header needs only the breadcrumb, which is known immediately when opening
//   a category, so it can appear at once instead of waiting out the full load.
//   At the root there is no breadcrumb at all — the header shows only knowledge
//   base data (present since app start), so it never skeletons there, even when
//   the root content loads cold (e.g. entered via a category deep link).
const headerLoading = computed(
  () => loading.value && Boolean(categoryId.value) && !breadcrumb.value.length,
)

// Size the category skeleton to the opened category's next level when known;
//   otherwise fall back to a small default.
const DEFAULT_SKELETON_COUNT = 4
const categorySkeletonCount = computed(() => directSubcategoryCount.value || DEFAULT_SKELETON_COUNT)

const { canEdit } = useKnowledgeBaseAccess()

// Fill the trailing gap in the last grid row with placeholder tiles so the row
//   always looks complete. Must mirror the `grid-cols-*` breakpoints below.
const GRID_BREAKPOINTS = [
  {
    columns: 1,
    self: ['block', 'hidden'],
    before: ['before:block', 'before:hidden'],
    after: ['after:block', 'after:hidden'],
  },
  {
    columns: 2,
    self: ['sm:block', 'sm:hidden'],
    before: ['sm:before:block', 'sm:before:hidden'],
    after: ['sm:after:block', 'sm:after:hidden'],
  },
  {
    columns: 3,
    self: ['lg:block', 'lg:hidden'],
    before: ['lg:before:block', 'lg:before:hidden'],
    after: ['lg:after:block', 'lg:after:hidden'],
  },
  {
    columns: 4,
    self: ['2xl:block', '2xl:hidden'],
    before: ['2xl:before:block', '2xl:before:hidden'],
    after: ['2xl:after:block', '2xl:after:hidden'],
  },
] as const

// The add card occupies a grid cell too, so it counts towards the row fill.
const tileCount = computed(() => subcategories.value.length + (canEdit.value ? 1 : 0))

// For each breakpoint, reveal as many of the three filler tiles as there are
// empty cells in the last row ([0] = shown class, [1] = hidden class).
const placeholderClasses = computed(() =>
  GRID_BREAKPOINTS.flatMap(({ columns, self, before, after }) => {
    const needed = (columns - (tileCount.value % columns)) % columns
    return [
      needed >= 1 ? self[0] : self[1],
      needed >= 2 ? before[0] : before[1],
      needed >= 3 ? after[0] : after[1],
    ]
  }),
)

const { isIntersecting: isReachingBottom } = useIndicator()
const { isIntersecting: isReachingTop } = useIndicator()

const scrollToStart = () => {
  scrollIntoView(contentContainerElement.value, 'start', {
    behavior: 'instant',
  })
}
const scrollToEnd = () => {
  scrollIntoView(contentContainerElement.value, 'end', {
    behavior: 'instant',
  })
}
</script>

<template>
  <LayoutContent
    background-variant="primary"
    content-alignment="center"
    name="knowledge-base"
    no-scrollable
    no-padding
  >
    <div
      ref="content-container"
      class="@container flex size-full flex-col items-center overflow-y-auto"
    >
      <CommonIndicator v-model="isReachingTop" />
      <KnowledgeBaseTopBarHeader
        :content-container-element="contentContainerElement"
        :category-breadcrumb="breadcrumb"
        :category-visible-publicly="categoryVisiblePublicly"
        :category-translation-missing="categoryTranslationMissing"
        :loading="headerLoading"
      />

      <CommonLoader class="flex w-full items-center" :loading="loading">
        <template #skeleton>
          <KnowledgeBaseCategorySkeleton :count="categorySkeletonCount" />
        </template>

        <!-- shrink-0 keeps the section at its full content height inside the
             flex scroll container; without it the section is compressed and the
             bottom padding is clipped above the overflowing answers. -->
        <section
          class="w-full max-w-7xl shrink-0 px-5.5 py-3 pb-6"
          :class="{ 'flex grow flex-col': !tileCount }"
        >
          <ol class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4">
            <CategoryCard v-for="category in subcategories" :key="category.id" v-bind="category" />
            <!-- <AddCategoryCard v-if="canEdit" /> -->
            <!-- Temporary placeholder card until AddCategoryCard is reintroduced. -->
            <!-- Remove the <li> below once that happens. -->
            <li
              v-if="canEdit && subcategories.length"
              class="flex min-h-42 flex-col items-center justify-center rounded-xl bg-blue-75 px-4 py-2.5 dark:bg-gray-700"
            />

            <li
              v-if="tileCount"
              aria-hidden="true"
              class="relative rounded-xl bg-blue-75 before:absolute before:inset-y-0 before:left-[calc(100%+1rem)] before:w-full before:rounded-xl before:bg-blue-75 after:absolute after:inset-y-0 after:left-[calc(200%+2rem)] after:w-full after:rounded-xl after:bg-blue-75 dark:bg-gray-700 dark:before:bg-gray-700 dark:after:bg-gray-700"
              :class="placeholderClasses"
            />
          </ol>

          <div
            v-if="!tileCount && !categoryId"
            class="flex grow flex-col items-center justify-center gap-2"
          >
            <CommonIcon name="book" size="medium" class="dark:text-neutral-500" />
            <CommonLabel tag="p" class="flex-col dark:text-neutral-500">
              <span>{{ $t('No knowledge base content is available yet.') }}</span>
              <span>{{ $t('Please contact your administrator.') }}</span>
            </CommonLabel>
          </div>

          <KnowledgeBaseAnswerList
            :category-id="categoryId"
            :locale="localeCode"
            :content-container-element="contentContainerElement"
          />
        </section>
      </CommonLoader>

      <CommonIndicator v-model="isReachingBottom" />

      <div class="pointer-none sticky bottom-3 h-0 w-full print:hidden">
        <CommonFloatingToolbar
          :label="$t('Knowledge base actions')"
          :is-reaching-bottom="isReachingBottom"
          :is-reaching-top="isReachingTop"
          class="absolute inset-e-3 bottom-0"
          @scroll-to-start="scrollToStart"
          @scroll-to-end="scrollToEnd"
        >
          <!-- TODO <template #action>
            <CommonButton/>
          </template> -->
        </CommonFloatingToolbar>
      </div>
    </div>
  </LayoutContent>
</template>
