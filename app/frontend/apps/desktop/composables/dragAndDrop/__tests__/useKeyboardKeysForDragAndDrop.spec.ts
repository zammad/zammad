// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h, ref, shallowRef } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { useKeyboardKeysForDragAndDrop } from '../useKeyboardKeysForDragAndDrop.ts'

interface Item {
  id: string
  title: string
}

const items = (count: number): Item[] =>
  Array.from({ length: count }, (_, index) => ({
    id: String(index + 1),
    title: `Item ${index + 1}`,
  }))

// A real element with a real layout, because the composable takes the column count and the
//   writing direction off the rendered list rather than off the classes it is written in.
const setupList = (
  itemCount: number,
  { columns, rtl }: { columns?: number; rtl?: boolean } = {},
) => {
  const element = document.createElement('ul')

  if (columns) element.style.gridTemplateColumns = Array(columns).fill('1fr').join(' ')
  if (rtl) element.style.direction = 'rtl'

  document.body.appendChild(element)

  const list = ref(items(itemCount))
  const onReorder = vi.fn()

  let keyboard!: ReturnType<typeof useKeyboardKeysForDragAndDrop<Item>>

  renderComponent(
    defineComponent({
      setup() {
        keyboard = useKeyboardKeysForDragAndDrop<Item>({
          items: list,
          parent: shallowRef(element),
          getValue: (item) => item.title,
          onReorder,
        })

        return () => h('ul')
      },
    }),
  )

  // The list has to have focus before it takes any key, and taking it focuses the first item.
  keyboard.handleFocus()

  const press = (key: string) => keyboard.handleKeydown(new KeyboardEvent('keydown', { key }))

  return { ...keyboard, list, onReorder, press }
}

describe('useKeyboardKeysForDragAndDrop', () => {
  it('steps through a plain list with every arrow key', () => {
    const { focusedItemIndex, press } = setupList(3)

    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(1)

    press('ArrowRight')
    expect(focusedItemIndex.value).toBe(2)

    press('ArrowUp')
    expect(focusedItemIndex.value).toBe(1)

    press('ArrowLeft')
    expect(focusedItemIndex.value).toBe(0)
  })

  it('wraps around the ends of a plain list', () => {
    const { focusedItemIndex, press } = setupList(3)

    press('ArrowUp')
    expect(focusedItemIndex.value).toBe(2)

    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(0)
  })

  it('moves by a whole row in a grid', () => {
    const { focusedItemIndex, press } = setupList(8, { columns: 3 })

    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(3)

    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(6)

    // Back to the top of the same column, rather than on past the end of the grid.
    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(0)

    press('ArrowUp')
    expect(focusedItemIndex.value).toBe(6)
  })

  it('moves by a single tile sideways in a grid, in reading order', () => {
    const { focusedItemIndex, press } = setupList(8, { columns: 3 })

    press('ArrowRight')
    expect(focusedItemIndex.value).toBe(1)

    // Over the row's edge into the next one, the way the tiles read.
    press('ArrowRight')
    press('ArrowRight')
    expect(focusedItemIndex.value).toBe(3)

    press('ArrowLeft')
    expect(focusedItemIndex.value).toBe(2)
  })

  it('skips the cells an incomplete last row does not have', () => {
    const { focusedItemIndex, press } = setupList(8, { columns: 3 })

    press('ArrowRight')
    press('ArrowRight')
    expect(focusedItemIndex.value).toBe(2)

    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(5)

    // The third row holds indexes 6 and 7 only, so this column wraps to its top.
    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(2)
  })

  it('follows the reading order of a right-to-left grid', () => {
    const { focusedItemIndex, press } = setupList(8, { columns: 3, rtl: true })

    press('ArrowLeft')
    expect(focusedItemIndex.value).toBe(1)

    press('ArrowRight')
    expect(focusedItemIndex.value).toBe(0)

    // Rows do not turn around with the writing direction.
    press('ArrowDown')
    expect(focusedItemIndex.value).toBe(3)
  })

  it('swaps two tiles a row apart', () => {
    const { list, onReorder, press, selectedItemIndex, focusedItemIndex } = setupList(8, {
      columns: 3,
    })

    press(' ')
    expect(selectedItemIndex.value).toBe(0)

    press('ArrowDown')
    press(' ')

    expect(list.value.map((item) => item.title)).toEqual([
      'Item 4',
      'Item 2',
      'Item 3',
      'Item 1',
      'Item 5',
      'Item 6',
      'Item 7',
      'Item 8',
    ])
    expect(onReorder).toHaveBeenCalledOnce()
    expect(selectedItemIndex.value).toBeNull()
    expect(focusedItemIndex.value).toBe(3)
  })

  it('builds focusedItemId from getId rather than getValue, so it matches the rendered item id even when the two diverge', () => {
    const element = document.createElement('ul')
    document.body.appendChild(element)

    let keyboard!: ReturnType<typeof useKeyboardKeysForDragAndDrop<Item>>

    renderComponent(
      defineComponent({
        setup() {
          keyboard = useKeyboardKeysForDragAndDrop<Item>({
            items: ref(items(3)),
            parent: shallowRef(element),
            getValue: (item) => item.title,
            getId: (item) => item.id,
          })

          return () => h('ul')
        },
      }),
    )

    keyboard.handleFocus()

    expect(keyboard.focusedItemId.value).toBe('item-1')
  })
})
