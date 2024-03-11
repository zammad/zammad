<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useThirdPartyAuthentication } from '#shared/composables/authentication/useThirdPartyAuthentication.ts'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { AdminPasswordAuthRequestData } from '../types/admin-password-auth'
import { useAdminPasswordAuthSendMutation } from '../graphql/mutations/adminPasswordAuthSend.api.ts'

defineOptions({
  beforeRouteEnter(to) {
    const application = useApplicationStore()
    const { hasEnabledProviders } = useThirdPartyAuthentication()

    if (application.config.user_show_password_login) {
      return to.redirectedFrom ? false : '/'
    }

    if (!hasEnabledProviders.value) {
      return to.redirectedFrom ? false : '/'
    }

    return true
  },
})

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
      'Admin password login instructions were sent to your email address.',
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
        'The admin password auth email could not be sent.',
      )
    })
}

const goToLogin = () => {
  router.replace('/login')
}

const retry = () => {
  requestSent.value = false
}
</script>

<template>
  <LayoutPublicPage box-size="medium" :show-logo="false" :title="pageTitle">
    <CommonAlert v-if="adminPasswordAuthError" variant="danger">{{
      $t(adminPasswordAuthError)
    }}</CommonAlert>

    <Form
      v-if="!requestSent"
      id="admin-password-auth"
      ref="form"
      form-class="mb-2.5"
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

    <template #boxActions>
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

      <CommonButton v-else variant="submit" size="medium" @click="retry()">
        {{ $t('Retry') }}
      </CommonButton>
    </template>
  </LayoutPublicPage>
</template>
