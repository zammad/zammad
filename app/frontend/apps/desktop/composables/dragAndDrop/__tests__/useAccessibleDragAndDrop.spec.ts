// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { parents, updateConfig } from '@formkit/drag-and-drop'
import { defineComponent, h, nextTick, ref, shallowRef } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { useAccessibleDragAndDrop } from '../useAccessibleDragAndDrop.ts'

interface Item {
  id: string
  title: string
}

const items = (): Item[] => [
  { id: '1', title: 'First' },
  { id: '2', title: 'Second' },
]

const setupList = () => {
  const parent = document.createElement('ul')

  items().forEach(() => parent.appendChild(document.createElement('li')))
  document.body.appendChild(parent)

  return { parentElement: shallowRef(parent), children: ref(items()) }
}

const configOf = (element: HTMLElement) => parents.get(element)?.config

// The drag start and drag end the library reports to us, which is what the drop zone class guard
//   lives between. Driven through the registered config rather than through synthesized pointer
//   events, which JSDOM cannot carry far enough to reach it.
const dragEvent = (draggedElement: HTMLElement) => {
  const node = { el: draggedElement, data: { value: items()[0] } }

  return { draggedNode: node, draggedNodes: [node] } as never
}

const startDrag = (parentElement: HTMLElement, draggedElement: HTMLElement) =>
  configOf(parentElement)?.onDragstart?.(dragEvent(draggedElement))

const endDrag = (parentElement: HTMLElement, draggedElement: HTMLElement) =>
  configOf(parentElement)?.onDragend?.(dragEvent(draggedElement))

// What the library puts on the dragged element once the drag is under way (its `dragstartClasses`,
//   deferred so the classes are not captured into the drag image), and what has to stay there
//   until the drag is over.
const applyDropZoneClasses = (parentElement: HTMLElement, draggedElement: HTMLElement) =>
  draggedElement.classList.add(
    ...(configOf(parentElement)?.dropZoneClass ?? '').split(' ').filter(Boolean),
  )

describe('useAccessibleDragAndDrop', () => {
  it('hides the dragged item so the list opens a gap for it', () => {
    const { parentElement, children } = setupList()

    useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn())

    expect(configOf(parentElement.value!)?.dropZoneClass).toContain('opacity-0')
    expect(configOf(parentElement.value!)?.synthDropZoneClass).toContain('opacity-0')
  })

  // The lists that come and go — the knowledge base sorting bar, the collapsed sidebar — switch
  //   dragging off and on again. @formkit/drag-and-drop's own `updateConfig` rebuilds the parent's
  //   whole configuration from the partial it is handed, so switching through it silently drops
  //   the drop zone classes, the animations and the plugin reporting a finished drag: the list
  //   still moves, but nothing makes room for the dragged item and nothing hears the drop.
  describe('switching dragging off and on', () => {
    it('keeps the rest of the configuration', () => {
      const { parentElement, children } = setupList()

      useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn())

      const pluginCount = configOf(parentElement.value!)?.plugins?.length

      useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn(), {
        disabled: true,
      })
      useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn(), {
        disabled: false,
      })

      const config = configOf(parentElement.value!)

      expect(config?.disabled).toBe(false)
      expect(config?.dropZoneClass).toContain('opacity-0')
      expect(config?.synthDropZoneClass).toContain('opacity-0')
      expect(config?.plugins).toHaveLength(pluginCount!)
    })

    // Guards the reason the call sites re-apply the whole configuration instead: should a future
    //   version of the library keep the rest of the config, this fails and the workaround can go.
    it('is why `updateConfig` is not used for it', () => {
      const { parentElement, children } = setupList()

      useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn())

      updateConfig(parentElement.value!, { disabled: true })

      expect(configOf(parentElement.value!)?.dropZoneClass).toBeUndefined()
    })

    it('stops handing the list to the drag engine while disabled', () => {
      const { parentElement, children } = setupList()

      useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn(), {
        disabled: true,
      })

      expect(parents.get(parentElement.value!)?.enabledNodes).toHaveLength(0)

      useAccessibleDragAndDrop<HTMLElement, Item>(parentElement, children, vi.fn(), {
        disabled: false,
      })

      expect(parents.get(parentElement.value!)?.enabledNodes).toHaveLength(items().length)
    })
  })

  // Vue owns the same `class` attribute the library writes the drop zone classes to, and rewrites
  //   the whole of it whenever a binding on that element renders to a different string - which
  //   every list here does while it is sorted, since they outline the focused and the selected
  //   item by index.
  describe('while an item is being dragged', () => {
    // Mirrors the shape every caller renders: a keyed list whose items carry a class bound to an
    //   index that moves while the list is sorted.
    const OutlinedList = defineComponent({
      props: { focusedIndex: { type: Number, default: null } },
      setup(props) {
        return () =>
          h(
            'ul',
            null,
            items().map((item, index) =>
              h('li', {
                key: item.id,
                'data-test-id': item.id,
                class: { 'outline-blue-900': index === props.focusedIndex },
              }),
            ),
          )
      },
    })

    const renderOutlinedList = () => {
      const view = renderComponent(OutlinedList, { props: { focusedIndex: null } })

      const parentElement = view.container.querySelector('ul') as HTMLElement
      const draggedElement = view.getByTestId('1')

      useAccessibleDragAndDrop<HTMLElement, Item>(shallowRef(parentElement), ref(items()), vi.fn())

      return { view, parentElement, draggedElement }
    }

    it('keeps the dragged item hidden when Vue rewrites its class', async () => {
      const { view, parentElement, draggedElement } = renderOutlinedList()

      startDrag(parentElement, draggedElement)
      applyDropZoneClasses(parentElement, draggedElement)

      expect(draggedElement.classList).toContain('opacity-0')

      // The list gains focus mid-drag, so the outline binding renders a different string and Vue
      //   writes the whole attribute - taking the library's classes with it.
      await view.rerender({ focusedIndex: 0 })
      await nextTick()

      expect(draggedElement.classList).toContain('opacity-0')
      expect(draggedElement.classList).toContain('outline-blue-900')
    })

    it('stops guarding once the drag is over, so the item comes back', async () => {
      const { view, parentElement, draggedElement } = renderOutlinedList()

      startDrag(parentElement, draggedElement)
      applyDropZoneClasses(parentElement, draggedElement)
      endDrag(parentElement, draggedElement)

      // What the library does in its own `requestAnimationFrame` after the drag ended.
      draggedElement.classList.remove('opacity-0', 'dragging-active')

      await view.rerender({ focusedIndex: 0 })
      await nextTick()

      expect(draggedElement.classList).not.toContain('opacity-0')
    })

    // At drag start the classes are deliberately still off: they would otherwise be captured into
    //   the drag image the browser takes of the element.
    it('does not hide the item before the library does', async () => {
      const { view, parentElement, draggedElement } = renderOutlinedList()

      startDrag(parentElement, draggedElement)

      await view.rerender({ focusedIndex: 0 })
      await nextTick()

      expect(draggedElement.classList).not.toContain('opacity-0')
    })
  })
})
