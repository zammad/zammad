// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef, FormFieldValue } from '#shared/components/Form/types.ts'
import type { MutationSendError } from '#shared/types/error.ts'

import type { EmailAccountData } from './email-account.ts'
import type {
  EmailInboundData,
  EmailInboundMessagesData,
  EmailOutboundData,
} from './email-inbound-outbound.ts'
import type { ShallowRef, Ref } from 'vue'

export type EmailChannelSteps =
  | 'account'
  | 'inbound'
  | 'inbound-messages'
  | 'outbound'

export interface EmailChannelForm<T> {
  form: ShallowRef<FormRef | undefined>
  updateFieldValues: (fieldValues: Record<string, FormFieldValue>) => void
  setErrors: (errors: MutationSendError) => void
  values: Ref<T>
}

export interface EmailChannelForms {
  emailAccount: EmailChannelForm<EmailAccountData>
  emailInbound: EmailChannelForm<EmailInboundData>
  emailInboundMessages: Pick<EmailChannelForm<EmailInboundMessagesData>, 'form'>
  emailOutbound: EmailChannelForm<EmailOutboundData>
}

export type ValidateConfigurationRoundtripAndChannelAddFunction = (
  account: EmailAccountData,
  inboundConfiguration: EmailInboundData,
  outboundConfiguration: EmailOutboundData,
) => Promise<void>
