<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { AdminPasswordAuthRequestData } from '../types/admin-password-auth'
import { useAdminPasswordAuthSendMutation } from '../graphql/mutations/adminPasswordAuthSend.api.ts'

const router = useRouter()

const adminPasswordAuthRequestSchema = [
  {
    name: 'login',
    type: 'text',
    label: __('Username / Email'),
    required: true,
  },
]

const { form, isDisabled } = useForm()

const requestSent = ref(false)
const adminPasswordAuthError = ref('')

const pageTitle = computed(() => {
  if (requestSent.value) {
    return __(
      "We've sent admin password login instructions to your email address.",
    )
  }

  return __('Request password login for admin?')
})

const send = (data: AdminPasswordAuthRequestData) => {
  const sendAdminPasswordAuth = new MutationHandler(
    useAdminPasswordAuthSendMutation({
      variables: { login: data.login },
    }),
    {
      errorShowNotification: false,
    },
  )

  sendAdminPasswordAuth
    .send()
    .then(() => {
      requestSent.value = true
    })
    .catch(() => {
      adminPasswordAuthError.value = __(
        'Unable to send admin password auth email.',
      )
    })
}

const goToLogin = () => {
  router.replace('login')
}

const retry = () => {
  requestSent.value = false
}
</script>

<template>
  <LayoutPublicPage box-size="small" :show-logo="false" :title="pageTitle">
    <CommonAlert v-if="adminPasswordAuthError" variant="danger">{{
      $t(adminPasswordAuthError)
    }}</CommonAlert>

    <Form
      v-if="!requestSent"
      id="admin-password-auth"
      ref="form"
      form-class="mb-2.5 space-y-2.5"
      :schema="adminPasswordAuthRequestSchema"
      @submit="send($event as FormSubmitData<AdminPasswordAuthRequestData>)"
    />

    <CommonLabel v-if="requestSent">
      {{
        $t(
          "If you don't receive instructions within a minute or two, check your email's spam and junk filters, or try resending your request.",
        )
      }}
    </CommonLabel>

    <div class="flex justify-end items-end gap-2">
      <CommonButton
        variant="secondary"
        size="medium"
        :disabled="isDisabled"
        @click="goToLogin()"
      >
        {{ $t('Cancel & Go Back') }}
      </CommonButton>

      <CommonButton
        v-if="!requestSent"
        variant="submit"
        type="submit"
        size="medium"
        form="admin-password-auth"
        :disabled="isDisabled"
      >
        {{ $t('Submit') }}
      </CommonButton>

      <CommonButton
        v-if="requestSent"
        variant="submit"
        size="medium"
        @click="retry()"
      >
        {{ $t('Retry') }}
      </CommonButton>
    </div>
  </LayoutPublicPage>
</template>
