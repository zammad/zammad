// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue } from '@shared/components/Form/types'
import type {
  TicketQuery,
  TicketArticlesQuery,
  UploadFileInput,
  TicketLiveUser,
  EnumTaskbarApp,
} from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'

export enum TicketState {
  Closed = 'closed',
  WaitingForClosure = 'waiting-for-closure',
  WaitingForReminder = 'waiting-for-reminder',
  Open = 'open',
  Escalated = 'escalated',
  New = 'new',
}

export enum TicketCreateArticleType {
  PhoneIn = 'phone-in',
  PhoneOut = 'phone-out',
  EmailOut = 'email-out',
}

export interface TicketLiveAppUser {
  user: TicketLiveUser['user']
  editing: boolean
  lastInteraction: string
  app: EnumTaskbarApp
}

export type TicketById = TicketQuery['ticket']
export type TicketArticle = ConfidentTake<
  TicketArticlesQuery,
  'articles.edges.node'
>

export type TicketArticleAttachment =
  TicketArticle['attachmentsWithoutInline'][number]

export interface TicketCustomerUpdateFormData {
  customer_id: number
  organization_id?: number
}

export interface TicketFormData {
  title: string
  customer_id?: number
  cc?: string[]
  body: string
  attachments?: UploadFileInput[]
  group_id: number
  owner_id?: number
  state_id?: number
  pending_time?: string
  priority_id?: number
  articleSenderType: TicketCreateArticleType
  tags: string[]
  [index: string]: FormFieldValue
}
