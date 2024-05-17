<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import { useImportSource } from '../../../composables/useImportSource.ts'
import { useImportSourceConfiguration } from '../../../composables/useImportSourceConfiguration.ts'

import type { ImportSourceConfigurationZendeskData } from '../../../types/setup-import.ts'

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
        help: i18n.t('Enter the URL of your %s system.', 'Zendesk'),
      },
      {
        name: 'username',
        label: __('Email'),
        type: 'email',
        validation: 'email',
        placeholder: 'admin@example.com',
        props: {
          maxLength: 150,
        },
        required: true,
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
                  link: 'https://support.zendesk.com/hc/en-us/articles/4408889192858-Managing-access-to-the-Zendesk-API#topic_tcb_fk1_2yb',
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
          'Enter your Zendesk API token gained from your admin interface.',
        ),
      },
    ],
  },
]

const { configureSystemImportSource } = useImportSourceConfiguration(
  EnumSystemImportSource.Zendesk,
)
</script>

<template>
  <div class="flex flex-col gap-y-2.5">
    <CommonAlert variant="info">
      {{
        $t(
          'The entered email and API token will become your Zammad login credentials after the import is completed.',
        )
      }}
    </CommonAlert>
    <Form
      id="import-zendesk-configuration"
      ref="form"
      form-class="mb-2.5"
      :schema="formSchema"
      @submit="
        configureSystemImportSource(
          $event as FormSubmitData<ImportSourceConfigurationZendeskData>,
        )
      "
    />
  </div>
</template>
