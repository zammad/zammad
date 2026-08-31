<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementVisibility } from '@vueuse/core'
import { useRouteQuery } from '@vueuse/router'
import {
  computed,
  onMounted,
  ref,
  toRef,
  useTemplateRef,
  watch,
  type ComponentPublicInstance,
} from 'vue'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { scrollIntoView } from '#shared/utils/dom.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'
import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'
import { useIndicator } from '#desktop/components/CommonIndicator/useIndicator.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

import { ADD_CARD_VISIBILITY_THRESHOLD } from '../components/KnowledgeBaseBrowse/addCardVisibility.ts'
import KnowledgeBaseAddCategoryCard from '../components/KnowledgeBaseBrowse/KnowledgeBaseAddCategoryCard.vue'
import KnowledgeBaseAnswerList from '../components/KnowledgeBaseBrowse/KnowledgeBaseAnswerList.vue'
import KnowledgeBaseCategoryCard from '../components/KnowledgeBaseBrowse/KnowledgeBaseCategoryCard.vue'
import KnowledgeBaseCategoryCardSkeleton from '../components/KnowledgeBaseBrowse/KnowledgeBaseCategoryCardSkeleton.vue'
import KnowledgeBaseSearchBar from '../components/KnowledgeBaseSearch/KnowledgeBaseSearchBar.vue'
import KnowledgeBaseSearchResults from '../components/KnowledgeBaseSearch/KnowledgeBaseSearchResults.vue'
import KnowledgeBaseSearchShortcuts from '../components/KnowledgeBaseSearch/KnowledgeBaseSearchShortcuts.vue'
import KnowledgeBaseTopBarHeader from '../components/KnowledgeBaseTopBarHeader/KnowledgeBaseTopBarHeader.vue'
import { useKnowledgeBaseCategoryFlyout } from '../composables/useKnowledgeBaseCategoryFlyout.ts'
import { useKnowledgeBaseCategorySubcategories } from '../composables/useKnowledgeBaseCategorySubcategories.ts'
import { useKnowledgeBaseEditFlyout } from '../composables/useKnowledgeBaseEditFlyout.ts'
import { useKnowledgeBaseSearchTerm } from '../composables/useKnowledgeBaseSearchTerm.ts'
import { knowledgeBaseBrowsedTitle } from '../utils/knowledgeBaseBrowsedTitle.ts'

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
  deletable: categoryDeletable,
  policy: categoryPolicy,
} = useKnowledgeBaseCategorySubcategories({
  categoryId,
  locale: toRef(props, 'localeCode'),
})

// What is browsed: a different category or locale is a different page. It keys the answer list, so
//   a switch drops that instance with its query and pagination state — reusing the handler would
//   let a `fetchMore` racing the switch page the new category with the old cursor.
const browsedPage = computed(() => `${props.localeCode}:${categoryId.value}`)

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

// Adding is gated by whoever would own the new category: the opened category (its own
//   `createSubcategory`), or the knowledge base at the root — where `CategoryPolicy#create?`
//   asks the knowledge base, so its `update` policy is the same answer. Granular editors are
//   commonly reader on the base and editor on one subtree, so the global permission alone
//   would offer them an add button the mutation refuses.
const knowledgeBase = toRef(useKnowledgeBaseStore(), 'knowledgeBase')

const canAddCategory = computed(() =>
  categoryId.value
    ? Boolean(categoryPolicy.value?.createSubcategory)
    : Boolean(knowledgeBase.value?.policy.update),
)

// Per record, like adding a category: a granular editor may write to one subtree and only read
//   elsewhere. There is nothing to add at the root, where no category is open.
const canAddAnswer = computed(() => Boolean(categoryPolicy.value?.createAnswer))

const { searchTerm, searchQuery, searchNow } = useKnowledgeBaseSearchTerm()

// While a term is committed to the URL, the results take the place of the browse content —
//   the category grid and the answer list alike.
const searchActive = computed(() => Boolean(searchQuery.value))

// The answer header's search button (KnowledgeBaseAnswerTopBarHeader.vue) links here with
//   `?focus=search` to land the cursor in the field it lands on - a one-shot signal, so it
//   is stripped right away instead of lingering across reloads or a back/forward.
const focusRequested = useRouteQuery<string | null>('focus', null)
const searchBarElement = useTemplateRef<{ focus: () => void }>('search-bar')

onMounted(() => {
  if (focusRequested.value !== 'search') return

  searchBarElement.value?.focus()
  focusRequested.value = null
})

const browsedTitle = computed(() =>
  knowledgeBaseBrowsedTitle({
    categoryBreadcrumb: breadcrumb.value,
    knowledgeBaseTitle: knowledgeBase.value?.title,
  }),
)

// Asked of the open category, once for the whole list: KnowledgeBase::AnswerPolicy#update?
//   resolves the access of the answer's category anyway, so every listed answer would answer the
//   same (KnowledgeBase::CategoryPolicy#update_answer?).
const canEditAnswer = computed(() => Boolean(categoryPolicy.value?.updateAnswer))

const { openKnowledgeBaseCategoryAddFlyout } = useKnowledgeBaseCategoryFlyout()
useKnowledgeBaseEditFlyout()

// Adding from within a category preselects that category as the parent; at the root
//   the updater falls back to its "top level" entry.
const addCategory = () => openKnowledgeBaseCategoryAddFlyout({ parentId: categoryId.value })

const addCategoryCardElement = useTemplateRef<ComponentPublicInstance>('add-category-card')

const isAddCategoryCardVisible = useElementVisibility(addCategoryCardElement, {
  threshold: ADD_CARD_VISIBILITY_THRESHOLD,
})

// Reported by the answer list, whose card it is.
const isAddAnswerCardVisible = ref(false)

const showAddCategoryAction = computed(
  () => canAddCategory.value && !isAddCategoryCardVisible.value,
)

const showAddAnswerAction = computed(() => canAddAnswer.value && !isAddAnswerCardVisible.value)

// The list owns the navigation - it knows the category and the locale it is showing.
const answerList = useTemplateRef<{ addAnswer: () => void }>('answer-list')

const addAnswer = () => answerList.value?.addAnswer()

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
const tileCount = computed(() => subcategories.value.length + (canAddCategory.value ? 1 : 0))

// Only the knowledge base root fills the page when it has no tiles: there its empty state is the
//   entire content. A category without subcategories — a reader sees no add card either — still
//   has its answers below, so the grid must not stretch above them.
const showsEmptyState = computed(() => !tileCount.value && !categoryId.value)

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

const { transitions } = useTransitionConfig()

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

// Opening another page starts it at the top. Nothing else does that: the scrolling element
//   is this container, not the window, so the router's scroll behavior never reaches it. Which
//   only shows when the new page is tall from its first frame — an answer list served from the
//   cache — because then the previous scroll position survives and the category section is
//   left out of view.
watch(browsedPage, scrollToStart)
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
      <CommonIndicator v-model="isReachingTop" class="translate-y-1" />
      <KnowledgeBaseTopBarHeader
        :content-container-element="contentContainerElement"
        :category-breadcrumb="breadcrumb"
        :category-visible-publicly="categoryVisiblePublicly"
        :category-translation-missing="categoryTranslationMissing"
        :category-deletable="categoryDeletable"
        :category-policy="categoryPolicy"
        :loading="headerLoading"
      />

      <!-- shrink-0: without it the flex scroll container compresses the section and clips its
           bottom padding above the overflowing answers. -->
      <section
        class="w-full max-w-7xl shrink-0 px-5.5 pt-4 pb-6"
        :class="{ 'flex grow flex-col': showsEmptyState || searchActive }"
      >
        <KnowledgeBaseSearchBar ref="search-bar" v-model="searchTerm" :title="browsedTitle">
          <template #controls>
            <KnowledgeBaseSearchShortcuts @search="searchNow" />
          </template>
        </KnowledgeBaseSearchBar>

        <!-- Keyed like the answer list: a scope or locale switch must drop the results with
             their query and pagination state rather than page the new scope with the old cursor.
             Outside the category loader below for the same reason the answer list is. -->
        <KnowledgeBaseSearchResults
          v-if="searchActive"
          :key="browsedPage"
          :query="searchQuery"
          :category-id="categoryId"
          :locale="localeCode"
          :content-container-element="contentContainerElement"
          @clear-search="searchTerm = ''"
        />

        <CommonLoader v-else class="flex w-full items-center" :loading="loading">
          <template #skeleton>
            <KnowledgeBaseCategoryCardSkeleton :count="categorySkeletonCount" />
          </template>

          <!-- One root element: the loader renders its slot inside a <Transition>. -->
          <div
            v-if="tileCount || showsEmptyState"
            :class="{ 'flex grow flex-col': showsEmptyState }"
          >
            <ol class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4">
              <KnowledgeBaseCategoryCard
                v-for="category in subcategories"
                :key="category.id"
                v-bind="category"
              />
              <!-- Also shown without subcategories: the only way to create the first one. -->
              <KnowledgeBaseAddCategoryCard
                v-if="canAddCategory"
                ref="add-category-card"
                @add="addCategory"
              />

              <li
                v-if="tileCount"
                aria-hidden="true"
                class="relative rounded-xl bg-blue-75 before:absolute before:inset-y-0 before:left-[calc(100%+1rem)] before:w-full before:rounded-xl before:bg-blue-75 after:absolute after:inset-y-0 after:left-[calc(200%+2rem)] after:w-full after:rounded-xl after:bg-blue-75 dark:bg-gray-700 dark:before:bg-gray-700 dark:after:bg-gray-700"
                :class="placeholderClasses"
              />
            </ol>

            <div
              v-if="showsEmptyState"
              class="flex grow flex-col items-center justify-center gap-2"
            >
              <CommonIcon name="book" size="medium" class="dark:text-neutral-500" />
              <CommonLabel tag="p" class="flex-col dark:text-neutral-500">
                <span>{{ $t('No knowledge base content is available yet.') }}</span>
                <span>{{ $t('Please contact your administrator.') }}</span>
              </CommonLabel>
            </div>
          </div>
        </CommonLoader>

        <!-- Outside the loader above: the answers bring their own query and skeleton, and wrapping
             them would remount the list on every category switch. -->
        <KnowledgeBaseAnswerList
          v-if="!searchActive"
          ref="answer-list"
          :key="browsedPage"
          v-model:add-answer-card-visible="isAddAnswerCardVisible"
          :category-id="categoryId"
          :locale="localeCode"
          :content-container-element="contentContainerElement"
          :can-add-answer="canAddAnswer"
          :can-edit-answer="canEditAnswer"
        />
      </section>

      <CommonIndicator v-model="isReachingBottom" />

      <div class="pointer-none sticky bottom-3 h-0 w-full print:hidden">
        <CommonFloatingToolbar
          :label="$t('Knowledge base actions')"
          :is-reaching-bottom="isReachingBottom"
          :is-reaching-top="isReachingTop"
          :hide-primary-action="!showAddAnswerAction && !showAddCategoryAction"
          class="absolute inset-e-3 bottom-0"
          @scroll-to-start="scrollToStart"
          @scroll-to-end="scrollToEnd"
        >
          <!-- Both shortcuts share the one action slot, each hidden while its own card is on
               screen - a toolbar duplicate of a button the user can already see is noise. The
               slot itself collapses once neither is left.
               Category first: it was the only action here before, and its grid sits above the
               answers on the page.
               The nesting is what `collapse-height` needs and what the toolbar's own scroll
               buttons do: the transition turns its target into a grid and squeezes the *child*,
               so it has to sit on a wrapper - putting it on the button collapses the button
               itself to nothing. -->
          <template v-if="canAddCategory || canAddAnswer" #primary-action>
            <div class="flex flex-col gap-1">
              <Transition :name="transitions.collapseHeight">
                <div v-if="showAddCategoryAction">
                  <div class="flex min-h-0">
                    <CommonButton
                      v-tooltip="$t('Add category')"
                      size="medium"
                      variant="secondary"
                      icon="folder-plus"
                      class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 dark:border-gray-900"
                      @click="addCategory"
                    />
                  </div>
                </div>
              </Transition>

              <!-- `kba-add`: the answer counterpart of `folder-plus`, a rich text document with
                   the same corner plus. From the design system's custom icons. -->
              <Transition :name="transitions.collapseHeight">
                <div v-if="showAddAnswerAction">
                  <div class="flex min-h-0">
                    <CommonButton
                      v-tooltip="$t('Add answer')"
                      size="medium"
                      variant="secondary"
                      icon="kba-add"
                      class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 dark:border-gray-900"
                      @click="addAnswer"
                    />
                  </div>
                </div>
              </Transition>
            </div>
          </template>
        </CommonFloatingToolbar>
      </div>
    </div>
  </LayoutContent>
</template>
