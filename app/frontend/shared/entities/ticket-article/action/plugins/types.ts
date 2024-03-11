// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSubmitData } from '#shared/components/Form/types.ts'
import type {
  EditorContentType,
  FieldEditorContext,
  FieldEditorProps,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import type { getTicketView } from '#shared/entities/ticket/utils/getTicketView.ts'
import type { AppName } from '#shared/types/app.ts'
import type { ConfigList } from '#shared/types/store.ts'
import type { SelectionData } from '#shared/utils/selection.ts'
import type { SecurityValue } from '#shared/components/Form/fields/FieldSecurity/types.ts'
import type { MaybeRecord } from '#shared/types/utils.ts'
import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'

export interface TicketArticleSelectionOptions {
  body: FieldEditorContext
}

export interface TicketArticleFormValues {
  articleType?: string
  body?: string
  internal?: boolean
  cc?: string[]
  subtype?: string
  inReplyTo?: string
  to?: string[]
  subject?: string
  attachments?: FileUploaded[]
  contentType?: string
  security?: SecurityValue
}

export interface TicketArticlePerformOptions {
  selection?: SelectionData
  formId: string

  openReplyDialog(values?: MaybeRecord<TicketArticleFormValues>): Promise<void>

  getNewArticleBody(type: EditorContentType): string
}

export interface CommonTicketAddOptions {
  view: ReturnType<typeof getTicketView>
  config: ConfigList
}

export interface TicketActionAddOptions extends CommonTicketAddOptions {
  recalculate(): void

  onDispose(callback: () => unknown): void
}

export type TicketTypeAddOptions = CommonTicketAddOptions

export type TicketViewPolicy = 'change' | 'read'
export type TicketViewPolicyMap = {
  agent?: TicketViewPolicy[]
  customer?: TicketViewPolicy[]
}

export interface TicketArticleAction {
  apps: AppName[]
  label: string // "name" in desktop view
  name: string // "type" in desktop view, but clashes with ArticleType
  icon: string
  view: TicketViewPolicyMap
  link?: string // do we need it(?)

  perform?(
    ticket: TicketById,
    article: TicketArticle,
    options: TicketArticlePerformOptions,
  ): void
}

export interface AppSpecificTicketArticleType {
  value: string
  icon: string
  label: string
  attributes: string[]
  internal: boolean
  view: TicketViewPolicyMap
  validation?: Record<
    string,
    string | Array<[rule: string, ...args: unknown[]]>
  >
  options?: Record<string, unknown>
  contentType?: FieldEditorProps['contentType']
  editorMeta?: FieldEditorProps['meta']

  // when clicked on type, and type is not selected, or when dialog is opened with this type
  onOpened?(ticket: TicketById, options: TicketArticleSelectionOptions): void

  onSelected?(ticket: TicketById, options: TicketArticleSelectionOptions): void

  // when clicked on other type, but this one is selected
  onDeselected?(
    ticket: TicketById,
    options: TicketArticleSelectionOptions,
  ): void

  // TODO use actual type instead of FormValues
  updateForm?(formValues: FormSubmitData): FormSubmitData
}

export interface TicketArticleType
  extends Omit<AppSpecificTicketArticleType, 'icon'> {
  apps: AppName[]
  icon: string
}

// inspired by tiptap plugins config
export interface TicketArticleActionPlugin {
  order: number

  addActions?(
    ticket: TicketById,
    article: TicketArticle,
    options: TicketActionAddOptions,
  ): TicketArticleAction[]

  addTypes?(
    ticket: TicketById,
    options: TicketTypeAddOptions,
  ): TicketArticleType[]
}
