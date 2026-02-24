// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'
import { useRoute } from 'vue-router'

import useFingerprint from '#shared/composables/useFingerprint.ts'
import { EnumAuthenticationProvider } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

export const useThirdPartyAuthentication = () => {
  const application = useApplicationStore()
  const config = toRef(application, 'config')

  const { fingerprint } = useFingerprint()

  const route = useRoute()

  const redirectQueryParam = computed(() => {
    const { redirect: redirectUrl } = route?.query ?? {}
    if (!redirectUrl || typeof redirectUrl !== 'string') return ''

    return `&redirect=${encodeURIComponent(redirectUrl)}`
  })

  const providerUrlQueryParams = computed(
    () => `?fingerprint=${encodeURIComponent(fingerprint.value)}${redirectQueryParam.value}`,
  )

  const availableProviders = computed(
    () => config.value.omniauth_available_providers ?? [],
  )

  const available = (provider: string) => availableProviders.value.includes(provider)


  const providers = computed<ThirdPartyAuthProvider[]>(() => {
    return [
      {
        name: EnumAuthenticationProvider.Facebook,
        label: i18n.t('Facebook'),
        enabled: !!config.value.auth_facebook && available('facebook'),
        icon: 'facebook',
        url: `/auth/facebook${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Twitter,
        label: i18n.t('Twitter'),
        enabled: !!config.value.auth_twitter && available('twitter'),
        icon: 'twitter',
        url: `/auth/twitter${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Linkedin,
        label: i18n.t('LinkedIn'),
        enabled: !!config.value.auth_linkedin && available('linkedin'),
        icon: 'linkedin',
        url: `/auth/linkedin${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Github,
        label: i18n.t('GitHub'),
        enabled: !!config.value.auth_github && available('github'),
        icon: 'github',
        url: `/auth/github${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Gitlab,
        label: i18n.t('GitLab'),
        enabled: !!config.value.auth_gitlab && available('gitlab'),
        icon: 'gitlab',
        url: `/auth/gitlab${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.MicrosoftOffice365,
        label: i18n.t('Microsoft'),
        enabled: !!config.value.auth_microsoft_office365 && available('microsoft_office365'),
        icon: 'microsoft',
        url: `/auth/microsoft_office365${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.GoogleOauth2,
        label: i18n.t('Google'),
        enabled: !!config.value.auth_google_oauth2 && available('google_oauth2'),
        icon: 'google',
        url: `/auth/google_oauth2${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Weibo,
        label: i18n.t('Weibo'),
        enabled: !!config.value.auth_weibo && available('weibo'),
        icon: 'weibo',
        url: `/auth/weibo${providerUrlQueryParams.value}`,
      },
      {
        name: EnumAuthenticationProvider.Saml,
        label: (config.value['auth_saml_credentials.display_name'] as string) || i18n.t('SAML'),
        enabled: !!config.value.auth_saml && available('saml'),
        icon: 'saml',
        url: `/auth/saml${providerUrlQueryParams.value}`,
      },
      {
        // SSO uses HTTP headers, has no external gem dependency, and is always available when enabled.
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
        enabled: !!config.value.auth_openid_connect && available('openid_connect'),
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
