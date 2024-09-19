// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { shallowRef, computed, ref, reactive } from 'vue'

import type {
  FormFieldValue,
  FormRef,
  FormSchemaField,
  FormValues,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { ChannelEmailInboundMailboxStats } from '#shared/graphql/types.ts'

import type {
  EmailInboundData,
  EmailInboundMetaInformation,
  EmailInboundMetaInformationNextAction,
} from '../types/email-inbound-outbound.ts'
import type { ShallowRef } from 'vue'

export const useEmailInboundForm = () => {
  const formEmailInbound: ShallowRef<FormRef | undefined> = shallowRef()

  const { values, updateFieldValues, formSetErrors, onChangedField } =
    useForm<EmailInboundData>(formEmailInbound)

  const metaInformationInbound = ref<Maybe<EmailInboundMetaInformation>>(null)

  const updateMetaInformationInbound = (
    data: ChannelEmailInboundMailboxStats,
    nextAction: EmailInboundMetaInformationNextAction,
  ) => {
    metaInformationInbound.value = {
      contentMessages: data.contentMessages || 0,
      archivePossible: !!data.archivePossible,
      archivePossibleIsFallback: !!data.archivePossibleIsFallback,
      archiveWeekRange: data.archiveWeekRange || 0,
      nextAction,
    }
  }

  const inboundSSLOptions = computed(() => {
    const options = [
      {
        value: 'off',
        label: __('No SSL'),
      },
      {
        value: 'ssl',
        label: __('SSL'),
      },
    ]

    if (values.value.adapter === 'imap') {
      options.push({
        value: 'starttls',
        label: __('STARTTLS'),
      })
    }

    return options
  })

  const emailInboundFormChangeFields = reactive<
    Record<string, Partial<FormSchemaField>>
  >({
    sslVerify: {},
    port: {},
  })

  onChangedField('ssl', (newValue: FormFieldValue) => {
    const disabled = Boolean(newValue === 'off')
    emailInboundFormChangeFields.sslVerify = {
      disabled,
    }

    const newValues: FormValues = {
      sslVerify: !disabled,
    }

    if (newValue === 'off') {
      newValues.port = 143
    } else if (newValue === 'ssl') {
      newValues.port = 993
    }

    updateFieldValues(newValues)
  })

  const emailInboundSchema = [
    {
      isLayout: true,
      element: 'div',
      attrs: {
        class: 'grid grid-cols-2 gap-y-2.5 gap-x-3',
      },
      children: [
        {
          type: 'group',
          name: 'inbound',
          isGroupOrList: true,
          children: [
            {
              name: 'adapter',
              label: __('Type'),
              type: 'select',
              outerClass: 'col-span-2',
              required: true,
            },
            {
              name: 'host',
              label: __('Host'),
              type: 'text',
              outerClass: 'col-span-2',
              props: {
                maxLength: 120,
              },
              required: true,
            },
            {
              name: 'user',
              label: __('User'),
              type: 'text',
              outerClass: 'col-span-2',
              props: {
                maxLength: 120,
              },
              required: true,
            },
            {
              name: 'password',
              label: __('Password'),
              type: 'password',
              outerClass: 'col-span-2',
              props: {
                maxLength: 120,
              },
              required: true,
            },
            {
              name: 'ssl',
              label: __('SSL/STARTTLS'),
              type: 'select',
              outerClass: 'col-span-1',
              value: 'ssl',
              options: inboundSSLOptions,
            },
            {
              name: 'sslVerify',
              label: __('SSL verification'),
              type: 'toggle',
              outerClass: 'col-span-1',
              wrapperClass: 'mt-6',
              value: true,
              props: {
                variants: {
                  true: 'yes',
                  false: 'no',
                },
              },
            },
            {
              name: 'port',
              label: __('Port'),
              type: 'text',
              outerClass: 'col-span-1',
              validation: 'number',
              props: {
                maxLength: 6,
              },
              value: 993,
              required: true,
            },
            {
              if: '$values.adapter === "imap"',
              name: 'folder',
              label: __('Folder'),
              type: 'text',
              outerClass: 'col-span-1',
              props: {
                maxLength: 120,
              },
            },
            {
              if: '$values.adapter === "imap"',
              name: 'keepOnServer',
              label: __('Keep messages on server'),
              type: 'toggle',
              outerClass: 'col-span-2',
              value: false,
              props: {
                variants: {
                  true: 'yes',
                  false: 'no',
                },
              },
            },
          ],
        },
      ],
    },
  ]

  return {
    formEmailInbound,
    emailInboundSchema,
    formEmailInboundValues: values,
    updateEmailInboundFieldValues: updateFieldValues,
    formEmailInboundSetErrors: formSetErrors,
    metaInformationInbound,
    emailInboundFormChangeFields,
    updateMetaInformationInbound,
  }
}
