// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import KnowledgeBaseAnswerListSkeleton from '../KnowledgeBaseAnswerListSkeleton.vue'

// Counted in this render's own container: rendered components are not cleaned up between the
//   examples of a file, so a document-wide query would also count the rows of the ones before it.
const renderSkeleton = (props: { count?: number; pageSize?: number } = {}) =>
  renderComponent(KnowledgeBaseAnswerListSkeleton, { props }).container.querySelectorAll('li')
    .length

describe('KnowledgeBaseAnswerListSkeleton', () => {
  it('lays out a row per answer that is on its way', () => {
    expect(renderSkeleton({ count: 5 })).toBe(5)
  })

  it('lays out a guess while the number of answers is unknown', () => {
    expect(renderSkeleton()).toBeGreaterThan(0)
  })

  // A count of none means nothing is known yet, not that nothing is coming: laying a zero out as
  //   zero rows is what left the answers area empty for as long as the fetch took.
  it('lays out the same guess for a count of none', () => {
    expect(renderSkeleton({ count: 0 })).toBeGreaterThan(0)
  })

  // A first load asks for one page, so a category of hundreds must not lay out hundreds of rows.
  it('lays out no more rows than one page brings', () => {
    expect(renderSkeleton({ count: 250, pageSize: 30 })).toBe(30)
  })

  it('lays out the count itself when it fits in a page', () => {
    expect(renderSkeleton({ count: 4, pageSize: 30 })).toBe(4)
  })
})
