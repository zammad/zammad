<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { parents } from '@formkit/drag-and-drop'
import { useElementVisibility, useInfiniteScroll } from '@vueuse/core'
import { isEqual } from 'lodash-es'
import {
  computed,
  nextTick,
  ref,
  shallowRef,
  toRef,
  useTemplateRef,
  watch,
  type ComponentPublicInstance,
} from 'vue'
import { useRouter } from 'vue-router'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'
import { useAccessibleDragAndDrop } from '#desktop/composables/dragAndDrop/useAccessibleDragAndDrop.ts'
import { useKeyboardKeysForDragAndDrop } from '#desktop/composables/dragAndDrop/useKeyboardKeysForDragAndDrop.ts'
import { knowledgeBaseAnswerCreateRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import { isTranslationMissing } from '#desktop/entities/knowledge-base/utils/translationLocale.ts'

import {
  ANSWERS_PAGE_SIZE,
  useKnowledgeBaseAnswers,
} from '../../composables/useKnowledgeBaseAnswers.ts'
import { useKnowledgeBaseSorting } from '../../composables/useKnowledgeBaseSorting.ts'

import { ADD_CARD_VISIBILITY_THRESHOLD } from './addCardVisibility.ts'
import KnowledgeBaseAddAnswerCard from './KnowledgeBaseAddAnswerCard.vue'
import KnowledgeBaseAnswerCard from './KnowledgeBaseAnswerCard.vue'
import KnowledgeBaseAnswerCardSkeleton from './KnowledgeBaseAnswerCardSkeleton.vue'
import KnowledgeBaseAnswerListSkeleton from './KnowledgeBaseAnswerListSkeleton.vue'

import type { KnowledgeBaseAnswerCompact } from '../../types.ts'

const props = defineProps<{
  // The open category; without one (the knowledge base root) there are no answers.
  categoryId?: string
  // The browsed locale, forwarded from the page (the URL route prop).
  locale?: string
  // The layout's scroll container (it also scrolls the category grid); it drives
  //   the infinite scroll.
  contentContainerElement?: HTMLElement | null
  // Whether the open category takes new answers, from its own `policy.createAnswer` — never the
  //   global editor permission: granular permissions routinely make someone editor of one subtree
  //   and reader elsewhere, so that would offer a button the mutation refuses.
  canAddAnswer?: boolean
  // Whether the answers listed here may be edited, from the open category's `policy.updateAnswer`
  //   - one flag for every row, see KnowledgeBaseAnswerCard's own `canEdit`.
  canEditAnswer?: boolean
  // Likewise for deleting them, from the open category's `policy.destroyAnswer`.
  canDeleteAnswer?: boolean
  isSorting?: boolean
  // How many answers this category holds at its own level, from the cached entry the page it was
  //   opened from wrote (`knowledgeBaseCategoryPreInfo`). Sizes the skeleton below: the listing's
  //   own `totalCount` cannot, arriving with the very query the skeleton waits for.
  answerCount?: number
}>()

const router = useRouter()

// Reported upwards so the page's floating toolbar can drop its own add-answer shortcut while the
//   real card is on screen - the same thing the category grid does with its add card.
const addAnswerCardVisible = defineModel<boolean>('addAnswerCardVisible')

const addAnswerCardElement = useTemplateRef<ComponentPublicInstance>('add-answer-card')

// Immediate, because the page keys this list by the category and the locale it shows: a switch
//   remounts it, and until this reports the state of its own card the page still holds the one of
//   the previous list. A card that is out of view in both leaves that flag stale at `true`, which
//   costs the toolbar its add-answer shortcut for as long as the card stays off screen.
watch(
  useElementVisibility(addAnswerCardElement, { threshold: ADD_CARD_VISIBILITY_THRESHOLD }),
  (visible) => {
    addAnswerCardVisible.value = visible
  },
  { immediate: true },
)

// Pulled up in front of the listing query below: the mode the bar is previewing is one of that
//   query's arguments, so the answers arrive already ordered the way saving would order them —
//   and, being paginated, they could not be ordered correctly here anyway.
const {
  isArmed: isSortingArmed,
  isScopeRearranging,
  previewSortingMode,
  registerBaselineOrder,
  stageOrder,
} = useKnowledgeBaseSorting()

// Only while the answers are the list being arranged - the categories have their own turn.
const isRearranging = isScopeRearranging('answers')

const { answers, pagination, loading } = useKnowledgeBaseAnswers({
  categoryId: toRef(props, 'categoryId'),
  locale: toRef(props, 'locale'),
  sortingMode: previewSortingMode('answers'),
})

useInfiniteScroll(
  () => props.contentContainerElement,
  () => pagination.fetchNextPage(),
  {
    distance: 100,
    canLoadMore: () => pagination.hasNextPage,
  },
)

const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => pagination.loadingNewPage ?? false),
})

// A reorder has to name every answer of the category, so the whole list has to be here before the
//   first drag - a page still unloaded would be dropped from the order otherwise. Infinite scroll
//   alone cannot be relied on: the editor may never scroll.
const isLoadingAllAnswers = ref(false)

const loadAllAnswers = async () => {
  if (isLoadingAllAnswers.value) return

  isLoadingAllAnswers.value = true

  try {
    let previousCount = -1

    // Stops as soon as a page adds nothing, so a fetch that fails or returns the same cursor
    //   cannot keep the loop running.
    while (pagination.hasNextPage && answers.value.length > previousCount) {
      previousCount = answers.value.length
      // Sequential on purpose: each page is fetched from the cursor the previous one ended at,
      //   so there is nothing to run in parallel here.
      // oxlint-disable-next-line no-await-in-loop
      await pagination.fetchNextPage()
    }
  } finally {
    isLoadingAllAnswers.value = false
  }
}

// Also on a later `true`, not just on arming: the answers become the arranged list when the scope
//   tab is switched to them, and a refetch in between (a content update, a mode put back on
//   manual) leaves the list at page one again.
watch(
  () => isRearranging.value && pagination.hasNextPage,
  (shouldLoadAll) => {
    if (shouldLoadAll) loadAllAnswers().catch(() => {})
  },
  { immediate: true },
)

// Dragging is held back until the list is whole, so a drag can never produce a partial order.
const isDraggable = computed(
  () => isRearranging.value && !pagination.hasNextPage && !isLoadingAllAnswers.value,
)

// The card renders one answer as this locale has it, so the translation is unwrapped once here
//   rather than in the card: whether the title is this locale's own or a fallback is a question
//   only the caller can answer, and the list is where the locale is known.
const listedAnswers = computed(() =>
  answers.value.map((answer) => ({
    id: answer.id,
    visibility: answer.visibility,
    position: answer.position,
    title: answer.translation?.title,
    translationMissing: isTranslationMissing(answer.translation, props.locale),
  })),
)

// The list @formkit/drag-and-drop owns and reorders in place. Kept apart from `answers`, which is
//   the query result and must not be mutated, and synced back from it whenever it delivers.
const dndAnswers = shallowRef<KnowledgeBaseAnswerCompact[]>([])

watch(
  listedAnswers,
  (newAnswers) => {
    if (isEqual(dndAnswers.value, newAnswers)) return

    dndAnswers.value = [...newAnswers]
    registerBaselineOrder(
      'answers',
      newAnswers.map((answer) => answer.id),
    )
  },
  { immediate: true },
)

const dndParentElement = useTemplateRef('dnd-parent')

const { announce, messageNodeId } = useAnnouncer()

const getValue = (answer: KnowledgeBaseAnswerCompact) => answer.title || answer.id

// After a pointer drag the library has already rewritten the DOM, so its own values are the truth
//   - the same hand-off PersonalSettingOverviewOrder does.
const dndEndCallback = (parent: HTMLElement) => {
  const parentData = parents.get(parent)
  if (!parentData) return

  dndAnswers.value = [...(parentData.getValues(parent) as KnowledgeBaseAnswerCompact[])]
  stageOrder(
    'answers',
    dndAnswers.value.map((answer) => answer.id),
  )
}

// Set up only once the list is actually draggable, never on mount: until then the <ol> also holds
//   the add card and the paging skeletons, and @formkit/drag-and-drop warns whenever the children
//   it sees outnumber the values it was given.
const applyDragAndDrop = (disabled: boolean) => {
  useAccessibleDragAndDrop<HTMLElement, KnowledgeBaseAnswerCompact>(
    dndParentElement,
    dndAnswers,
    announce,
    { dndEndCallback, getValue, disabled },
  )
}

const {
  focusedItemIndex,
  selectedItemIndex,
  focusedItemId,
  handleKeydown,
  handleFocus,
  handleBlur,
} = useKeyboardKeysForDragAndDrop<KnowledgeBaseAnswerCompact>({
  items: dndAnswers,
  getValue,
  // The rendered card's id is always built from the answer id, never its (possibly missing or
  //   duplicate) title, so aria-activedescendant must match that rather than getValue.
  getId: (answer) => answer.id,
  onReorder: (newOrder) => {
    stageOrder(
      'answers',
      newOrder.map((answer) => answer.id),
    )
  },
})

// `nextTick`, so the tiles that are no answer have left the list before it is handed over.
//
// The whole configuration is re-applied on every switch rather than the `disabled` flag alone: the
//   library's `updateConfig` would throw the rest of it away (see the composable).
//
// On the element as much as on the flag, because the two come apart: previewing a sorting mode
//   refetches the answers, and a result that is not in the cache yet puts the loader back up -
//   which unmounts this <ol> and mounts a new one, leaving the drag engine attached to an element
//   that is no longer on the page.
watch([dndParentElement, isDraggable], async ([, draggable]) => {
  if (draggable) await nextTick()

  if (!dndParentElement.value) return

  applyDragAndDrop(!draggable)
})

// Only inside a category: an answer always belongs to one, so there is nothing to add at the
//   knowledge base root.
const canAddAnswerHere = computed(() => Boolean(props.categoryId) && Boolean(props.canAddAnswer))

// The card closes the list, so it may only appear once the list is actually closed: with pages
//   still to come - or coming in - it would sit between the answers and the paging skeletons and
//   read as the end of a list that then keeps growing. Nothing is lost while it is away: the
//   page's floating toolbar offers its add-answer shortcut exactly while this card is not on
//   screen, and an absent card reports itself as not visible just like an off-screen one.
const showAddAnswerCard = computed(
  () => canAddAnswerHere.value && !pagination.hasNextPage && !debouncedLoading.value,
)

// While sorting, the add card that otherwise stands in for an empty list is gone, so the list has
//   to say for itself that there is nothing to arrange yet - the mode picked in the bar still
//   applies to the answers that arrive later.
const showsSortingEmptyState = computed(() => isSortingArmed.value && !dndAnswers.value.length)

// The internal id is what the create form's category field works with (the form updater reads it
//   back to preselect the category), and the route builder mints the draft's tab id.
const addAnswer = () => {
  if (!props.locale || !props.categoryId) return

  router.push(knowledgeBaseAnswerCreateRoute(props.locale, getIdFromGraphQLId(props.categoryId)))
}

defineExpose({ addAnswer })
</script>

<template>
  <CommonLoader :loading="loading">
    <!-- One root element: the loader renders its slot inside a <Transition>, and the page's
         `v-show` needs an element of its own to hide. -->
    <div>
      <!-- Dropped while the empty state below takes its place: everything else in it is hidden
           while sorting anyway, and an empty list that still takes focus would announce itself as
           one to arrange. -->
      <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
      <ol
        v-if="!showsSortingEmptyState"
        ref="dnd-parent"
        class="group focus-visible:outline-offset-0.5! flex flex-col gap-4 rounded-xl focus-visible-app-default"
        :class="{ 'mt-4': !isSorting }"
        :tabindex="isDraggable ? 0 : undefined"
        :aria-label="isDraggable ? $t('Answer order list') : undefined"
        :aria-activedescendant="isDraggable ? focusedItemId : undefined"
        :aria-describedby="isDraggable ? messageNodeId : undefined"
        @focus="handleFocus"
        @blur="handleBlur"
        @keydown="handleKeydown"
      >
        <KnowledgeBaseAnswerCard
          v-for="(answer, index) in dndAnswers"
          :key="answer.id"
          :list-item-id="`item-${answer.id}`"
          v-bind="answer"
          :can-edit="canEditAnswer"
          :can-delete="canDeleteAnswer"
          :category-id="categoryId"
          :is-sorting="isSortingArmed"
          :is-rearranging="isRearranging"
          :class="{
            draggable: isDraggable,
            'rounded-xl -outline-offset-1 outline-blue-900 group-focus-visible:outline':
              index === focusedItemIndex,
            'rounded-xl outline -outline-offset-1 outline-blue-800!': index === selectedItemIndex,
          }"
          :draggable="isDraggable ? 'true' : undefined"
        />
        <!-- Also shown without answers: the only way to create the first one in a category. Not
             while rearranging: it is no answer, so it must not take part in the order. -->
        <KnowledgeBaseAddAnswerCard
          v-if="showAddAnswerCard && !isSortingArmed"
          ref="add-answer-card"
          @add="addAnswer"
        />
        <template v-if="debouncedLoading && !isSortingArmed">
          <KnowledgeBaseAnswerCardSkeleton v-for="i in 3" :key="i" :index="i" />
        </template>
      </ol>

      <!-- Same shape as the empty search results (KnowledgeBaseSearchResults.vue): it sits in the
           same place on the page and says the same kind of thing.

           Two lines, because an editor who arrives here has nothing to drag and would otherwise
           read the bar as pointless: the mode is stored on the category, so what they pick now is
           what places the answers that arrive later. -->
      <div
        v-if="showsSortingEmptyState"
        class="flex flex-col items-center justify-center gap-4 py-8"
        role="status"
      >
        <CommonIcon decorative name="file-richtext" size="medium" class="dark:text-neutral-500" />
        <div class="flex max-w-prose flex-col items-center">
          <CommonLabel tag="p" class="dark:text-neutral-500">
            {{ $t('There are no answers to arrange yet.') }}
          </CommonLabel>
          <CommonLabel tag="p" class="dark:text-neutral-500">
            {{ $t('The sorting mode you save here will apply to answers added later.') }}
          </CommonLabel>
        </div>
      </div>

      <!-- Its own list while rearranging: the one above is handed to the drag engine, which counts
           everything in it as an answer. -->
      <ol v-if="isLoadingAllAnswers" aria-hidden="true" class="mt-4 flex flex-col gap-4">
        <KnowledgeBaseAnswerCardSkeleton v-for="i in 3" :key="i" :index="i" />
      </ol>
    </div>

    <!-- The count comes from the category, not from this listing: `totalCount` arrives with the
         very query this is waiting for. The skeleton caps it at one page, which is all the first
         load asks for. -->
    <template #skeleton>
      <KnowledgeBaseAnswerListSkeleton
        :count="answerCount"
        :page-size="ANSWERS_PAGE_SIZE"
        :with-add-answer="canAddAnswerHere"
      />
    </template>
  </CommonLoader>
</template>
