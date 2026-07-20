// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { ErrorStatusCodes } from '#shared/types/error.ts'

import CommonError from '../CommonError.vue'

const options = {
  title: 'Not found',
  message: "This page doesn't exist.",
  statusCode: ErrorStatusCodes.NotFound,
}

describe('CommonError', () => {
  it('renders a back link when one is provided', () => {
    const view = renderComponent(CommonError, {
      props: {
        authenticated: true,
        options: {
          ...options,
          backLink: { label: 'Go to knowledge base', link: '/knowledge-base/locale/en-us' },
        },
      },
      router: true,
    })

    const link = view.getByRole('link', { name: 'Go to knowledge base' })
    expect(link).toHaveAttribute('href', '/knowledge-base/locale/en-us')
  })

  it('renders no back link when none is provided', () => {
    const view = renderComponent(CommonError, {
      props: { authenticated: true, options },
      router: true,
    })

    expect(view.queryByRole('link')).not.toBeInTheDocument()
  })
})
