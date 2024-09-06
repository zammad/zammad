<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { shallowRef, computed, reactive } from 'vue'
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormValues,
} from '#shared/components/Form/types.ts'
import { useBaseUrl } from '#shared/composables/useBaseUrl.ts'
import { useLogoUrl } from '#shared/composables/useLogoUrl.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import { useGuidedSetupSetSystemInformationMutation } from '../../graphql/mutations/setSystemInformation.api.ts'

import type { SystemInformationData } from '../../types/setup-manual.ts'

const router = useRouter()
const application = useApplicationStore()

const { logoUrl } = useLogoUrl()

const { setTitle } = useSystemSetup()
setTitle(__('System Information'))

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
        label: __('Organization name'),
        type: 'text',
        required: true,
        placeholder: __('Company Inc.'),
      },
      {
        name: 'logo',
        label: __('Organization logo'),
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

const { baseUrl } = useBaseUrl()

const initialValues: FormValues = {
  organization: application.config.organization,
  url: baseUrl.value,
}

const form = shallowRef()

const isSystemOnlineService = computed(
  () => application.config.system_online_service,
)

const schemaData = reactive({
  isSystemOnlineService,
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
      if (application.config.system_online_service) {
        router.push('/guided-setup/manual/channels/email-pre-configured')
        return
      }

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
    :initial-values="initialValues"
    @submit="
      setSystemInformation($event as FormSubmitData<SystemInformationData>)
    "
  />
  <GuidedSetupActionFooter
    :form="form"
    :submit-button-text="__('Save and Continue')"
  />
</template>
