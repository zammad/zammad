// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, onMounted, onUnmounted, watch, type ComputedRef, type Ref } from 'vue'

import type { TicketArticleHighlightedText } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { AnnouncerHandler } from '#desktop/composables/accessibility/types.ts'
import { useTicketArticleHighlightedTextUpsertMutation } from '#desktop/entities/ticket-article/graphql/mutations/highlightedTextUpsert.api.ts'

import { useHighlightMenuState } from '../../TicketDetailTopBar/TopBarHeader/useHighlightMenuState.ts'

import { collectCharAnchors, extractText } from './utils.ts'

import type { CharAnchor, HighlightRange, SelectionContext } from './types.ts'

const sortByStart = (a: HighlightRange, b: HighlightRange) => a.startIndex - b.startIndex

const toRange = ({ startIndex, endIndex, colorClass }: HighlightRange): HighlightRange => ({
  startIndex,
  endIndex,
  colorClass,
})

const carveOutSelection = (
  highlight: HighlightRange,
  startIndex: number,
  endIndex: number,
): HighlightRange[] => {
  // No overlap with the selected interval.
  if (highlight.endIndex <= startIndex || highlight.startIndex >= endIndex)
    return [toRange(highlight)]

  const segments: HighlightRange[] = []

  // Keep left remainder.
  if (highlight.startIndex < startIndex)
    segments.push({
      startIndex: highlight.startIndex,
      endIndex: startIndex,
      colorClass: highlight.colorClass,
    })

  // Keep right remainder.
  if (highlight.endIndex > endIndex)
    segments.push({
      startIndex: endIndex,
      endIndex: highlight.endIndex,
      colorClass: highlight.colorClass,
    })

  return segments
}

const mergeAdjacentSameColor = (highlights: HighlightRange[]): HighlightRange[] => {
  const sorted = [...highlights].sort(sortByStart)
  const merged: HighlightRange[] = []

  sorted.forEach((highlight) => {
    const previous = merged.at(-1)

    if (
      previous?.colorClass === highlight?.colorClass &&
      previous.endIndex >= highlight.startIndex
    ) {
      previous.endIndex = Math.max(previous.endIndex, highlight.endIndex)
      return
    }

    merged.push({ ...highlight })
  })

  return merged
}

const findLastIndex = (
  anchors: Array<CharAnchor | null>,
  predicate: (anchor: CharAnchor) => boolean,
  fallback: number,
): number => {
  const lastIndex = anchors.findLastIndex((anchor) => anchor !== null && predicate(anchor))

  return lastIndex >= 0 ? lastIndex + 1 : fallback
}

const domStartToCharIndex = (
  anchors: Array<CharAnchor | null>,
  node: Node,
  offset: number,
): number => {
  if (node.nodeType === Node.TEXT_NODE) {
    // Normal case: find the anchor for the char at position `offset`.
    const anchorIndex = anchors.findIndex(
      (anchor) => anchor !== null && anchor.node === node && anchor.charIndex === offset,
    )
    if (anchorIndex >= 0) return anchorIndex

    // `offset` is past the end of the text node (e.g. backward drag released after
    // the last character). Start the selection right after this text node.
    const lastInNode = anchors.findLastIndex((anchor) => anchor !== null && anchor.node === node)
    return lastInNode >= 0 ? lastInNode + 1 : 0
  }

  if (offset === 0) {
    // Start is at the very beginning of the element.
    const indexInside = anchors.findIndex(
      (anchor) => anchor !== null && (node as Element).contains(anchor.node),
    )
    if (indexInside >= 0) return indexInside

    // Empty element — find first anchor following in document order.
    const followingIndex = anchors.findIndex(
      (anchor) =>
        anchor !== null &&
        !!(node.compareDocumentPosition(anchor.node) & Node.DOCUMENT_POSITION_FOLLOWING),
    )
    return followingIndex >= 0 ? followingIndex : anchors.length
  }

  // offset > 0: start is after the first `offset` children (e.g. backward drag
  // released right after the last child of a paragraph element).
  const childrenBeforeOffset = Array.from(node.childNodes).slice(0, offset)
  const lastInsideIndex = anchors.findLastIndex(
    (anchor) =>
      anchor !== null &&
      childrenBeforeOffset.some((child) => child === anchor.node || child.contains(anchor.node)),
  )
  if (lastInsideIndex >= 0) return lastInsideIndex + 1

  // No anchors in those children — find first anchor following this node.
  const followingIndex = anchors.findIndex(
    (anchor) =>
      anchor !== null &&
      !!(node.compareDocumentPosition(anchor.node) & Node.DOCUMENT_POSITION_FOLLOWING),
  )
  return followingIndex >= 0 ? followingIndex : anchors.length
}

const domEndToCharIndex = (
  anchors: Array<CharAnchor | null>,
  node: Node,
  offset: number,
): number => {
  if (node.nodeType !== Node.TEXT_NODE) {
    // offset === 0 means the cursor is at the very beginning of the element
    // (e.g. an empty <p>). No children precede it, so find the last anchor
    // that is positioned before `node` in document order.
    if (offset === 0)
      return findLastIndex(
        anchors,
        (anchor) =>
          !!(node.compareDocumentPosition(anchor.node) & Node.DOCUMENT_POSITION_PRECEDING),
        0,
      )

    const childrenBeforeEnd = Array.from(node.childNodes).slice(0, offset)

    return findLastIndex(
      anchors,
      (anchor) =>
        childrenBeforeEnd.some((child) => child === anchor.node || child.contains(anchor.node)),
      0,
    )
  }

  if (offset === 0) return findLastIndex(anchors, (anchor) => anchor.node !== node, 0)

  return findLastIndex(
    anchors,
    (anchor) => anchor.node === node && anchor.charIndex === offset - 1,
    anchors.length,
  )
}

export const useArticleHighlightsSelection = (
  bubbleBodyElement: Ref<HTMLElement | undefined>,
  highlightedTexts: ComputedRef<TicketArticleHighlightedText[] | undefined>,
  articleId: ComputedRef<string>,
  onHighlightApplied?: AnnouncerHandler,
) => {
  const { isActive, isEraserActive, activeMenuItem } = useHighlightMenuState()
  const { mutate } = useTicketArticleHighlightedTextUpsertMutation()

  const getContainer = (): HTMLElement | null => {
    const root = bubbleBodyElement.value
    if (!root) return null

    return root.querySelector<HTMLElement>('.inner-article-body') ?? root
  }

  const getSelectionContext = (container: HTMLElement): SelectionContext | null => {
    const selection = window.getSelection()
    if (!selection || selection.isCollapsed || selection.rangeCount === 0) return null

    const range = selection.getRangeAt(0)

    const startInContainer = container.contains(range.startContainer)
    const endInContainer = container.contains(range.endContainer)

    // Skip if the selection doesn't touch this container at all.
    if (!startInContainer && !endInContainer && !range.intersectsNode(container)) return null

    const anchors = collectCharAnchors(container)

    // Clamp: if the start is outside the container, begin from the first char.
    const startIndex = startInContainer
      ? domStartToCharIndex(anchors, range.startContainer, range.startOffset)
      : 0

    // Clamp: if the end is outside the container, extend to the last char.
    const endIndex = endInContainer
      ? domEndToCharIndex(anchors, range.endContainer, range.endOffset)
      : anchors.length

    if (startIndex >= endIndex) return null

    return {
      selection,
      startIndex,
      endIndex,
      anchors,
    }
  }

  const getUpdatedHighlights = (startIndex: number, endIndex: number): HighlightRange[] => {
    const existing = (highlightedTexts.value ?? []).filter(
      (h) => h.startIndex >= 0 && h.endIndex > h.startIndex,
    )
    const carved = existing.flatMap((highlight) =>
      carveOutSelection(highlight, startIndex, endIndex),
    )

    if (isEraserActive.value) return mergeAdjacentSameColor(carved)

    return mergeAdjacentSameColor([
      ...carved,
      {
        startIndex,
        endIndex,
        colorClass: activeMenuItem.value.key,
      },
    ])
  }

  const applyFromCurrentSelection = async () => {
    if (!isActive.value) return

    const container = getContainer()
    if (!container) return

    const context = getSelectionContext(container)
    if (!context) return

    const updated = getUpdatedHighlights(context.startIndex, context.endIndex)

    try {
      await mutate({
        articleId: articleId.value,
        highlight: updated.length > 0 ? updated : null,
      })

      const selectedText = extractText(context.anchors, context.startIndex, context.endIndex)

      if (isEraserActive.value) {
        onHighlightApplied?.(i18n.t('Highlight removed from "%s"', selectedText))
      } else {
        onHighlightApplied?.(
          i18n.t('Color %s highlight applied to "%s"', activeMenuItem.value.label, selectedText),
        )
      }
    } finally {
      context.selection.removeAllRanges()
    }
  }

  const handlePointerUp = () => {
    void applyFromCurrentSelection()
  }

  let removeListener: (() => void) | null = null

  const attachListener = () => {
    if (removeListener) return

    document.addEventListener('pointerup', handlePointerUp)
    removeListener = () => document.removeEventListener('pointerup', handlePointerUp)
  }

  const detachListener = () => {
    removeListener?.()
    removeListener = null
  }

  watch(isActive, async (active) => {
    if (!active) {
      detachListener()
      return
    }

    attachListener()
    await nextTick()

    // Allows selecting first, then activating the tool from the top bar.
    void applyFromCurrentSelection()
  })

  onMounted(() => {
    if (isActive.value) attachListener()
  })

  onUnmounted(detachListener)
}
