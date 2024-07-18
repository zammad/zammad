// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type { FormFieldAdditionalProps } from '#shared/components/Form/types.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { TicketCreateArticleType } from '../types.ts'

export const ticketCreateArticleType = {
  [TicketCreateArticleType.PhoneIn]: {
    icon: 'phone-in',
    label: __('Received Call'),
    title: __('Received Call: %s'),
    sender: 'Customer',
    type: 'phone',
  },
  [TicketCreateArticleType.PhoneOut]: {
    icon: 'phone-out',
    label: __('Outbound Call'),
    title: __('Outbound Call: %s'),
    sender: 'Agent',
    type: 'phone',
  },
  [TicketCreateArticleType.EmailOut]: {
    icon: 'mail-out',
    label: __('Send Email'),
    title: __('Send Email: %s'),
    sender: 'Agent',
    type: 'email',
  },
}

export const useTicketCreateArticleType = (
  additionalProps: FormFieldAdditionalProps = {},
) => {
  const application = useApplicationStore()

  const availableTypes = computed(() => {
    let configuredAvailableTypes =
      (application.config.ui_ticket_create_available_types as
        | TicketCreateArticleType[]
        | TicketCreateArticleType) || []

    if (!Array.isArray(configuredAvailableTypes)) {
      configuredAvailableTypes = [configuredAvailableTypes]
    }

    return configuredAvailableTypes
  })

  const options = computed(() => {
    return availableTypes.value.map((availableType) => ({
      label: ticketCreateArticleType[availableType].label,
      value: availableType,
      icon: ticketCreateArticleType[availableType].icon,
    }))
  })

  const defaultTicketCreateArticleType = application.config
    .ui_ticket_create_default_type as TicketCreateArticleType

  const ticketArticleSenderTypeField = {
    name: 'articleSenderType',
    type: useAppName() === 'mobile' ? 'radio' : 'toggleButtons',
    required: true,
    value: availableTypes.value.includes(defaultTicketCreateArticleType)
      ? defaultTicketCreateArticleType
      : availableTypes.value[0],
    props: {
      options,
      ...additionalProps,
    },
  }

  return {
    ticketCreateArticleType,
    ticketArticleSenderTypeField,
    defaultTicketCreateArticleType,
  }
}
