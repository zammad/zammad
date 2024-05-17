// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumAuthenticationProvider } from '#shared/graphql/types.ts'

import LoginThirdParty from '../LoginThirdParty.vue'

const renderLoginThirdParty = () => {
  return renderComponent(LoginThirdParty, {
    props: {
      providers: [
        {
          name: EnumAuthenticationProvider.Github,
          label: 'GitHub',
          enabled: true,
          icon: 'github',
          url: '/auth/github',
        },
        {
          name: EnumAuthenticationProvider.Gitlab,
          label: 'GitLab',
          enabled: true,
          icon: 'gitlab',
          url: '/auth/gitlab',
        },
        {
          name: EnumAuthenticationProvider.Saml,
          label: 'SAML',
          enabled: true,
          icon: 'saml',
          url: '/auth/saml',
        },
      ],
    },
  })
}

describe('LoginThirdParty.vue', () => {
  it('shows the third-party login buttons', () => {
    const view = renderLoginThirdParty()

    expect(view.getByText('SAML')).toBeInTheDocument()
    expect(view.getByText('GitHub')).toBeInTheDocument()
    expect(view.getByText('GitLab')).toBeInTheDocument()

    expect(view.getByIconName('saml')).toBeInTheDocument()
    expect(view.getByIconName('github')).toBeInTheDocument()
    expect(view.getByIconName('gitlab')).toBeInTheDocument()
  })
})
