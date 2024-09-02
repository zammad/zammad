// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { shallowRef, reactive } from 'vue'

import type { FormRef, FormSchemaField } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'

import type { EmailOutboundData } from '../types/email-inbound-outbound.ts'
import type { ShallowRef } from 'vue'

export const useEmailOutboundForm = () => {
  const formEmailOutbound: ShallowRef<FormRef | undefined> = shallowRef()

  const { updateFieldValues, values, formSetErrors, onChangedField } =
    useForm<EmailOutboundData>(formEmailOutbound)

  const emailOutboundFormChangeFields = reactive<
    Record<string, Partial<FormSchemaField>>
  >({
    sslVerify: {},
  })

  onChangedField('port', (newValue) => {
    const disabled = Boolean(
      newValue && !(newValue === '465' || newValue === '587'),
    )

    emailOutboundFormChangeFields.sslVerify = {
      disabled,
    }

    updateFieldValues({
      sslVerify: !disabled,
    })
  })

  const emailOutboundSchema = [
    {
      isLayout: true,
      element: 'div',
      attrs: {
        class: 'grid grid-cols-2 gap-y-2.5 gap-x-3',
      },
      children: [
        {
          type: 'group',
          name: 'outbound',
          isGroupOrList: true,
          children: [
            {
              name: 'adapter',
              label: __('Send mails via'),
              type: 'select',
              outerClass: 'col-span-2',
              required: true,
            },
            {
              if: '$values.adapter === "smtp"',
              isLayout: true,
              element: 'div',
              attrs: {
                class: 'grid grid-cols-2 gap-y-2.5 gap-x-3 col-span-2',
              },
              children: [
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
                  name: 'port',
                  label: __('Port'),
                  type: 'text',
                  outerClass: 'col-span-1',
                  validation: 'number',
                  props: {
                    maxLength: 6,
                  },
                  required: true,
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
              ],
            },
          ],
        },
      ],
    },
  ]

  return {
    formEmailOutbound,
    emailOutboundSchema,
    emailOutboundFormChangeFields,
    updateEmailOutboundFieldValues: updateFieldValues,
    formEmailOutboundSetErrors: formSetErrors,
    formEmailOutboundValues: values,
  }
}
