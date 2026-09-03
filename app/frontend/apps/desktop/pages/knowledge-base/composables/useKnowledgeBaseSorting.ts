// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, ref } from 'vue'

import { EnumKnowledgeBaseSortingMode } from '#shared/graphql/types.ts'

import type {
  KnowledgeBaseSortingMode,
  KnowledgeBaseSortingModes,
  KnowledgeBaseSortingScope,
} from '../types.ts'

const SORTING_SCOPES: KnowledgeBaseSortingScope[] = ['categories', 'answers']

// What one reorder mutation is given for one list: the mode it is to be sorted in from now on,
//   and — only with `manual`, which is the sole mode that reads a stored order back — the whole
//   list in the wanted order. The backend refuses ids against any other mode and requires them
//   with this one, so the two always travel together (Gql::Mutations::KnowledgeBase::Reorder::*).
export interface KnowledgeBaseSortingChange {
  scope: KnowledgeBaseSortingScope
  sortingMode: KnowledgeBaseSortingMode
  orderedIds?: string[]
}

const emptyOrders = (): Record<KnowledgeBaseSortingScope, string[]> => ({
  categories: [],
  answers: [],
})

const allScopesOn = (
  mode: KnowledgeBaseSortingMode,
): Record<KnowledgeBaseSortingScope, KnowledgeBaseSortingMode> => ({
  categories: mode,
  answers: mode,
})

// Module-level, like the flyout composables: the header arms the state, the sorting bar drives it,
//   and the category grid and the answer list read it — none of them can reach the others through
//   props, and all of them are talking about the one node currently browsed.
const isArmed = ref(false)

// Which of the two lists is being arranged, i.e. which one the page shows and which one the bar
//   sets the mode of. Display state only: switching it must clear nothing, since both scopes are
//   staged at once and go to the server on the single Save below.
const activeScope = ref<KnowledgeBaseSortingScope>('categories')

// The modes the browsed node is stored with, and the ones the editor has picked in the bar. Kept
//   apart so Cancel has something to go back to and Save knows which ones moved at all. Per scope,
//   because a node sorts its categories and its answers independently.
const storedSortingModes = ref(allScopesOn(EnumKnowledgeBaseSortingMode.Manual))
const sortingModes = ref(allScopesOn(EnumKnowledgeBaseSortingMode.Manual))

// Ids in the order the server delivered them, against which a rearrangement is a change, and the
//   order the editor has dragged them into. Both lists register their own baseline, since each is
//   loaded by its own query.
const baselineOrders = ref(emptyOrders())
const stagedOrders = ref(emptyOrders())

/**
 * Whether one list is being rearranged: it is the one on screen, and it is in the manual mode.
 * The other list is neither draggable nor navigation-locked while it waits its turn.
 */
const isScopeRearranging = (scope: KnowledgeBaseSortingScope) =>
  computed(
    () =>
      isArmed.value &&
      activeScope.value === scope &&
      sortingModes.value[scope] === EnumKnowledgeBaseSortingMode.Manual,
  )

// Which lists the editor actually moved — what Save has to send, and nothing more. A scope only
//   counts while it is manual: picking an automatic mode discards a hand-made order rather than
//   saving it. Deliberately not limited to the scope on screen — the other one may have been
//   arranged before the tab was switched, and there is a single Save for both.
const changedOrderScopes = computed<KnowledgeBaseSortingScope[]>(() => {
  if (!isArmed.value) return []

  return SORTING_SCOPES.filter(
    (scope) =>
      sortingModes.value[scope] === EnumKnowledgeBaseSortingMode.Manual &&
      stagedOrders.value[scope].length &&
      !isEqual(stagedOrders.value[scope], baselineOrders.value[scope]),
  )
})

const changedModeScopes = computed<KnowledgeBaseSortingScope[]>(() => {
  if (!isArmed.value) return []

  return SORTING_SCOPES.filter(
    (scope) => sortingModes.value[scope] !== storedSortingModes.value[scope],
  )
})

/**
 * Enters the rearrange state on the browsed node, starting from the modes it is stored with.
 * Called from the browse header, which has no setup scope of its own to hold this in.
 *
 * The knowledge base root passes the `categories` entry alone — it holds no answers — which
 * leaves that scope on the default both stored and picked, so it is never part of a Save.
 */
export const armKnowledgeBaseSorting = (currentSortingModes: KnowledgeBaseSortingModes = {}) => {
  const modes = { ...allScopesOn(EnumKnowledgeBaseSortingMode.Manual), ...currentSortingModes }

  storedSortingModes.value = modes
  sortingModes.value = { ...modes }
  stagedOrders.value = emptyOrders()
  activeScope.value = 'categories'
  isArmed.value = true
}

/**
 * Leaves the state and drops everything staged. Also the way out when the browsed page changes
 * under it — a mode picked for one category must not be carried into the next.
 */
export const resetKnowledgeBaseSorting = () => {
  isArmed.value = false
  stagedOrders.value = emptyOrders()
  baselineOrders.value = emptyOrders()
}

export const useKnowledgeBaseSorting = () => {
  /**
   * The order a list was rendered in before anything was dragged. Re-registered whenever the
   * query behind it delivers, so a refetched list moves its baseline with it.
   */
  const registerBaselineOrder = (scope: KnowledgeBaseSortingScope, ids: string[]) => {
    baselineOrders.value = { ...baselineOrders.value, [scope]: ids }

    // A list that reloaded is no longer the list the staged order was made from. Only ever its
    //   own scope: the two are loaded by separate queries, so one reloading says nothing about
    //   an order staged in the other.
    if (stagedOrders.value[scope].length) {
      stagedOrders.value = { ...stagedOrders.value, [scope]: [] }
    }
  }

  const stageOrder = (scope: KnowledgeBaseSortingScope, ids: string[]) => {
    stagedOrders.value = { ...stagedOrders.value, [scope]: ids }
  }

  /**
   * The mode a list is to be *shown* in right now, for the query that lists it — the picked one
   * for as long as it differs from the stored one, and nothing at all otherwise, which leaves that
   * query listing in the mode the node is stored with.
   *
   * Handed to the listing query rather than applied to the loaded records, so a picked mode is
   * previewed by the very code the saved order comes back through (KnowledgeBase::Category /
   * KnowledgeBase::Answer.sorted_by_mode). Ruby compares strings by codepoint and the database by
   * its collation, which is why that order is settled in SQL for both stacks — a third opinion
   * formed in the browser could only disagree with it. For the answers it is also the only
   * correct option at all: they arrive paginated, so a page sorted client-side would page wrongly.
   *
   * Nothing while the picked mode *is* the stored one, so putting the bar up refetches neither
   * list. That round-trip would show the very order already on screen, and it would arrive after
   * the editor has started dragging — re-registering the baseline and discarding the order they
   * had just made (see #registerBaselineOrder).
   */
  const previewSortingMode = (scope: KnowledgeBaseSortingScope) =>
    computed<KnowledgeBaseSortingMode | undefined>(() => {
      if (!isArmed.value) return undefined

      const mode = sortingModes.value[scope]

      return mode === storedSortingModes.value[scope] ? undefined : mode
    })

  // The mode of the list on screen, which is what the bar sets — writing it through to that
  //   scope keeps the bar a plain `v-model` and makes it follow the scope tabs on its own.
  const sortingMode = computed<KnowledgeBaseSortingMode>({
    get: () => sortingModes.value[activeScope.value],
    set: (mode) => {
      sortingModes.value = { ...sortingModes.value, [activeScope.value]: mode }
    },
  })

  /**
   * What Save has to persist, one entry per list that moved — mode, order, or both, since a
   * single mutation call carries them together. Both scopes at once: the tab in view has no say
   * in it, as both can be changed before the one Save is pressed.
   *
   * A `manual` entry always names the whole list, even when only the mode was switched to it:
   * that is the mutation's contract, and it is what makes a list an editor puts on manual keep
   * the order it was showing at that moment. The staged order when there is one, the order the
   * server delivered otherwise.
   */
  const pendingChanges = computed<KnowledgeBaseSortingChange[]>(() =>
    SORTING_SCOPES.filter(
      (scope) =>
        changedModeScopes.value.includes(scope) || changedOrderScopes.value.includes(scope),
    ).map((scope) => {
      const mode = sortingModes.value[scope]

      // An automatic mode derives the order from the content itself, and the backend refuses a
      //   list sent alongside one.
      if (mode !== EnumKnowledgeBaseSortingMode.Manual) return { scope, sortingMode: mode }

      const staged = stagedOrders.value[scope]

      return {
        scope,
        sortingMode: mode,
        orderedIds: staged.length ? staged : baselineOrders.value[scope],
      }
    }),
  )

  // True as soon as *any* scope moved, not just the one in view: Save must not sit disabled on
  //   top of work the editor cannot currently see.
  const isDirty = computed(() => pendingChanges.value.length > 0)

  return {
    isArmed: computed(() => isArmed.value),
    activeScope,
    isScopeRearranging,
    isDirty,
    sortingMode,
    previewSortingMode,
    storedSortingModes: computed(() => storedSortingModes.value),
    pendingChanges,
    registerBaselineOrder,
    stageOrder,
    armKnowledgeBaseSorting,
    resetKnowledgeBaseSorting,
  }
}
