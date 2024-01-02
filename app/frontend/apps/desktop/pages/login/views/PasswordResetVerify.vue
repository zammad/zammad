<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, onBeforeMount } from 'vue'
import { useRouter } from 'vue-router'
import { useForm } from '#shared/components/Form/useForm.ts'
import type {
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import Form from '#shared/components/Form/Form.vue'
import { useApplicationStore } from '#shared/stores/application.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage.vue'
import CommonPublicLinks from '#desktop/components/CommonPublicLinks/CommonPublicLinks.vue'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useUserPasswordResetVerifyMutation } from '../graphql/mutations/userPasswordResetVerify.api.ts'
import { useUserPasswordResetUpdateMutation } from '../graphql/mutations/userPasswordResetUpdate.api.ts'

defineOptions({
  beforeRouteEnter(to) {
    const application = useApplicationStore()
    if (!application.config.user_lost_password) {
      return to.redirectedFrom ? false : '/'
    }
    return true
  },
})

interface Props {
  token?: string
}

const props = defineProps<Props>()

interface FormValues {
  password: string
  confirmPassword: string
}

const formSchema: FormSchemaNode[] = [
  {
    type: 'password',
    label: __('Password'),
    name: 'password',
    outerClass: 'col-span-1',
    required: true,
    props: {
      maxLength: 1001,
    },
  },
  {
    type: 'password',
    label: __('Confirm password'),
    name: 'password_confirm',
    outerClass: 'col-span-1',
    validation: 'confirm',
    props: {
      maxLength: 1001,
    },
    required: true,
  },
]

const { form, isDisabled } = useForm()

const errorMessage = ref('')
const loading = ref(true)
const canResetPassword = ref(false)

const { notify } = useNotifications()
const router = useRouter()

onBeforeMount(() => {
  if (!props.token) {
    loading.value = false
    canResetPassword.value = false
    errorMessage.value = __(
      'The token could not be verified. Please contact your administrator.',
    )
    return
  }

  const userSignupVerify = new MutationHandler(
    useUserPasswordResetVerifyMutation({
      variables: { token: props.token },
    }),
    {
      errorShowNotification: false,
    },
  )

  userSignupVerify
    .send()
    .then(() => {
      canResetPassword.value = true
      errorMessage.value = ''
    })
    .catch(() => {
      canResetPassword.value = false
      errorMessage.value = __('The provided token is invalid.')
    })
    .finally(() => {
      loading.value = false
    })
})

const resetPasswordHandler = new MutationHandler(
  useUserPasswordResetUpdateMutation(),
  { errorShowNotification: false },
)

const updatePassword = async (form: FormSubmitData<FormValues>) => {
  await resetPasswordHandler.send({
    token: props.token!,
    password: form.password,
  })

  notify({
    type: NotificationTypes.Success,
    message: __('Woo hoo! Your password has been changed!'),
  })
  router.replace('/login')
}
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="__('Choose your new password')">
    <CommonLoader :loading="loading" :error="errorMessage" />
    <div
      v-if="!canResetPassword"
      class="flex gap-3 justify-end items-center mt-3"
    >
      <CommonLink link="/login" replace class="select-none">
        {{ $t('Cancel & Go Back') }}
      </CommonLink>
    </div>
    <Form
      v-else
      ref="form"
      form-class="grid grid-cols-2 gap-y-2.5 gap-x-3"
      :schema="formSchema"
      @submit="updatePassword($event as FormSubmitData<FormValues>)"
    >
      <template #after-fields>
        <div class="flex gap-3 justify-end items-center pt-5">
          <CommonLink link="/login" replace class="select-none">
            {{ $t('Cancel & Go Back') }}
          </CommonLink>
          <CommonButton
            type="submit"
            variant="submit"
            size="large"
            :disabled="isDisabled"
          >
            {{ $t('Submit') }}
          </CommonButton>
        </div>
      </template>
    </Form>
    <template #bottomContent>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.PasswordReset" />
    </template>
  </LayoutPublicPage>
</template>
