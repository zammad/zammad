<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import { useImportSource } from '../../../composables/useImportSource.ts'
import { useImportSourceConfiguration } from '../../../composables/useImportSourceConfiguration.ts'

import type { ImportSourceConfigurationKayakoData } from '../../../types/setup-import.ts'

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
        help: i18n.t('Enter the URL of your %s system.', 'Kayako'),
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
        help: __(
          'Enter your email address from your Kayako account which should be used for the import.',
        ),
      },
      {
        label: __('Password'),
        name: 'secret',
        type: 'password',
        required: true,
        help: __(
          'Enter your password from your Kayako account which should be used for the import.',
        ),
      },
    ],
  },
]

const { configureSystemImportSource } = useImportSourceConfiguration(
  EnumSystemImportSource.Kayako,
)
</script>

<template>
  <div class="flex flex-col gap-y-2.5">
    <CommonAlert variant="info">
      {{
        $t(
          'The entered email and password will become your Zammad login credentials after the import is completed.',
        )
      }}
    </CommonAlert>
    <Form
      id="import-kayako-configuration"
      ref="form"
      form-class="mb-2.5"
      :schema="formSchema"
      @submit="
        configureSystemImportSource(
          $event as FormSubmitData<ImportSourceConfigurationKayakoData>,
        )
      "
    />
  </div>
</template>
