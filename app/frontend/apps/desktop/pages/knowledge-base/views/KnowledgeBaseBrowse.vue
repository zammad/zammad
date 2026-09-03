<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { parents } from '@formkit/drag-and-drop'
import { useElementVisibility } from '@vueuse/core'
import { useRouteQuery } from '@vueuse/router'
import { isEqual } from 'lodash-es'
import {
  computed,
  nextTick,
  onMounted,
  ref,
  shallowRef,
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
import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'
import { useAccessibleDragAndDrop } from '#desktop/composables/dragAndDrop/useAccessibleDragAndDrop.ts'
import { useKeyboardKeysForDragAndDrop } from '#desktop/composables/dragAndDrop/useKeyboardKeysForDragAndDrop.ts'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

import { ADD_CARD_VISIBILITY_THRESHOLD } from '../components/KnowledgeBaseBrowse/addCardVisibility.ts'
import KnowledgeBaseAddCategoryCard from '../components/KnowledgeBaseBrowse/KnowledgeBaseAddCategoryCard.vue'
import KnowledgeBaseAnswerList from '../components/KnowledgeBaseBrowse/KnowledgeBaseAnswerList.vue'
import KnowledgeBaseCategoryCard from '../components/KnowledgeBaseBrowse/KnowledgeBaseCategoryCard.vue'
import KnowledgeBaseCategoryCardSkeleton from '../components/KnowledgeBaseBrowse/KnowledgeBaseCategoryCardSkeleton.vue'
import KnowledgeBaseSortingBar from '../components/KnowledgeBaseBrowse/KnowledgeBaseSortingBar.vue'
import KnowledgeBaseContentTabs from '../components/KnowledgeBaseContentTabs/KnowledgeBaseContentTabs.vue'
import KnowledgeBaseSearchBar from '../components/KnowledgeBaseSearch/KnowledgeBaseSearchBar.vue'
import KnowledgeBaseSearchResults from '../components/KnowledgeBaseSearch/KnowledgeBaseSearchResults.vue'
import KnowledgeBaseSearchShortcuts from '../components/KnowledgeBaseSearch/KnowledgeBaseSearchShortcuts.vue'
import KnowledgeBaseTopBarHeader from '../components/KnowledgeBaseTopBarHeader/KnowledgeBaseTopBarHeader.vue'
import { useKnowledgeBaseCategoryFlyout } from '../composables/useKnowledgeBaseCategoryFlyout.ts'
import { useKnowledgeBaseCategorySubcategories } from '../composables/useKnowledgeBaseCategorySubcategories.ts'
import { useKnowledgeBaseEditFlyout } from '../composables/useKnowledgeBaseEditFlyout.ts'
import { useKnowledgeBaseSearchTerm } from '../composables/useKnowledgeBaseSearchTerm.ts'
import { useKnowledgeBaseSorting } from '../composables/useKnowledgeBaseSorting.ts'
import { useKnowledgeBaseSortingSave } from '../composables/useKnowledgeBaseSortingSave.ts'
import { knowledgeBaseBrowsedTitle } from '../utils/knowledgeBaseBrowsedTitle.ts'

import type { KnowledgeBaseCategoryCompact, KnowledgeBaseSortingModes } from '../types.ts'

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

// Pulled up in front of the listing query below: the mode the bar is previewing is one of that
//   query's arguments, so the categories arrive already ordered the way saving would order them.
const {
  isArmed: isSortingArmed,
  activeScope: sortingScope,
  isScopeRearranging,
  isDirty: isSortingDirty,
  sortingMode,
  previewSortingMode,
  registerBaselineOrder,
  stageOrder,
  resetKnowledgeBaseSorting,
} = useKnowledgeBaseSorting()

const isRearranging = isScopeRearranging('categories')

const {
  subcategories,
  breadcrumb,
  loading,
  directSubcategoryCount,
  visiblePublicly: categoryVisiblePublicly,
  translationMissing: categoryTranslationMissing,
  deletable: categoryDeletable,
  policy: categoryPolicy,
  directAnswerCount,
  categorySortingMode,
  answerSortingMode,
} = useKnowledgeBaseCategorySubcategories({
  categoryId,
  locale: toRef(props, 'localeCode'),
  sortingMode: previewSortingMode('categories'),
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

// Arranging the content of a node is editing that node, so it is gated like adding to it - and on
//   nothing else. Deliberately not on what the node currently holds: a mode is stored on the node
//   and applies to everything that arrives under it later, so it stays on offer for an empty or
//   single-item list, where it decides where the next categories and answers will land. Each list
//   then says for itself that it is empty (see below and KnowledgeBaseAnswerList.vue).
const canSortContent = computed(() =>
  categoryId.value
    ? Boolean(categoryPolicy.value?.update)
    : Boolean(knowledgeBase.value?.policy.update),
)

// Where the sorting bar starts: the opened category's two modes, or the knowledge base's one at
//   the root, which lists categories and nothing else. Undefined entries leave that list on the
//   default until its query resolves — the header cannot be reached before that in practice, the
//   sort entry being gated on the same query's policy.
const storedSortingModes = computed<KnowledgeBaseSortingModes>(() =>
  categoryId.value
    ? { categories: categorySortingMode.value, answers: answerSortingMode.value }
    : { categories: knowledgeBase.value?.categorySortingMode },
)

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

// The same, for deleting them (KnowledgeBase::CategoryPolicy#destroy_answer?).
const canDeleteAnswer = computed(() => Boolean(categoryPolicy.value?.destroyAnswer))

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

// Only one of the two lists is arranged at a time, so only that one is on screen. Hidden rather
//   than dropped: an order staged in the other list has to survive switching back and forth, and
//   remounting it would re-register its baseline and discard it.
const showsCategories = computed(() => !isSortingArmed.value || sortingScope.value === 'categories')
const showsAnswers = computed(() => !isSortingArmed.value || sortingScope.value === 'answers')

// Both entries are offered inside a category, an empty one included - it is what says where
//   content of that kind will go. Never at the knowledge base root, which holds no answers at
//   all: a zero there would promise something that can never arrive, and one entry is nothing to
//   pick between.
const showsContentTabs = computed(() => isSortingArmed.value && Boolean(categoryId.value))

// Which list the bar starts on. The categories, following the page order - unless the opened
//   category has none and does have answers, where the answers are the only list there is to
//   arrange: starting on the empty categories tab would hide the whole job behind a tab switch.
//   Only on arming, never afterwards: from then on the tabs are the editor's to pick.
watch(isSortingArmed, (armed) => {
  if (!armed || !categoryId.value) return
  if (subcategories.value.length || !directAnswerCount.value) return

  sortingScope.value = 'answers'
})

// The grid @formkit/drag-and-drop owns and reorders in place, kept apart from the query result.
const dndSubcategories = shallowRef<KnowledgeBaseCategoryCompact[]>([])

watch(
  subcategories,
  (newSubcategories) => {
    if (isEqual(dndSubcategories.value, newSubcategories)) return

    dndSubcategories.value = [...newSubcategories]
    registerBaselineOrder(
      'categories',
      newSubcategories.map((category) => category.id),
    )
  },
  { immediate: true },
)

const dndParentElement = useTemplateRef('dnd-parent')

const { announce, messageNodeId } = useAnnouncer()

const categoryValue = (category: KnowledgeBaseCategoryCompact) => category.title || category.id

// After a pointer drag the library has already rewritten the DOM, so its own values are the truth.
const dndEndCallback = (parent: HTMLElement) => {
  const parentData = parents.get(parent)
  if (!parentData) return

  dndSubcategories.value = [...(parentData.getValues(parent) as KnowledgeBaseCategoryCompact[])]
  stageOrder(
    'categories',
    dndSubcategories.value.map((category) => category.id),
  )
}

// Set up only once the grid is actually rearranged, never on mount: until then it also holds the
//   add card and the row-filler tile, and @formkit/drag-and-drop warns whenever the children it
//   sees outnumber the values it was given.
const applyDragAndDrop = (disabled: boolean) => {
  useAccessibleDragAndDrop<HTMLElement, KnowledgeBaseCategoryCompact>(
    dndParentElement,
    dndSubcategories,
    announce,
    { dndEndCallback, getValue: categoryValue, disabled },
  )
}

const {
  focusedItemIndex,
  selectedItemIndex,
  focusedItemId,
  handleKeydown,
  handleFocus,
  handleBlur,
} = useKeyboardKeysForDragAndDrop<KnowledgeBaseCategoryCompact>({
  items: dndSubcategories,
  // A grid, so its arrow keys move by row as much as by tile - the composable takes the column
  //   count off the element, which is the only place the container query has resolved it.
  parent: dndParentElement,
  getValue: categoryValue,
  // The rendered card's id is always built from the category id, never its (possibly missing or
  //   duplicate) title, so aria-activedescendant must match that rather than categoryValue.
  getId: (category) => category.id,
  onReorder: (newOrder) => {
    stageOrder(
      'categories',
      newOrder.map((category) => category.id),
    )
  },
})

// `nextTick`, so the tiles that are no category have left the grid before it is handed over.
//
// The whole configuration is re-applied on every switch rather than the `disabled` flag alone: the
//   library's `updateConfig` would throw the rest of it away (see the composable).
//
// On the element as much as on the flag, because the two come apart: previewing a sorting mode
//   refetches the listing, and a result that is not in the cache yet puts the loader back up -
//   which unmounts this <ol> and mounts a new one, leaving the drag engine attached to an element
//   that is no longer on the page.
watch([dndParentElement, isRearranging], async ([, rearranging]) => {
  if (rearranging) await nextTick()

  if (!dndParentElement.value) return

  applyDragAndDrop(!rearranging)
})

const { isSaving: isSavingSorting, saveSorting } = useKnowledgeBaseSortingSave(categoryId)

// The add card occupies a grid cell too, so it counts towards the row fill - but not while sorting,
//   where it is hidden so it cannot take part in the order (the same condition it renders under).
const tileCount = computed(
  () => subcategories.value.length + (canAddCategory.value && !isSortingArmed.value ? 1 : 0),
)

// Only the knowledge base root fills the page when it has no tiles: there its empty state is the
//   entire content. A category without subcategories — a reader sees no add card either — still
//   has its answers below, so the grid must not stretch above them. Never while sorting, which
//   brings an empty state of its own for the list being arranged.
const showsEmptyState = computed(
  () => !tileCount.value && !categoryId.value && !isSortingArmed.value,
)

// While sorting, the add card that otherwise stands in for an empty grid is gone, so the grid has
//   to say for itself that there is nothing to arrange yet - the mode picked in the bar still
//   applies to the categories that arrive later.
const showsSortingEmptyState = computed(() => isSortingArmed.value && !subcategories.value.length)

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
watch(browsedPage, () => {
  scrollToStart()

  // A mode picked for one category must not be carried into the next, and a staged order belongs
  //   to the list it was made in.
  resetKnowledgeBaseSorting()
})
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
        :can-sort-content="canSortContent"
        :sorting-modes="storedSortingModes"
        :loading="headerLoading"
      />

      <!-- shrink-0: without it the flex scroll container compresses the section and clips its
           bottom padding above the overflowing answers. -->
      <section
        class="w-full max-w-7xl shrink-0 px-5.5 pt-4 pb-6"
        :class="{ 'flex grow flex-col': showsEmptyState || searchActive }"
      >
        <!-- Not while sorting: searching would replace the very content being arranged. -->
        <KnowledgeBaseSearchBar
          v-if="!isSortingArmed"
          ref="search-bar"
          v-model="searchTerm"
          :title="browsedTitle"
        >
          <template #controls>
            <KnowledgeBaseSearchShortcuts @search="searchNow" />
          </template>
        </KnowledgeBaseSearchBar>

        <!-- Takes the search bar's place while sorting: it is the same slot on the page, and the
             two are never both useful - searching would replace the content being arranged. -->
        <KnowledgeBaseContentTabs
          v-if="showsContentTabs"
          v-model="sortingScope"
          class="mb-4"
          :category-count="subcategories.length"
          :answer-count="directAnswerCount ?? 0"
        />

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
            v-if="tileCount || showsEmptyState || showsSortingEmptyState"
            v-show="showsCategories"
            :class="{ 'flex grow flex-col': showsEmptyState }"
          >
            <!-- Dropped while the empty state below takes its place: everything else in it is
                 hidden while sorting anyway, and an empty grid that still takes focus would
                 announce itself as one to arrange. -->
            <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
            <ol
              v-if="!showsSortingEmptyState"
              ref="dnd-parent"
              class="group focus-visible:outline-offset-0.5! grid grid-cols-1 gap-4 rounded-xl focus-visible-app-default sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4"
              :tabindex="isRearranging ? 0 : undefined"
              :aria-label="isRearranging ? $t('Category order list') : undefined"
              :aria-activedescendant="isRearranging ? focusedItemId : undefined"
              :aria-describedby="isRearranging ? messageNodeId : undefined"
              @focus="handleFocus"
              @blur="handleBlur"
              @keydown="handleKeydown"
            >
              <KnowledgeBaseCategoryCard
                v-for="(category, index) in dndSubcategories"
                :key="category.id"
                :list-item-id="`item-${category.id}`"
                v-bind="category"
                :is-sorting="isSortingArmed"
                :is-rearranging="isRearranging"
                :is-focused="index === focusedItemIndex"
                :is-selected="index === selectedItemIndex"
                :class="{
                  draggable: isRearranging,
                }"
                :draggable="isRearranging ? 'true' : undefined"
              />
              <!-- Also shown without subcategories: the only way to create the first one. Not
                   while rearranging: it is no category, so it must not take part in the order. -->
              <KnowledgeBaseAddCategoryCard
                v-if="canAddCategory && !isSortingArmed"
                ref="add-category-card"
                @add="addCategory"
              />

              <li
                v-if="tileCount && !isSortingArmed"
                aria-hidden="true"
                class="relative rounded-xl bg-blue-75 before:absolute before:inset-y-0 before:left-[calc(100%+1rem)] before:w-full before:rounded-xl before:bg-blue-75 after:absolute after:inset-y-0 after:left-[calc(200%+2rem)] after:w-full after:rounded-xl after:bg-blue-75 dark:bg-gray-700 dark:before:bg-gray-700 dark:after:bg-gray-700"
                :class="placeholderClasses"
              />
            </ol>

            <div
              v-if="showsSortingEmptyState"
              class="flex flex-col items-center justify-center gap-4 py-8"
              role="status"
            >
              <CommonIcon
                decorative
                name="folder"
                size="medium"
                class="text-stone-200! dark:text-neutral-500!"
              />
              <div class="flex max-w-prose flex-col items-center">
                <CommonLabel tag="p" class="text-stone-200! dark:text-neutral-500!">
                  {{ $t('There are no categories to arrange yet.') }}
                </CommonLabel>
                <CommonLabel tag="p" class="text-stone-200! dark:text-neutral-500!">
                  {{ $t('The sorting mode you save here will apply to categories added later.') }}
                </CommonLabel>
              </div>
            </div>

            <div
              v-if="showsEmptyState"
              class="flex grow flex-col items-center justify-center gap-2"
            >
              <CommonIcon
                name="book"
                size="medium"
                class="text-stone-200! dark:text-neutral-500!"
              />
              <div class="flex flex-col">
                <CommonLabel tag="p" class="text-stone-200! dark:text-neutral-500!">
                  {{ $t('No knowledge base content is available yet.') }}
                </CommonLabel>
                <CommonLabel tag="p" class="text-stone-200! dark:text-neutral-500!">
                  {{ $t('Please contact your administrator.') }}
                </CommonLabel>
              </div>
            </div>
          </div>
        </CommonLoader>

        <!-- Outside the loader above: the answers bring their own query and skeleton, and wrapping
             them would remount the list on every category switch. -->
        <KnowledgeBaseAnswerList
          v-if="!searchActive"
          v-show="showsAnswers"
          ref="answer-list"
          :key="browsedPage"
          v-model:add-answer-card-visible="isAddAnswerCardVisible"
          :category-id="categoryId"
          :locale="localeCode"
          :content-container-element="contentContainerElement"
          :can-add-answer="canAddAnswer"
          :can-edit-answer="canEditAnswer"
          :can-delete-answer="canDeleteAnswer"
          :is-sorting="isSortingArmed"
        />
      </section>

      <CommonIndicator v-model="isReachingBottom" />

      <!-- Not while sorting: the bottom bar takes over there, and adding is not on offer. -->
      <div v-if="!isSortingArmed" class="pointer-none sticky bottom-3 h-0 w-full print:hidden">
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

    <!-- The condition belongs on the slot, not on the component inside it: the layout reserves
         the row for as long as the slot is passed at all, so an empty one would shorten the
         content by a bar that is not there. -->
    <template v-if="isSortingArmed" #bottomBar>
      <KnowledgeBaseSortingBar
        v-model="sortingMode"
        :dirty="isSortingDirty"
        :saving="isSavingSorting"
        @cancel="resetKnowledgeBaseSorting"
        @save="saveSorting"
      />
    </template>
  </LayoutContent>
</template>
