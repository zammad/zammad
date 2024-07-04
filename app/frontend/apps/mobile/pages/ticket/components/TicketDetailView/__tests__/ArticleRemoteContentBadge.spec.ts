// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import ArticleRemoteContentBadge, {
  type Props,
} from '../ArticleRemoteContentBadge.vue'

const renderBadge = (propsData: Props = {}) => {
  return renderComponent(ArticleRemoteContentBadge, {
    props: propsData,
    router: true,
  })
}

const originalFormattingUrl =
  '/ticket_attachment/12/34/56?disposition=attachment'

describe('rendering remote content badge', () => {
  beforeEach(() => {
    mockApplicationConfig({
      api_path: '/api/v1',
    })
  })

  it('renders the button and popup on click', async () => {
    const view = renderBadge({ originalFormattingUrl })

    const button = view.getByRole('button', { name: 'Blocked Content' })

    expect(view.getByIconName('warning')).toBeInTheDocument()

    await view.events.click(button)

    const popup = view.getByTestId('popupWindow')

    expect(within(popup).getByText('Blocked Content')).toBeInTheDocument()
    expect(
      within(popup).getByText(
        'This message contains images or other content hosted by an external source. It was blocked, but you can download the original formatting here.',
      ),
    ).toBeInTheDocument()

    const link = within(popup).getByText('Original Formatting')

    expect(link).toHaveAttribute('href', `/api/v1${originalFormattingUrl}`)
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('does not show original formatting link if missing', async () => {
    const view = renderBadge()

    await view.events.click(
      view.getByRole('button', { name: 'Blocked Content' }),
    )

    const popup = view.getByTestId('popupWindow')

    expect(
      within(popup).queryByText('Original Formatting'),
    ).not.toBeInTheDocument()
  })
})
