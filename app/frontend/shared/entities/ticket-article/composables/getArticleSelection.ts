// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// import { textToHtml } from '@shared/utils/helpers'
import { getCurrentSelectionData } from '@shared/utils/selection'

const closest = (node: Node, selector: string) => {
  while (node.parentNode) {
    if ('matches' in node && (node as Element).matches(selector)) return node
    node = node.parentNode
  }
  return null
}

const isInsideSelectionBoundary = (node: Element, articleId: number) => {
  // node can be textNode, it doesn't have "closest" method
  return !!closest(node, `#article-${articleId} .Content`)
}

const containsNode = (selection: Selection, node: Element) => {
  return !!selection.containsNode(node, false)
}

export const getArticleSelection = (articleId: number) => {
  const selection = window.getSelection()
  if (!selection || selection.rangeCount <= 0) return undefined
  const range = selection.getRangeAt(0)
  const articleContent = document.querySelector(
    `#article-${articleId} .Content`,
  ) as HTMLDivElement | null
  if (!articleContent) return undefined
  const startInsideArticle = isInsideSelectionBoundary(
    range.startContainer as Element,
    articleId,
  )
  const endInsideArticle = isInsideSelectionBoundary(
    range.endContainer as Element,
    articleId,
  )
  const contains = containsNode(selection, articleContent)
  const canQuote = startInsideArticle || endInsideArticle || contains

  if (!canQuote) return undefined

  // Fixes Issue #3539 - When replying quote article content only
  if (!startInsideArticle && endInsideArticle) {
    range.setStart(articleContent, 0)
  } else if (startInsideArticle && !endInsideArticle) {
    range.setEnd(articleContent, articleContent.childNodes.length)
  } else if (contains) {
    range.setStart(articleContent, 0)
    range.setEnd(articleContent, articleContent.childNodes.length)
  }

  return getCurrentSelectionData()
}
