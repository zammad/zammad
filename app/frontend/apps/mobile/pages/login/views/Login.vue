<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import { useAuthenticationStore } from '@shared/stores/authentication'
import CommonLogo from '@shared/components/CommonLogo/CommonLogo.vue'
import Form from '@shared/components/Form/Form.vue'
import { type FormData, useForm } from '@shared/components/Form'
import UserError from '@shared/errors/UserError'
import { defineFormSchema } from '@mobile/form/defineFormSchema'
import { useApplicationStore } from '@shared/stores/application'
import { usePublicLinksQuery } from '@shared/entities/public-links/graphql/queries/links.api'
import type {
  PublicLinkUpdatesSubscription,
  PublicLinkUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import { EnumPublicLinksScreen } from '@shared/graphql/types'
import { computed } from 'vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { PublicLinkUpdatesDocument } from '@shared/entities/public-links/graphql/subscriptions/currentLinks.api'

const route = useRoute()

// Output a hint when the session is no longer valid.
// This could happen because the session was deleted on the server.
if (route.query.invalidatedSession === '1') {
  const { notify } = useNotifications()

  notify({
    message: __('The session is no longer valid. Please log in again.'),
    type: NotificationTypes.Warn,
  })

  // TODO: After showing this we should remove the query parameter from the URL.
}

const authentication = useAuthenticationStore()

const router = useRouter()

const application = useApplicationStore()

const loginSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'login',
        type: 'text',
        label: __('Username / Email'),
        placeholder: __('Username / Email'),
        required: true,
      },
    ],
  },
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'password',
        label: __('Password'),
        placeholder: __('Password'),
        type: 'password',
        required: true,
      },
    ],
  },
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'mt-2.5 flex grow items-center justify-between text-white',
    },
    children: [
      {
        type: 'checkbox',
        name: 'rememberMe',
        label: __('Remember me'),
        wrapperClass: '!h-6',
      },
      // TODO support if/then in form-schema
      ...(application.config.user_lost_password
        ? [
            {
              isLayout: true,
              component: 'CommonLink',
              props: {
                class: 'text-right text-white',
                link: '/#password_reset',
              },
              children: __('Forgot password?'),
            },
          ]
        : []),
    ],
  },
])

interface LoginFormData {
  login: string
  password: string
  rememberMe: boolean
}

const publicLinksQuery = new QueryHandler(
  usePublicLinksQuery({
    screen: EnumPublicLinksScreen.Login,
  }),
)

publicLinksQuery.subscribeToMore<
  PublicLinkUpdatesSubscriptionVariables,
  PublicLinkUpdatesSubscription
>({
  document: PublicLinkUpdatesDocument,
  variables: {
    screen: EnumPublicLinksScreen.Login,
  },
  updateQuery(existing, { subscriptionData }) {
    const publicLinks = subscriptionData.data.publicLinkUpdates?.publicLinks
    return {
      publicLinks: publicLinks || existing.publicLinks || [],
    }
  },
})

const links = computed(() => {
  const publicLinks = publicLinksQuery.result()

  return publicLinks.value?.publicLinks || []
})

// TODO: workaround for disabled button state, will be changed in formkit.
const { form, isDisabled } = useForm()

const login = (formData: FormData<LoginFormData>) => {
  const { notify, clearAllNotifications } = useNotifications()

  // Clear notifications to avoid duplicated error messages.
  clearAllNotifications()

  return authentication
    .login(formData.login, formData.password, formData.rememberMe)
    .then(() => {
      // TODO: maybe we need some additional logic for the ThirtParty-Login situtation.
      const { redirect: redirectUrl } = route.query
      if (typeof redirectUrl === 'string') {
        router.replace(redirectUrl)
      } else {
        router.replace('/')
      }
    })
    .catch((errors: UserError) => {
      if (errors instanceof UserError) {
        notify({
          message: errors.generalErrors[0],
          type: NotificationTypes.Error,
        })
      }
    })
}
</script>

<template>
  <div class="flex h-full min-h-screen flex-col items-center px-6 pt-6 pb-4">
    <main class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div class="my-5 grow">
          <div class="flex justify-center p-2">
            <CommonLogo />
          </div>
          <h1 class="mb-6 flex justify-center p-2 text-2xl font-extrabold">
            {{ $c.product_name }}
          </h1>
          <template v-if="$c.maintenance_mode">
            <div
              class="my-1 flex items-center rounded-xl bg-red py-2 px-4 text-white"
            >
              {{
                $t(
                  'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
                )
              }}
            </div>
          </template>
          <template v-if="$c.maintenance_login && $c.maintenance_login_message">
            <!-- eslint-disable vue/no-v-html -->
            <div
              class="my-1 flex items-center rounded-xl bg-green py-2 px-4 text-white"
              v-html="$c.maintenance_login_message"
            ></div>
          </template>
          <Form
            id="signin"
            ref="form"
            class="text-left"
            :schema="loginSchema"
            @submit="login($event as FormData<LoginFormData>)"
          >
            <template #after-fields>
              <div
                v-if="$c.user_create_account"
                class="mt-4 flex grow items-center justify-center"
              >
                <span class="ltr:mr-1 rtl:ml-1">{{ $t('New user?') }}</span>
                <CommonLink
                  link="/#signup"
                  class="cursor-pointer select-none !text-yellow underline"
                >
                  {{ $t('Register') }}
                </CommonLink>
              </div>
              <FormKit
                wrapper-class="mt-6 flex grow justify-center items-center"
                input-class="py-2 px-4 w-full h-14 text-xl font-semibold !text-black formkit-variant-primary:bg-yellow rounded-xl select-none"
                type="submit"
                :disabled="isDisabled"
              >
                {{ $t('Sign in') }}
              </FormKit>
            </template>
          </Form>
        </div>
      </div>
    </main>
    <CommonLink link="/#login" class="font-medium leading-4 text-gray">
      {{ $t('Continue to desktop app') }}
    </CommonLink>
    <nav
      v-if="links.length"
      class="mt-4 flex w-full max-w-md flex-wrap items-center justify-center gap-1"
    >
      <template v-for="link in links" :key="link.id">
        <CommonLink
          :link="link.link"
          :title="link.description"
          :open-in-new-tab="link.newTab"
          class="font-semibold leading-4 tracking-wide text-gray after:ml-1 after:font-medium after:text-gray-200 after:content-['|'] last:after:content-none"
        >
          {{ $t(link.title) }}
        </CommonLink>
      </template>
    </nav>
    <footer
      class="mt-8 mb-14 flex w-full max-w-md items-center justify-center border-t border-gray-600 pt-2.5 align-middle font-medium leading-4 text-gray"
    >
      <CommonLink
        v-if="application.hasCustomProductBranding"
        link="https://zammad.org"
        external
        open-in-new-tab
        class="ltr:mr-1 rtl:ml-1"
      >
        <img
          :src="'/assets/images/icons/logo.svg'"
          :alt="$t('Logo')"
          class="h-6 w-6"
        />
      </CommonLink>
      <span class="ltr:mr-1 rtl:ml-1">{{ $t('Powered by') }}</span>
      <CommonLink
        link="https://zammad.org"
        external
        open-in-new-tab
        class="font-semibold"
      >
        Zammad
      </CommonLink>
    </footer>
  </div>
</template>
