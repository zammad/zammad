// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { waitForAnimationFrame } from '@shared/utils/helpers'
import { renderComponent } from '@tests/support/components'
import { mockAccount } from '@tests/support/mock-account'
import ArticleBubble, { type Props } from '../ArticleBubble.vue'

const renderArticleBubble = (props: Partial<Props> = {}) => {
  return renderComponent(ArticleBubble, {
    props: {
      position: 'right',
      internal: false,
      content: 'Some Content',
      user: {
        id: '2',
        firstname: 'Max',
        lastname: 'Mustermann',
      },
      ...props,
    },
  })
}

describe('component for displaying text article', () => {
  beforeEach(() => {
    mockAccount({
      id: '2',
    })
  })

  it('renders basic stuff', async () => {
    const view = renderArticleBubble()

    expect(view.getByRole('comment'), 'has content reversed').toHaveClass(
      'flex-row-reverse',
    )
    expect(
      view.getByRole('img', { name: 'Avatar (Max Mustermann)' }),
      'shows avatar',
    ).toBeInTheDocument()
    expect(
      view.queryByIconName('lock'),
      'doesnt have a lock icon',
    ).not.toBeInTheDocument()
    expect(view.getByText('Me'), 'instead of name shows me').toBeInTheDocument()

    await view.events.click(view.getByIconName('overflow-button'))

    expect(view.emitted()).toHaveProperty('showContext')

    await view.rerender({
      position: 'left',
      user: {
        id: '3',
        lastname: 'Mustermann',
      },
    })

    expect(
      view.getByText('Mustermann'),
      'shows surname, when not mine article and has no name',
    ).toBeInTheDocument()

    expect(
      view.getByRole('comment'),
      'doesnt have content reversed',
    ).not.toHaveClass('flex-row-reverse')

    await view.rerender({
      position: 'left',
      internal: true,
      user: {
        id: '3',
        lastname: '-',
      },
    })

    expect(view.queryByIconName('lock'), 'has a lock icon').toBeInTheDocument()
    expect(
      view.getByTestId('article-username'),
      'doesnt have content name',
    ).not.toHaveTextContent('-')

    expect(view.queryByText('Show more')).not.toBeInTheDocument()
  })

  it('has "see more" for large article', async () => {
    const view = renderArticleBubble({
      content: '<div>Text</div>'.repeat(5),
    })

    const content = view.getByTestId('article-content')

    Object.defineProperty(content, 'clientHeight', {
      value: 900,
    })

    await waitForAnimationFrame()

    const seeMoreButton = view.getByText('See more')
    expect(seeMoreButton).toBeInTheDocument()

    expect(content, 'has maximum height').toHaveStyle({ height: '320px' })

    await view.events.click(seeMoreButton)

    expect(seeMoreButton).toHaveTextContent('See less')
    expect(content, 'has actual height').toHaveStyle({ height: '900px' })
  })

  it('has "see more" for small article with signature', async () => {
    const html = String.raw

    const view = renderArticleBubble({
      content: html`<div>
        Text
        <div>
          <div data-test-id="signature" data-signature="true">Signature</div>
        </div>
      </div>`,
    })

    const content = view.getByTestId('article-content')
    const signature = view.getByTestId('signature')

    Object.defineProperty(content, 'clientHeight', {
      value: 200,
    })
    Object.defineProperty(signature, 'offsetTop', {
      value: 65,
    })

    await waitForAnimationFrame()

    const seeMoreButton = view.getByText('See more')
    expect(seeMoreButton).toBeInTheDocument()

    expect(content, 'has maximum height').toHaveStyle({ height: '65px' })

    await view.events.click(seeMoreButton)

    expect(seeMoreButton).toHaveTextContent('See less')
    expect(content, 'has actual height').toHaveStyle({ height: '200px' })
  })
})
