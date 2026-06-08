// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, onMounted, onUnmounted, watch, type ComputedRef, type Ref } from 'vue'

import { useReactivate } from '#shared/composables/useReactivate.ts'
import type { TicketArticleHighlightedText } from '#shared/graphql/types.ts'

import { useHighlightsRegistry } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useArticleHighlights/useHighlightsRegistry.ts'

import { collectCharAnchors } from './utils.ts'

import type { CharAnchor } from './types'

/**
 * Build `Range` objects covering the character interval [startIndex, endIndex)
 * in the element's text content. A single logical selection may span multiple
 * adjacent text nodes (e.g. across inline HTML tags), yielding more than one range.
 */
const buildRangesForInterval = (root: Element, startIndex: number, endIndex: number): Range[] => {
  if (startIndex >= endIndex) return []

  const anchors = collectCharAnchors(root)
  const start = Math.max(0, startIndex)
  const end = Math.min(endIndex, anchors.length)

  const ranges: Range[] = []
  let segStart: CharAnchor | null = null
  let segEnd: CharAnchor | null = null

  const flush = () => {
    if (segStart && segEnd) {
      const range = new Range()
      range.setStart(segStart.node, segStart.charIndex)
      range.setEnd(segEnd.node, segEnd.charIndex + 1) // setEnd offset is exclusive
      ranges.push(range)
    }
    segStart = null
    segEnd = null
  }

  anchors.slice(start, end).forEach((anchor) => {
    if (anchor === null) {
      // Virtual char (br / block boundary) - close the current segment.
      flush()
      return
    }

    if (segStart === null) {
      segStart = anchor
    } else if (segEnd !== null && anchor.node !== segEnd.node) {
      // Crossed a text-node boundary - flush and start a fresh segment.
      flush()
      segStart = anchor
    }

    segEnd = anchor
  })

  flush()
  return ranges
}

/**
 * Apply CSS Custom Highlight API highlights for a single article bubble.
 */
export const useArticleHighlights = (
  bubbleBodyElement: Ref<HTMLElement | undefined>,
  highlightedTexts: ComputedRef<TicketArticleHighlightedText[] | undefined>,
  bodyContent: ComputedRef<string>,
) => {
  const { removeHighlightFromRegistry, getOrCreateHighlight } = useHighlightsRegistry()

  // Track ranges owned by this instance so we can remove on cleanup
  let ownedRanges: Array<{ colorClass: string; range: Range }> = []

  const clearHighlights = () => {
    ownedRanges.forEach(({ colorClass, range }) => removeHighlightFromRegistry(colorClass, range))
    ownedRanges = []
  }

  const applyHighlights = () => {
    clearHighlights()

    const container =
      bubbleBodyElement.value?.querySelector<HTMLElement>('.inner-article-body') ??
      bubbleBodyElement.value
    const texts = highlightedTexts.value

    if (!container || !texts?.length || !('highlights' in CSS)) return

    ownedRanges = texts.flatMap(({ startIndex, endIndex, colorClass }) => {
      const highlight = getOrCreateHighlight(colorClass)

      if (!highlight) return []

      return buildRangesForInterval(container, startIndex, endIndex).map((range) => {
        highlight.add(range)
        return { colorClass, range }
      })
    })
  }

  // When switching back to a cached taskbar tab, KeepAlive reactivates the
  // component without remounting it. Range objects reference detached DOM nodes
  // while deactivated, so we clear them on deactivate and rebuild on reactivate.
  // useReactivate skips the first onActivated call (which fires right after
  // onMounted inside KeepAlive) to avoid double-applying on initial load.
  useReactivate(() => nextTick(applyHighlights), clearHighlights)

  // Reapply whenever the highlight data or the rendered body HTML changes.
  // nextTick ensures the DOM has been updated before we walk text nodes.
  watch(
    [bubbleBodyElement, highlightedTexts, bodyContent],
    () => {
      applyHighlights()
    },
    { flush: 'post' },
  )

  onMounted(applyHighlights)
  onUnmounted(clearHighlights)
}
