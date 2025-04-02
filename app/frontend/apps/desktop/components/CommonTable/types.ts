// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { Props as CommonLinkProps } from '#shared/components/CommonLink/CommonLink.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type {
  EnumObjectManagerObjects,
  EnumOrderDirection,
} from '#shared/graphql/types.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import type { Awaitable } from '@vueuse/shared'

export const MINIMUM_COLUMN_WIDTH = 50
export const MINIMUM_TABLE_WIDTH = 600

type TableColumnType = 'timestamp' | 'timestamp_absolute' | 'link'

type TableHeaderPreference = {
  headerClass?: string
  labelClass?: string
  hideLabel?: boolean
  truncate?: boolean
  noResize?: boolean
  displayWidth?: number
  noSorting?: boolean
}

type TableColumnPreference = {
  /**
   * @default 'left'
   * */
  alignContent?: 'center' | 'right' | 'left'
}

export interface TableSimpleHeader<K = string>
  extends TableHeaderPreference,
    TableColumnPreference {
  key: K
  label: string
  labelPlaceholder?: string[]
  type?: TableColumnType
  columnSeparator?: boolean
  [key: string]: unknown
}

export type TableItemLinkValue = Partial<CommonLinkProps> & { label: string }

export interface TableItem {
  [key: string]: unknown | TableItemLinkValue
  id: ID | number
}

export interface TableAdvancedItem {
  [key: string]: unknown
  id: ID
  policy?: {
    update?: boolean
  }
}

interface BaseTableProps {
  actions?: MenuItem[]
  caption: string
  showCaption?: boolean
}

export interface SimpleTableProps extends BaseTableProps {
  items: TableItem[]
  headers: TableSimpleHeader[]
  onClickRow?: (tableItem: TableItem) => void
  /**
   * Used to set a default selected row
   * Is not used for checkbox
   * */
  selectedRowId?: string
  hasCheckboxColumn?: boolean
}

export interface CellContentProps {
  value?: string | number
  isRowSelected?: boolean
}

export interface TableAttribute {
  name: string
  label: string
  labelPlaceholder?: string[]
  headerPreferences?: TableHeaderPreference
  columnPreferences?: TableColumnPreference & {
    link?: Pick<CommonLinkProps, 'internal' | 'openInNewTab'> & {
      getLink: (
        item: TableAdvancedItem,
        tableAttribute: TableAttribute,
      ) => string
    }
  }
  dataType: ObjectAttribute['dataType']
  dataOption?: ObjectAttribute['dataOption']
}

export interface AdvancedTableProps extends BaseTableProps {
  items: TableAdvancedItem[]
  headers: string[]
  attributes?: TableAttribute[]
  attributeExtensions?: Record<string, Partial<TableAttribute>>
  object?: EnumObjectManagerObjects
  /**
   * Used to set a default selected row
   * Is not used for checkbox
   * */
  selectedRowId?: string
  hasCheckboxColumn?: boolean // TODO: rename this prop, related to bulk???

  totalItems: number
  maxItems?: number

  onClickRow?: (tableItem: TableAdvancedItem) => void

  reachedScrollTop?: boolean

  onLoadMore?: () => Awaitable<void>

  storageKeyId?: string

  scrollContainer?: HTMLElement | null

  groupBy?: string

  orderBy?: string
  orderDirection?: EnumOrderDirection

  isSorting?: boolean
}

export interface ListTableProps<T> {
  tableId: string
  headers: string[]
  orderDirection?: EnumOrderDirection
  orderBy?: string
  groupBy?: string
  caption: string
  reachedScrollTop?: boolean
  scrollContainer?: HTMLElement | null
  items: T[]
  totalCount: number
  maxItems: number
  resorting?: boolean
  loading: boolean
  loadingNewPage: boolean
  skeletonLoadingCount?: number
  onLoadMore?: () => Awaitable<void>
}

export interface ListTableEmits {
  sort: [string, EnumOrderDirection]
}
