<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import { useImportSource } from '../../../composables/useImportSource.ts'
import { useImportSourceConfiguration } from '../../../composables/useImportSourceConfiguration.ts'

import type { ImportSourceConfigurationFreshdeskData } from '../../../types/setup-import.ts'

const { form } = useImportSource()

const formSchema = [
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'grid grid-cols-1 gap-y-2.5 gap-x-3',
    },
    children: [
      {
        label: 'URL',
        name: 'url',
        type: 'text',
        required: true,
        validation: 'url',
        help: i18n.t('Enter the URL of your %s system.', 'Freshdesk'),

        // TODO: :)
        // sectionsSchema: {
        //   prefix: {
        //     $el: 'span',
        //     children: 'https://',
        //     attrs: {
        //       class:
        //         'py-2.5 px-2.5 outline outline-1 -outline-offset-1 outline-blue-200 dark:outline-gray-700 bg-white dark:bg-gray-500 rounded-s-md text-stone-200 dark:text-neutral-500',
        //       readonly: 'readonly',
        //     },
        //   },
        //   suffix: {
        //     $el: 'span',
        //     children: '.freshdesk.com',
        //     attrs: {
        //       class:
        //         'py-2.5 px-2.5 outline outline-1 -outline-offset-1 outline-blue-200 dark:outline-gray-700 bg-white dark:bg-gray-500 rounded-e-md text-stone-200 dark:text-neutral-500',
        //       readonly: 'readonly',
        //     },
        //   },
        // },
      },
      {
        label: __('API token'),
        name: 'secret',
        type: 'text',
        placeholder: 'XYZ3133723421111',
        required: true,
        sectionsSchema: {
          help: {
            children: [
              '$help',
              {
                $cmp: 'CommonLink',
                props: {
                  link: 'https://support.freshdesk.com/support/solutions/articles/215517-how-to-find-your-api-key',
                  external: true,
                  openInNewTab: true,
                  class: 'ltr:ml-1 rtl:mr-1',
                },
                children: __('More information can be found here.'),
              },
            ],
          },
        },
        help: __(
          'Enter your Freshdesk API token gained from your account profile settings.',
        ),
      },
    ],
  },
]

const { configureSystemImportSource } = useImportSourceConfiguration(
  EnumSystemImportSource.Freshdesk,
)
</script>

<template>
  <div class="flex flex-col gap-y-2.5">
    <CommonAlert variant="info">
      {{
        $t(
          'After the import is completed, the account associated with the API token will become your username, and the token itself will be your password.',
        )
      }}
    </CommonAlert>
    <Form
      id="import-freshdesk-configuration"
      ref="form"
      form-class="mb-2.5"
      :schema="formSchema"
      @submit="
        configureSystemImportSource(
          $event as FormSubmitData<ImportSourceConfigurationFreshdeskData>,
        )
      "
    />
  </div>
</template>
