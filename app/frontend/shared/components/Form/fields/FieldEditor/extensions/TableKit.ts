// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { TableRow, TableHeader, TableCell, type TableKitOptions } from '@tiptap/extension-table'

export const TableKitExtensionName = 'tableKit'
import { Table } from './TableKit/Table.ts'

export const TableKit = Extension.create<TableKitOptions>({
  name: TableKitExtensionName,

  addExtensions() {
    const extensions = []

    if (this.options.table !== false) {
      extensions.push(Table.configure(this.options.table))
    }

    if (this.options.tableCell !== false) {
      extensions.push(TableCell.configure(this.options.tableCell))
    }

    if (this.options.tableHeader !== false) {
      extensions.push(TableHeader.configure(this.options.tableHeader))
    }

    if (this.options.tableRow !== false) {
      extensions.push(TableRow.configure(this.options.tableRow))
    }

    return extensions
  },
})
