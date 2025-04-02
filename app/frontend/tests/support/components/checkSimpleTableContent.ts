// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import type { ExtendedRenderResult } from '#tests/support/components/renderComponent.ts'

export const checkSimpleTableHeader = (
  view: ExtendedRenderResult,
  tableHeaders: string[],
  tableLabel?: string,
) => {
  const table = within(view.getByRole('table', { name: tableLabel }))

  tableHeaders.forEach((header) => {
    expect(
      table.getByRole('columnheader', { name: header }),
    ).toBeInTheDocument()
  })
}

export const checkSimpleTableContent = (
  view: ExtendedRenderResult,
  rowContents: (string | string[])[][],
  tableLabel?: string,
) => {
  const table = within(view.getByRole('table', { name: tableLabel }))

  const rows = table.getAllByRole('row')

  expect(rows).toHaveLength(rowContents.length + 1) // +1 for header row

  rows.forEach((row, index) => {
    const cells = within(row).queryAllByRole('cell')

    if (!cells.length)
      cells.forEach((cell, cellIndex) => {
        if (!cell) return
        const content = rowContents[index][cellIndex]
        if (content) {
          const withinCell = within(cell)

          if (Array.isArray(content)) {
            const dateTime = withinCell.getByLabelText(content[0])
            expect(dateTime).toHaveTextContent(content[1])
          } else {
            expect(withinCell.getByText(content)).toBeInTheDocument()
          }
        }
      })
  })
}
