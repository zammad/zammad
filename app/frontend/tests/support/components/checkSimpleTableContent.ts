// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

  expect(rows).toHaveLength(rowContents.length)

  rows.forEach((row, index) => {
    within(row)
      .getAllByRole('cell')
      .forEach((cell, cellIndex) => {
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
