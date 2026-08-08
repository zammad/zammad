<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import { useImportSource } from '../../../composables/useImportSource.ts'
import { useImportSourceConfiguration } from '../../../composables/useImportSourceConfiguration.ts'

import type { ImportSourceConfigurationJiraData } from '../../../types/setup-import.ts'

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
        placeholder: 'https://your-domain.atlassian.net',
        help: i18n.t('Enter the URL of your %s Cloud site.', 'Jira'),
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
        help: __('Enter the email address of the Jira account used for the import.'),
      },
      {
        label: __('API token'),
        name: 'secret',
        type: 'text',
        required: true,
        sectionsSchema: {
          help: {
            children: [
              '$help',
              {
                $cmp: 'CommonLink',
                props: {
                  link: 'https://id.atlassian.com/manage-profile/security/api-tokens',
                  external: true,
                  openInNewTab: true,
                  class: 'ltr:ml-1 rtl:mr-1',
                },
                children: __('More information can be found here.'),
              },
            ],
          },
        },
        help: __('Enter an API token created for the Jira account above.'),
      },
      {
        label: __('Project key'),
        name: 'projectKey',
        type: 'text',
        required: true,
        placeholder: 'LS',
        help: __('Enter the key of the Jira project whose issues should be imported.'),
      },
    ],
  },
]

const { configureSystemImportSource } = useImportSourceConfiguration(EnumSystemImportSource.Jira)
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
      id="import-jira-configuration"
      ref="form"
      form-class="mb-2.5"
      :schema="formSchema"
      @submit="
        configureSystemImportSource($event as FormSubmitData<ImportSourceConfigurationJiraData>)
      "
    />
  </div>
</template>
