// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  Scalars,
  EnumChannelEmailInboundAdapter,
  EnumChannelEmailOutboundAdapter,
  EnumChannelEmailSsl,
  ChannelEmailInboundMailboxStats,
} from '#shared/graphql/types.ts'

interface EmailBaseConfigurationData {
  host?: string
  user?: string
  password?: string
  port?: number
  sslVerify?: boolean
}

export interface EmailBaseOutboundData extends EmailBaseConfigurationData {
  adapter: EnumChannelEmailOutboundAdapter
}

export interface EmailOutboundSendmailFormData extends EmailBaseOutboundData {
  adapter: EnumChannelEmailOutboundAdapter.Sendmail
}

export interface EmailOutboundSmtpFormData
  extends Required<EmailBaseOutboundData> {
  adapter: EnumChannelEmailOutboundAdapter.Smtp
}

export type EmailOutboundData =
  | EmailOutboundSendmailFormData
  | EmailOutboundSmtpFormData

export interface EmailInboundMessagesData {
  archive?: boolean
  archiveBefore?: Scalars['ISO8601DateTime']['output']
}

export interface EmailInboundData
  extends Required<EmailBaseConfigurationData>,
    EmailInboundMessagesData {
  adapter: EnumChannelEmailInboundAdapter
  ssl: EnumChannelEmailSsl
  folder?: string
  keepOnServer?: boolean
}

export type EmailInboundMetaInformationNextAction = 'roundtrip' | 'outbound'

export interface EmailInboundMetaInformation {
  contentMessages: number
  archivePossible?: boolean
  archivePossibleIsFallback?: boolean
  archiveWeekRange?: number
  nextAction: EmailInboundMetaInformationNextAction
  archive?: boolean
  archiveBefore?: Scalars['ISO8601DateTime']['output']
}

export type UpdateMetaInformationInboundFunction = (
  data: ChannelEmailInboundMailboxStats,
  nextAction: EmailInboundMetaInformationNextAction,
) => void
