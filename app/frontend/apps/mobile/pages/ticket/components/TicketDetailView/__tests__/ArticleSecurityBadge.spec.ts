// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '@shared/graphql/utils'
import { getByRole, getByText } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import ArticleSecurityBadge, { type Props } from '../ArticleSecurityBadge.vue'

const renderBadge = (propsData: Props) => {
  return renderComponent(ArticleSecurityBadge, {
    props: propsData,
  })
}

const SUCCESS_COMMENT =
  '/emailAddress=smime1@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com'

describe('rendering security badge', () => {
  it('renders success classes, when security passed')

  describe('renders encryption', () => {
    const renderEncryption = (success: boolean, comment: string) => {
      return renderBadge({
        articleId: convertToGraphQLId('Ticket::Article', 1),
        security: { encryptionMessage: comment, encryptionSuccess: success },
      })
    }

    it('renders successful encryption, if provided', async () => {
      const view = renderEncryption(true, SUCCESS_COMMENT)

      expect(view.getByIconName('mobile-lock')).toBeInTheDocument()
      expect(view.getByLabelText('Encrypted')).toBeInTheDocument()
      expect(view.queryByIconName('mobile-unlock')).not.toBeInTheDocument()
      expect(view.queryByIconName('mobile-signed')).not.toBeInTheDocument()
      expect(view.queryByIconName('mobile-not-signed')).not.toBeInTheDocument()

      await view.events.click(view.getByRole('button'))

      expect(view.queryByText('Security Error')).not.toBeInTheDocument()
      expect(
        view.getByText(`Encryption: ${SUCCESS_COMMENT}`),
      ).toBeInTheDocument()
    })

    it('ignores encryption error, if comment is not provided', () => {
      const view = renderEncryption(false, '')

      expect(view.queryByIconName('mobile-lock')).not.toBeInTheDocument()
      expect(view.queryByLabelText('Encrypted')).not.toBeInTheDocument()
    })

    it('renders security error, if encryption is unsuccessful and comment is provided', async () => {
      const view = renderEncryption(false, 'error!')

      expect(view.getByText('Security Error')).toBeInTheDocument()

      const icon = view.getByIconName('mobile-unlock')
      expect(icon).toBeInTheDocument()

      await view.events.click(icon)

      const popup = view.getByTestId('popupWindow')
      expect(getByText(popup, 'Security Error')).toBeInTheDocument()
      expect(getByText(popup, 'Encryption: error!')).toBeInTheDocument()
      expect(
        getByRole(popup, 'button', { name: 'Try again' }),
      ).toBeInTheDocument()
    })
  })

  describe('renders sign', () => {
    const renderSign = (success: boolean, comment: string) => {
      return renderBadge({
        articleId: convertToGraphQLId('Ticket::Article', 1),
        security: { signingMessage: comment, signingSuccess: success },
      })
    }

    it('renders successful sign, if provided', async () => {
      const view = renderSign(true, SUCCESS_COMMENT)

      expect(view.getByLabelText('Signed')).toBeInTheDocument()
      expect(view.getByIconName('mobile-signed')).toBeInTheDocument()
      expect(view.queryByIconName('mobile-not-signed')).not.toBeInTheDocument()
      expect(view.queryByIconName('mobile-lock')).not.toBeInTheDocument()
      expect(view.queryByLabelText('Encrypted')).not.toBeInTheDocument()

      await view.events.click(view.getByRole('button'))

      expect(view.queryByText('Security Error')).not.toBeInTheDocument()
      expect(view.getByText(`Sign: ${SUCCESS_COMMENT}`)).toBeInTheDocument()
    })

    it('ignores sign error, if comment is not provided', () => {
      const view = renderSign(false, '')

      expect(view.queryByIconName('mobile-signed')).not.toBeInTheDocument()
      expect(view.queryByIconName('mobile-not-signed')).not.toBeInTheDocument()
      expect(view.queryByLabelText('Signed')).not.toBeInTheDocument()
      expect(view.queryByLabelText('Unsigned')).not.toBeInTheDocument()
    })

    it('renders security error, if sign is unsuccessful and comment is provided', async () => {
      const view = renderSign(false, 'error!')

      expect(view.getByText('Security Error')).toBeInTheDocument()

      const icon = view.getByIconName('mobile-not-signed')
      expect(icon).toBeInTheDocument()

      await view.events.click(icon)

      const popup = view.getByTestId('popupWindow')
      expect(getByText(popup, 'Security Error')).toBeInTheDocument()
      expect(getByText(popup, 'Sign: error!')).toBeInTheDocument()
      expect(
        getByRole(popup, 'button', { name: 'Try again' }),
      ).toBeInTheDocument()
    })
  })

  it('renders both, if provided', () => {
    const view = renderBadge({
      articleId: convertToGraphQLId('Ticket::Article', 1),
      security: {
        encryptionMessage: '',
        encryptionSuccess: true,
        signingMessage: '',
        signingSuccess: true,
      },
    })

    expect(view.queryByText('Security Error')).not.toBeInTheDocument()
    expect(view.getByLabelText('Signed')).toBeInTheDocument()
    expect(view.getByIconName('mobile-signed')).toBeInTheDocument()
    expect(view.getByIconName('mobile-lock')).toBeInTheDocument()
    expect(view.getByLabelText('Encrypted')).toBeInTheDocument()
  })

  it('renders both, when both are unsuccessful', async () => {
    const view = renderBadge({
      articleId: convertToGraphQLId('Ticket::Article', 1),
      security: {
        signingMessage: 'sign error',
        signingSuccess: false,
        encryptionMessage: 'encryption error',
        encryptionSuccess: false,
      },
    })

    expect(view.getByText('Security Error')).toBeInTheDocument()

    // signed icon has priority over lock icon, when both failed
    const icon = view.getByIconName('mobile-not-signed')
    expect(icon).toBeInTheDocument()

    await view.events.click(icon)

    const popup = view.getByTestId('popupWindow')
    expect(getByText(popup, 'Security Error')).toBeInTheDocument()
    expect(getByText(popup, 'Encryption: encryption error')).toBeInTheDocument()
    expect(getByText(popup, 'Sign: sign error')).toBeInTheDocument()

    expect(
      getByRole(popup, 'button', { name: 'Try again' }),
    ).toBeInTheDocument()
  })
})
