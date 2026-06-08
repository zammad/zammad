// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import useFingerprint from '#shared/composables/useFingerprint.ts'
import { EnumAuthenticationProvider } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { getCurrentRouter } from '#shared/router/router.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

export const useThirdPartyAuthentication = () => {
  const application = useApplicationStore()
  const config = toRef(application, 'config')

  const { fingerprint } = useFingerprint()

  // To avoid warning for trying to use useRoute calling it outside of
  // vue-setup scope, like this we read route as a singleton directly
  // and it works in navigation guards as well
  const route = getCurrentRouter().currentRoute.value

  const redirectQueryParam = computed(() => {
    const { redirect: redirectUrl } = route?.query ?? {}
    if (!redirectUrl || typeof redirectUrl !== 'string') return ''

    return `&redirect=${encodeURIComponent(redirectUrl)}`
  })

  const providerUrlQueryParams = computed(
    () => `?fingerprint=${encodeURIComponent(fingerprint.value)}${redirectQueryParam.value}`,
  )

  const providers = computed<ThirdPartyAuthProvider[]>(() => {
    return [
      {
        name: EnumAuthenticationProvider.Facebook,
        label: i18n.t('Facebook'),
        enabled: !!config.value.auth_facebook,
        icon: 'facebook',
        url: `/auth/facebook${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Twitter,
        label: i18n.t('Twitter'),
        enabled: !!config.value.auth_twitter,
        icon: 'twitter',
        url: `/auth/twitter${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Linkedin,
        label: i18n.t('LinkedIn'),
        enabled: !!config.value.auth_linkedin,
        icon: 'linkedin',
        url: `/auth/linkedin${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Github,
        label: i18n.t('GitHub'),
        enabled: !!config.value.auth_github,
        icon: 'github',
        url: `/auth/github${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Gitlab,
        label: i18n.t('GitLab'),
        enabled: !!config.value.auth_gitlab,
        icon: 'gitlab',
        url: `/auth/gitlab${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.MicrosoftOffice365,
        label: i18n.t('Microsoft'),
        enabled: !!config.value.auth_microsoft_office365,
        icon: 'microsoft',
        url: `/auth/microsoft_office365${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.GoogleOauth2,
        label: i18n.t('Google'),
        enabled: !!config.value.auth_google_oauth2,
        icon: 'google',
        url: `/auth/google_oauth2${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Weibo,
        label: i18n.t('Weibo'),
        enabled: !!config.value.auth_weibo,
        icon: 'weibo',
        url: `/auth/weibo${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Saml,
        label: (config.value['auth_saml_credentials.display_name'] as string) || i18n.t('SAML'),
        enabled: !!config.value.auth_saml,
        icon: 'saml',
        url: `/auth/saml${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Sso,
        label: i18n.t('SSO'),
        enabled: !!config.value.auth_sso,
        icon: 'sso',
        url: `/auth/sso${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.OpenidConnect,
        label:
          (config.value['auth_openid_connect_credentials.display_name'] as string) ||
          i18n.t('OpenID Connect'),
        enabled: !!config.value.auth_openid_connect,
        icon: 'openid-connect',
        url: `/auth/openid_connect${providerUrlQueryParams.value}`,
      },
    ]
  })

  const enabledProviders = computed(() => {
    return providers.value.filter((provider) => provider.enabled)
  })

  return {
    enabledProviders,
    hasEnabledProviders: computed(() => enabledProviders.value.length > 0),
  }
}
