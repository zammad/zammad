// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { CATEGORY_GRID_MAX_COLUMNS } from '../../../utils/knowledgeBaseCategoryGrid.ts'
import KnowledgeBaseCategoryCardSkeleton from '../KnowledgeBaseCategoryCardSkeleton.vue'

// Counted in this render's own container: rendered components are not cleaned up between the
//   examples of a file, so a document-wide query would also count the tiles of the ones before it.
const renderSkeleton = (count?: number) =>
  renderComponent(KnowledgeBaseCategoryCardSkeleton, {
    props: { count },
  }).container.querySelectorAll('li').length

describe('KnowledgeBaseCategoryCardSkeleton', () => {
  it('lays out a tile per subcategory that is on its way', () => {
    expect(renderSkeleton(2)).toBe(2)
  })

  // A known count is rendered in full and wraps exactly like the real cards will - so a bigger
  //   category grows the skeleton to the same rows the loaded grid ends up with, rather than
  //   popping from a capped placeholder row to a taller grid once it arrives.
  it('lays out every tile of a known count, even past the widest grid column count', () => {
    expect(renderSkeleton(12)).toBe(12)
  })

  // Unknown count (no prop) reserves one row at most: a tile is hidden by the breakpoint
  //   `CATEGORY_GRID_REVEAL` has for it, and past the last column count there is none - so
  //   guessing more than a row would risk showing rows the grid does not have at that width.
  it('reserves one row at most for an unknown count', () => {
    expect(renderSkeleton()).toBe(CATEGORY_GRID_MAX_COLUMNS)
  })
})
