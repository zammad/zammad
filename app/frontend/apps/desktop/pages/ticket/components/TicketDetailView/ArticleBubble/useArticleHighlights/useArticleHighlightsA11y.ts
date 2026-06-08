// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onMounted, ref, watch, type ComputedRef, type Ref } from 'vue'

import type { TicketArticleHighlightedText } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import { collectCharAnchors, extractText } from './utils.ts'

const colorLabels: Record<string, string> = {
  'highlight-yellow': __('Yellow'),
  'highlight-green': __('Green'),
  'highlight-blue': __('Blue'),
  'highlight-pink': __('Pink'),
  'highlight-purple': __('Purple'),
}

/**
 * Provides an accessible text description of the article's highlighted segments,
 * grouped by color. Intended to be referenced via `aria-details` on the article
 * body element, since the CSS Custom Highlight API produces no accessible markup.
 */
export const useArticleHighlightsA11y = (
  bubbleBodyElement: Ref<HTMLElement | undefined>,
  highlightedTexts: ComputedRef<TicketArticleHighlightedText[] | undefined>,
  bodyContent: ComputedRef<string>,
  /**
   * Internal article ID
   */
  articleId: ComputedRef<number>,
) => {
  const description = ref('')

  const descriptionId = computed(() =>
    description.value ? `article-highlight-description-${articleId.value}` : undefined,
  )

  const updateDescription = () => {
    const highlights = highlightedTexts.value

    if (!highlights?.length) {
      description.value = ''
      return
    }

    const container =
      bubbleBodyElement.value?.querySelector<HTMLElement>('.inner-article-body') ??
      bubbleBodyElement.value

    if (!container) {
      description.value = ''
      return
    }

    const anchors = collectCharAnchors(container)
    const sorted = [...highlights].sort((a, b) => a.startIndex - b.startIndex)

    // Group highlighted texts by color, preserving first-appearance order.
    const groupedByColor = sorted.reduce((acc, { startIndex, endIndex, colorClass }) => {
      const text = extractText(anchors, startIndex, endIndex)
      if (!text) return acc
      if (!acc.has(colorClass)) acc.set(colorClass, [])

      acc.get(colorClass)!.push(text)

      return acc
    }, new Map<string, string[]>())

    if (groupedByColor.size === 0) {
      description.value = ''
      return
    }

    const parts = [...groupedByColor.entries()].map(([colorClass, texts]) => {
      const colorLabel = colorLabels[colorClass] ?? colorClass
      const quotedTexts = texts.map((t) => `"${t}"`).join(', ')

      return `${i18n.t(colorLabel)}: ${quotedTexts}`
    })

    description.value = `${i18n.t('Highlighted text')}: ${parts.join('. ')}.`
  }

  watch([bubbleBodyElement, highlightedTexts, bodyContent], updateDescription, { flush: 'post' })

  onMounted(updateDescription)

  return { descriptionId, description }
}
