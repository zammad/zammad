// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import type { FormFieldValue } from '#shared/components/Form/types.ts'
import type {
  TicketQuery,
  TicketArticlesQuery,
  TicketLiveUser,
  EnumTaskbarApp,
  EnumSecurityOption,
} from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export enum TicketState {
  Closed = 'closed',
  WaitingForClosure = 'pending close',
  WaitingForReminder = 'pending reminder',
  Open = 'open',
  New = 'new',
}

export enum TicketCreateArticleType {
  PhoneIn = 'phone-in',
  PhoneOut = 'phone-out',
  EmailOut = 'email-out',
}

export type TicketView = 'agent' | 'customer'

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
  attachments?: FileUploaded[]
  group_id: number
  owner_id?: number
  state_id?: number
  pending_time?: string
  priority_id?: number
  articleSenderType: TicketCreateArticleType
  tags: string[]
  security?: EnumSecurityOption[]
  [index: string]: FormFieldValue
}

export type TicketDuplicateDetectionItem = [
  id: number,
  number: string,
  title: string,
]
