// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { animations } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { type Ref, type ShallowRef } from 'vue'

import { i18n } from '#shared/i18n/index.ts'
import { startAndEndEventsDNDPlugin } from '#shared/utils/startAndEndEventsDNDPlugin.ts'

import type { AnnouncerHandler } from '../accessibility/types'

export const useAccessibleDragAndDrop = <T extends HTMLElement, C extends object | string>(
  parent: ShallowRef<T | null>,
  children: Ref<C[]>,
  announceHandler: AnnouncerHandler,
  options: {
    dndStartCallback?: (parent: HTMLElement) => void
    dndEndCallback?: (parent: HTMLElement) => void
    dropZoneClass?: string
    synthDropZoneClass?: string
    draggingClass?: string
    getValue?: (item: C) => string
    /**
     * Whether the list is currently *not* draggable, for a list that comes and goes — a collapsed
     * sidebar, a sorting mode that arranges itself.
     *
     * Switch it by calling this composable again with the new value, never through the library's
     * own `updateConfig`: that one rebuilds the parent's whole configuration from the partial it
     * is handed (@formkit/drag-and-drop 0.6.1, `updateConfig` → `dragAndDrop`), so a
     * `{ disabled }` call silently drops everything set below — the drop zone classes that hide
     * the dragged item to leave a gap behind it, the animations, and the plugin that reports a
     * finished drag. `dragAndDrop` tears the parent down before setting it up again, so calling
     * it repeatedly is how the config is meant to be replaced.
     */
    disabled?: boolean
  } = {},
) => {
  const {
    dndStartCallback = () => {},
    dndEndCallback = () => {},
    dropZoneClass = '',
    synthDropZoneClass = '',
    draggingClass = '',
    getValue = (item) => (typeof item === 'string' ? item : String(item)),
    disabled = false,
  } = options

  const resolvedDropZoneClass = `opacity-0 dragging-active ${dropZoneClass}`
  const resolvedSynthDropZoneClass = `opacity-0 dragging-active ${synthDropZoneClass}`

  // Only one of the two is ever applied - which one depends on whether the drag is a native or a
  //   synthetic one - so guarding both together is safe: nothing is put back that was not there.
  const dropZoneClassNames = new Set(
    `${resolvedDropZoneClass} ${resolvedSynthDropZoneClass}`.split(' ').filter(Boolean),
  )

  /**
   * Puts the drop zone classes back whenever something rewrites the dragged element's `class`.
   *
   * Two owners write that attribute: the library adds these classes imperatively - `opacity-0` is
   * what hides the dragged item so the list visibly opens a gap for it - while Vue rewrites the
   * whole attribute (`el.className = …`) as soon as a `:class` binding on that element renders to
   * a different string. One bound to the item's index is enough, and every list here has one: they
   * outline the focused and the selected item that way, `useKeyboardKeysForDragAndDrop` focuses
   * the first item as soon as the list is focused (which pointing at it does), and each sort
   * during the drag shifts those indexes. Vue's patch then drops the library's classes and the
   * list stops making room for the item - intermittently, since a list that was never focused
   * renders the same string throughout and is never patched.
   *
   * The library takes the same precaution for the rewrites it knows about, but only for those:
   * `reapplyDragClasses` runs when a node is remapped, i.e. on a childList mutation, which an
   * attribute rewrite is not.
   *
   * Restores by the attribute's previous value rather than unconditionally, so this cannot get
   * ahead of the library: at `dragstart` the classes are deliberately not applied yet (they would
   * be captured into the native drag image), and what was not there a moment ago is not put back.
   */
  const dropZoneClassGuard = new MutationObserver((mutations) => {
    mutations.forEach(({ target, oldValue }) => {
      if (!(target instanceof HTMLElement)) return

      const previousClassNames = (oldValue ?? '').split(' ')

      const missing = previousClassNames.filter(
        (className) => dropZoneClassNames.has(className) && !target.classList.contains(className),
      )

      if (missing.length) target.classList.add(...missing)
    })
  })

  dragAndDrop({
    // Wrong library bug it should be ShallowRef
    parent: parent as Ref<HTMLElement>,
    values: children,
    disabled,
    plugins: [startAndEndEventsDNDPlugin(dndStartCallback, dndEndCallback), animations()],
    dropZoneClass: resolvedDropZoneClass,
    synthDropZoneClass: resolvedSynthDropZoneClass,
    draggingClass: `dragging-active ${draggingClass}`,
    onDragstart: (state) => {
      // Multi-drag moves several nodes at once, each carrying the classes.
      const draggedElements = state.draggedNodes?.map((node) => node.el) ?? [state.draggedNode.el]

      draggedElements.forEach((element) =>
        dropZoneClassGuard.observe(element, {
          attributes: true,
          attributeFilter: ['class'],
          attributeOldValue: true,
        }),
      )

      announceHandler(
        i18n.t(`Drag started for %s.`, getValue(state.draggedNode.data.value as unknown as C)),
      )
    },
    // Deliberately without naming the list: this composable serves several of them, and the
    //   listener is focused inside the one they are sorting - it carries its own `aria-label`,
    //   which a screen reader announces on entry. Interpolating a list name would need it as a
    //   translatable fragment, which does not survive being put into another language's sentence.
    onSort: (event) => {
      announceHandler(
        i18n.t(
          'Sorted %s to position %s.',
          getValue(event.draggedNodes[0].data.value as unknown as C),
          event.position + 1,
        ),
      )
    },
    onTransfer: (event) => {
      announceHandler(
        i18n.t(
          'Moved %s to position %s in the target list.',
          getValue(event.draggedNodes[0].data.value as unknown as C),
          event.targetIndex + 1,
        ),
      )
    },
    onDragend: (state) => {
      // Before the library drops the classes itself, which it does in a `requestAnimationFrame`
      //   after this callback - so the guard is already gone by then and does not fight it.
      dropZoneClassGuard.disconnect()

      announceHandler(
        i18n.t('Drag ended for %s.', getValue(state.draggedNode.data.value as unknown as C)),
      )
    },
  })
}
