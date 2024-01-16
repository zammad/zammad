<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { shallowRef, computed, reactive } from 'vue'
import { useRouter } from 'vue-router'

import type { FormSubmitData } from '#shared/components/Form/types.ts'
import Form from '#shared/components/Form/Form.vue'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useLogoUrl } from '#shared/composables/useLogoUrl.ts'

import { useSystemSetupManual } from '../../composables/useSystemSetupManual.ts'
import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useGuidedSetupSetSystemInformationMutation } from '../../graphql/mutations/setSystemInformation.api.ts'

const router = useRouter()

const { logoUrl } = useLogoUrl()

const { setTitle } = useSystemSetupManual()
const systemInformationSchema = [
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'grid gap-y-2.5',
    },
    children: [
      {
        name: 'organization',
        label: __('Organization Name'),
        type: 'text',
        required: true,
        placeholder: __('Company Inc.'),
      },
      {
        name: 'logo',
        label: __('Organization Logo'),
        type: 'imageUpload',
        props: {
          placeholderImagePath: logoUrl,
        },
      },
      {
        if: '$isSystemOnlineService !== true',
        name: 'url',
        label: __('System URL'),
        type: 'text',
        required: true,
        validation: 'url',
        help: __('The URL of this installation of Zammad.'),
      },
    ],
  },
]

setTitle(__('System Information'))

interface SystemInformationData {
  organization: string
  logo: string
  url: string
  localeDefault: string
  timezoneDefault: string
}

const form = shallowRef()

const application = useApplicationStore()
const isSystemOnlineService = computed(
  () => application.config.system_online_service,
)

const schemaData = reactive({
  isSystemOnlineService,
  logoPlaceholderUrl: logoUrl,
})

const dateTimeFormatOptions = Intl?.DateTimeFormat
  ? new Intl.DateTimeFormat().resolvedOptions()
  : null

const locale = dateTimeFormatOptions?.locale
const timezone = dateTimeFormatOptions?.timeZone

const setSystemInformation = async (formData: SystemInformationData) => {
  const setSystemInformationMutation = new MutationHandler(
    useGuidedSetupSetSystemInformationMutation({}),
  )

  return setSystemInformationMutation
    .send({
      input: {
        organization: formData.organization,
        logo: formData.logo,
        url: formData.url,
        localeDefault: locale,
        timezoneDefault: timezone,
      },
    })
    .then(() => {
      router.push('/guided-setup/manual/email-notification')
    })
}
</script>

<template>
  <Form
    id="set-system-manual"
    ref="form"
    form-class="mb-2.5"
    :schema="systemInformationSchema"
    :schema-data="schemaData"
    @submit="
      setSystemInformation($event as FormSubmitData<SystemInformationData>)
    "
  />
  <GuidedSetupActionFooter
    :form="form"
    :submit-button-text="__('Save and Continue')"
  />
</template>
