<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { SignupFormData } from '#shared/entities/user/types.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPublicLinks from '#desktop/components/CommonPublicLinks/CommonPublicLinks.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
import { useSignupForm } from '#desktop/composables/authentication/useSignupForm.ts'

import { useUserSignupMutation } from '../graphql/mutations/userSignup.api.ts'
import { useUserSignupResendMutation } from '../graphql/mutations/userSignupResend.api.ts'

defineOptions({
  beforeRouteEnter(to) {
    const application = useApplicationStore()
    if (!application.config.user_create_account) {
      return to.redirectedFrom ? false : '/'
    }
    return true
  },
})

const application = useApplicationStore()

const router = useRouter()

const { signupSchema } = useSignupForm()

const { form, isDisabled } = useForm()

const signupSent = ref(false)
const signupEmail = ref('')

const pageTitle = computed(() => {
  if (signupSent.value) return __('Registration successful!')

  return i18n.t('Join %s', application.config.product_name)
})

const singup = async (data: SignupFormData) => {
  const sendSignup = new MutationHandler(useUserSignupMutation())

  return sendSignup
    .send({
      input: {
        firstname: data.firstname,
        lastname: data.lastname,
        email: data.email,
        password: data.password,
      },
    })
    .then(() => {
      signupSent.value = true
      signupEmail.value = data.email
    })
}

const { notify } = useNotifications()

const resendVerifyEmail = () => {
  const resendVerifyEmail = new MutationHandler(
    useUserSignupResendMutation({
      variables: {
        email: signupEmail.value,
      },
    }),
    {
      errorShowNotification: false,
    },
  )

  resendVerifyEmail
    .send()
    .then(() => {
      notify({
        id: 'resend-verify-email',
        type: NotificationTypes.Success,
        message: __('Email sent to "%s". Please verify your email account.'),
        messagePlaceholder: [signupEmail.value],
      })
    })
    .catch(() => {
      notify({
        id: 'resend-verify-email-error',
        type: NotificationTypes.Error,
        message: __('The verification email could not be resent.'),
      })
    })
}

const goToLogin = () => {
  router.replace('login')
}
</script>

<template>
  <LayoutPublicPage box-size="medium" :show-logo="false" :title="pageTitle">
    <Form
      v-if="!signupSent"
      id="signup"
      ref="form"
      form-class="mb-2.5"
      :schema="signupSchema"
      @submit="singup($event as FormSubmitData<SignupFormData>)"
    />

    <div v-else class="flex flex-col items-center gap-2.5">
      <CommonLabel class="py-5 text-center">
        {{ $t('Thanks for joining. Email sent to "%s".', signupEmail) }}
      </CommonLabel>
      <CommonLabel class="py-5 text-center">
        {{
          $t(
            "Please click on the link in the verification email. If you don't see the email, check other places it might be, like your junk, spam, social, or other folders.",
          )
        }}
      </CommonLabel>
    </div>

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
        v-if="!signupSent"
        variant="submit"
        type="submit"
        size="medium"
        form="signup"
        :disabled="isDisabled"
      >
        {{ $t('Create my account') }}
      </CommonButton>
      <CommonButton
        v-else
        variant="submit"
        size="medium"
        @click="resendVerifyEmail()"
      >
        {{ $t('Resend verification email') }}
      </CommonButton>
    </template>

    <template #bottomContent>
      <div
        class="inline-flex flex-wrap items-center justify-center p-2 text-sm"
      >
        <CommonLabel class="text-center text-stone-200 dark:text-neutral-500">
          {{
            $t(
              "You're already registered with your email address if you've been in touch with our Support team.",
            )
          }}
        </CommonLabel>
        <CommonLink v-if="$c.user_lost_password" link="/reset-password">{{
          $t('You can request your password here.')
        }}</CommonLink>
      </div>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.Signup" />
    </template>
  </LayoutPublicPage>
</template>
