<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, reactive } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type {
  FormFieldValue,
  FormSchemaField,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import { useSSLVerificationWarningHandler } from '#desktop/form/composables/useSSLVerificationWarningHandler.ts'

import { useImportSource } from '../../../composables/useImportSource.ts'
import { useImportSourceConfiguration } from '../../../composables/useImportSourceConfiguration.ts'
import { useSystemSetup } from '../../../composables/useSystemSetup.ts'

import GuidedSetupImportSourceOTRSDownloadButtons from './GuidedSetupImportSourceOTRSDownloadButtons.vue'

import type { ImportSourceConfigurationOtrsData } from '../../../types/setup-import.ts'

const { setTitle } = useSystemSetup()

setTitle(i18n.t('Download %s Migration Plugin', 'OTRS'))

const pluginDownloaded = ref(false)

const { form, onContinueButtonCallback } = useImportSource()

onContinueButtonCallback.value = () => {
  setTitle(i18n.t('Link %s', 'OTRS'))

  onContinueButtonCallback.value = undefined
  pluginDownloaded.value = true
}

const formSchema = [
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'flex flex-col gap-y-2.5 gap-x-3',
    },
    children: [
      {
        name: 'url',
        label: __('URL'),
        type: 'text',
        placeholder:
          'https://example.com/otrs/public.pl?Action=ZammadMigrator;Key=31337',
        required: true,
        validation: 'url',
        help: __(
          'Enter the link provided by the plugin at the end of the installation to link the two systems.',
        ),
      },
      {
        name: 'sslVerify',
        label: __('SSL verification'),
        type: 'toggle',
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
]

const { configureSystemImportSource } = useImportSourceConfiguration(
  EnumSystemImportSource.Otrs,
)

const { updateFieldValues, onChangedField } = useForm(form)
const formChangeFields = reactive<Record<string, Partial<FormSchemaField>>>({})

onChangedField('url', (newValue: FormFieldValue) => {
  if (newValue && typeof newValue === 'string') {
    const disabled = newValue.startsWith('http://')

    formChangeFields.sslVerify = {
      disabled,
    }

    updateFieldValues({
      sslVerify: !disabled,
    })
  }
})
</script>

<template>
  <div v-if="!pluginDownloaded" class="flex flex-col gap-2">
    <CommonLabel>
      {{
        $t(
          'Download and install the %s Migration Plugin on your %s instance.',
          'OTRS',
          'OTRS',
        )
      }}
    </CommonLabel>
    <GuidedSetupImportSourceOTRSDownloadButtons class="mb-5" />
  </div>
  <Form
    v-if="pluginDownloaded === true"
    id="import-otrs-configuration"
    ref="form"
    form-class="mb-2.5"
    :handlers="[useSSLVerificationWarningHandler()]"
    :schema="formSchema"
    :change-fields="formChangeFields"
    @submit="
      configureSystemImportSource(
        $event as FormSubmitData<ImportSourceConfigurationOtrsData>,
      )
    "
  />
</template>
