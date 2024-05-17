// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { EnumAuthenticationProvider } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

export const useThirdPartyAuthentication = () => {
  const application = useApplicationStore()
  const { config } = storeToRefs(application)

  const providers = computed<ThirdPartyAuthProvider[]>(() => {
    return [
      {
        name: EnumAuthenticationProvider.Facebook,
        label: i18n.t('Facebook'),
        enabled: !!config.value.auth_facebook,
        icon: 'facebook',
        url: '/auth/facebook',
      },
      {
        name: EnumAuthenticationProvider.Twitter,
        label: i18n.t('Twitter'),
        enabled: !!config.value.auth_twitter,
        icon: 'twitter',
        url: '/auth/twitter',
      },
      {
        name: EnumAuthenticationProvider.Linkedin,
        label: i18n.t('LinkedIn'),
        enabled: !!config.value.auth_linkedin,
        icon: 'linkedin',
        url: '/auth/linkedin',
      },
      {
        name: EnumAuthenticationProvider.Github,
        label: i18n.t('GitHub'),
        enabled: !!config.value.auth_github,
        icon: 'github',
        url: '/auth/github',
      },
      {
        name: EnumAuthenticationProvider.Gitlab,
        label: i18n.t('GitLab'),
        enabled: !!config.value.auth_gitlab,
        icon: 'gitlab',
        url: '/auth/gitlab',
      },
      {
        name: EnumAuthenticationProvider.MicrosoftOffice365,
        label: i18n.t('Microsoft'),
        enabled: !!config.value.auth_microsoft_office365,
        icon: 'microsoft',
        url: '/auth/microsoft_office365',
      },
      {
        name: EnumAuthenticationProvider.GoogleOauth2,
        label: i18n.t('Google'),
        enabled: !!config.value.auth_google_oauth2,
        icon: 'google',
        url: '/auth/google_oauth2',
      },
      {
        name: EnumAuthenticationProvider.Weibo,
        label: i18n.t('Weibo'),
        enabled: !!config.value.auth_weibo,
        icon: 'weibo',
        url: '/auth/weibo',
      },
      {
        name: EnumAuthenticationProvider.Saml,
        label:
          (config.value['auth_saml_credentials.display_name'] as string) ||
          i18n.t('SAML'),
        enabled: !!config.value.auth_saml,
        icon: 'saml',
        url: '/auth/saml',
      },
      {
        name: EnumAuthenticationProvider.Sso,
        label: i18n.t('SSO'),
        enabled: !!config.value.auth_sso,
        icon: 'sso',
        url: '/auth/sso',
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
