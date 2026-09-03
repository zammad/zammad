// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseSortingMode } from '#shared/graphql/types.ts'

import {
  armKnowledgeBaseSorting,
  resetKnowledgeBaseSorting,
  useKnowledgeBaseSorting,
} from '../useKnowledgeBaseSorting.ts'

const { Manual, Alphabetical, LastUpdate } = EnumKnowledgeBaseSortingMode

// Module-level state, so each example starts from a disarmed one - the browse page does the same
//   whenever the browsed category or locale changes.
beforeEach(() => {
  resetKnowledgeBaseSorting()
})

describe('useKnowledgeBaseSorting', () => {
  it('starts from the modes the browsed node is stored with', () => {
    const sorting = useKnowledgeBaseSorting()

    expect(sorting.isArmed.value).toBe(false)

    armKnowledgeBaseSorting({ categories: Alphabetical, answers: LastUpdate })

    expect(sorting.isArmed.value).toBe(true)
    expect(sorting.activeScope.value).toBe('categories')
    expect(sorting.sortingMode.value).toBe(Alphabetical)
    expect(sorting.isDirty.value).toBe(false)

    sorting.activeScope.value = 'answers'

    expect(sorting.sortingMode.value).toBe(LastUpdate)
  })

  // Only the manual mode is rearrangeable - the other two are the server's to order - and only the
  //   list currently on screen, since the other one is waiting its turn.
  it('only rearranges the manual mode of the scope on screen', () => {
    const sorting = useKnowledgeBaseSorting()
    const categories = sorting.isScopeRearranging('categories')
    const answers = sorting.isScopeRearranging('answers')

    armKnowledgeBaseSorting()

    expect(categories.value).toBe(true)
    expect(answers.value).toBe(false)

    sorting.activeScope.value = 'answers'

    expect(categories.value).toBe(false)
    expect(answers.value).toBe(true)

    sorting.sortingMode.value = Alphabetical

    expect(answers.value).toBe(false)
  })

  it('sets a mode on the scope on screen alone', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.activeScope.value = 'answers'
    sorting.sortingMode.value = Alphabetical

    expect(sorting.pendingChanges.value).toEqual([{ scope: 'answers', sortingMode: Alphabetical }])

    sorting.activeScope.value = 'categories'

    expect(sorting.sortingMode.value).toBe(Manual)
  })

  it('collects a rearranged list for saving', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.registerBaselineOrder('categories', ['1', '2', '3'])
    sorting.stageOrder('categories', ['2', '1', '3'])

    expect(sorting.isDirty.value).toBe(true)
    expect(sorting.pendingChanges.value).toEqual([
      { scope: 'categories', sortingMode: Manual, orderedIds: ['2', '1', '3'] },
    ])
  })

  // The mutation refuses a `manual` call without the whole list, and the point of switching to it
  //   is to keep the order that is on screen - so the untouched baseline is what goes along.
  it('sends the order on screen when a list is put on manual without dragging', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting({ categories: Alphabetical })
    sorting.registerBaselineOrder('categories', ['1', '2', '3'])
    sorting.sortingMode.value = Manual

    expect(sorting.pendingChanges.value).toEqual([
      { scope: 'categories', sortingMode: Manual, orderedIds: ['1', '2', '3'] },
    ])
  })

  // An automatic mode derives the order from the content itself, and the backend refuses a list
  //   sent alongside one.
  it('sends no order with an automatic mode', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.registerBaselineOrder('categories', ['1', '2'])
    sorting.sortingMode.value = LastUpdate

    expect(sorting.pendingChanges.value).toEqual([{ scope: 'categories', sortingMode: LastUpdate }])
  })

  it('ignores a list dragged back into the order it already had', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.registerBaselineOrder('answers', ['1', '2'])
    sorting.stageOrder('answers', ['1', '2'])

    expect(sorting.isDirty.value).toBe(false)
    expect(sorting.pendingChanges.value).toEqual([])
  })

  // The requirement behind the whole scope split: both lists can be arranged before the single
  //   Save at the bottom is pressed, so switching between them must carry everything along.
  it('keeps both scopes staged across a switch and saves them together', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()

    sorting.registerBaselineOrder('categories', ['c1', 'c2'])
    sorting.stageOrder('categories', ['c2', 'c1'])

    sorting.activeScope.value = 'answers'

    // Still dirty while the changed list is off screen - Save must not go quiet on work the
    //   editor cannot see.
    expect(sorting.isDirty.value).toBe(true)

    sorting.registerBaselineOrder('answers', ['a1', 'a2'])
    sorting.stageOrder('answers', ['a2', 'a1'])

    sorting.activeScope.value = 'categories'

    expect(sorting.pendingChanges.value).toEqual([
      { scope: 'categories', sortingMode: Manual, orderedIds: ['c2', 'c1'] },
      { scope: 'answers', sortingMode: Manual, orderedIds: ['a2', 'a1'] },
    ])
  })

  // An order made by hand has no meaning under a mode the server decides, so picking one drops it
  //   rather than saving it alongside - for that scope only.
  it('drops a staged order when its scope is put on an automatic mode', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.registerBaselineOrder('categories', ['c1', 'c2'])
    sorting.stageOrder('categories', ['c2', 'c1'])

    sorting.activeScope.value = 'answers'
    sorting.registerBaselineOrder('answers', ['a1', 'a2'])
    sorting.stageOrder('answers', ['a2', 'a1'])
    sorting.sortingMode.value = Alphabetical

    expect(sorting.pendingChanges.value).toEqual([
      { scope: 'categories', sortingMode: Manual, orderedIds: ['c2', 'c1'] },
      { scope: 'answers', sortingMode: Alphabetical },
    ])
  })

  // A list that reloaded - a subscription refetch, a page loaded in - is not the list the staged
  //   order was made from. Its own scope only: the two come from separate queries.
  it('drops a staged order when its own list reloads, and only that one', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.registerBaselineOrder('categories', ['c1', 'c2'])
    sorting.stageOrder('categories', ['c2', 'c1'])
    sorting.registerBaselineOrder('answers', ['a1', 'a2'])
    sorting.stageOrder('answers', ['a2', 'a1'])

    sorting.registerBaselineOrder('answers', ['a1', 'a2'])

    expect(sorting.pendingChanges.value).toEqual([
      { scope: 'categories', sortingMode: Manual, orderedIds: ['c2', 'c1'] },
    ])
  })

  it('drops everything when the browsed page changes', () => {
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    sorting.registerBaselineOrder('categories', ['1', '2'])
    sorting.stageOrder('categories', ['2', '1'])

    resetKnowledgeBaseSorting()

    expect(sorting.isArmed.value).toBe(false)
    expect(sorting.isDirty.value).toBe(false)
  })
})
