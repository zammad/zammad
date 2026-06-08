// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
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
          url: '/auth/github?fingerprint=foobar',
        },
        {
          name: EnumAuthenticationProvider.Gitlab,
          label: 'GitLab',
          enabled: true,
          icon: 'gitlab',
          url: '/auth/gitlab?fingerprint=foobar',
        },
        {
          name: EnumAuthenticationProvider.Saml,
          label: 'SAML',
          enabled: true,
          icon: 'saml',
          url: '/auth/saml?fingerprint=foobar',
        },
      ],
    },
  })
}

describe('LoginThirdParty.vue', () => {
  it('shows the third-party login buttons', () => {
    const view = renderLoginThirdParty()

    const samlButton = view.getByRole('button', { name: 'SAML' })
    const githubButton = view.getByRole('button', { name: 'GitHub' })
    const gitlabButton = view.getByRole('button', { name: 'GitLab' })

    expect(samlButton.parentElement).toHaveAttribute('action', '/auth/saml?fingerprint=foobar')
    expect(githubButton.parentElement).toHaveAttribute('action', '/auth/github?fingerprint=foobar')
    expect(gitlabButton.parentElement).toHaveAttribute('action', '/auth/gitlab?fingerprint=foobar')

    expect(getByIconName(samlButton, 'saml')).toBeInTheDocument()
    expect(getByIconName(githubButton, 'github')).toBeInTheDocument()
    expect(getByIconName(gitlabButton, 'gitlab')).toBeInTheDocument()
  })
})
