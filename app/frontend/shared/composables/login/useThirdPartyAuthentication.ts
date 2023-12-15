// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

export const useThirdPartyAuthentication = () => {
  const application = useApplicationStore()
  const { config } = storeToRefs(application)

  const providers = computed<ThirdPartyAuthProvider[]>(() => {
    return [
      {
        name: i18n.t('Facebook'),
        enabled: !!config.value.auth_facebook,
        icon: 'facebook',
        url: '/auth/facebook',
      },
      {
        name: i18n.t('Twitter'),
        enabled: !!config.value.auth_twitter,
        icon: 'twitter',
        url: '/auth/twitter',
      },
      {
        name: i18n.t('LinkedIn'),
        enabled: !!config.value.auth_linkedin,
        icon: 'linkedin',
        url: '/auth/linkedin',
      },
      {
        name: i18n.t('GitHub'),
        enabled: !!config.value.auth_github,
        icon: 'github',
        url: '/auth/github',
      },
      {
        name: i18n.t('GitLab'),
        enabled: !!config.value.auth_gitlab,
        icon: 'gitlab',
        url: '/auth/gitlab',
      },
      {
        name: i18n.t('Microsoft'),
        enabled: !!config.value.auth_microsoft_office365,
        icon: 'microsoft',
        url: '/auth/microsoft_office365',
      },
      {
        name: i18n.t('Google'),
        enabled: !!config.value.auth_google_oauth2,
        icon: 'google',
        url: '/auth/google_oauth2',
      },
      {
        name: i18n.t('Weibo'),
        enabled: !!config.value.auth_weibo,
        icon: 'weibo',
        url: '/auth/weibo',
      },
      {
        name:
          (config.value['auth_saml_credentials.display_name'] as string) ||
          i18n.t('SAML'),
        enabled: !!config.value.auth_saml,
        icon: 'saml',
        url: '/auth/saml',
      },
      {
        name: i18n.t('SSO'),
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
