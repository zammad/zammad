// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import CommonSectionContainer from '../CommonSectionContainer.vue'

describe('CommonSectionContainer', () => {
  it('renders CommonSectionContainer with default styles', () => {
    const wrapper = renderComponent(CommonSectionContainer, {
      props: {
        label: 'test-label',
      },
    })

    const container = wrapper.getByRole('region', { name: 'test-label' })

    expect(container).toHaveClass('rounded-lg')
    expect(container).toHaveClass('p-3')
    expect(container).toHaveClass('bg-blue-200')
    expect(container).toHaveClass('dark:bg-gray-500')
  })

  it('applies alternative background color when prop is true', () => {
    const wrapper = renderComponent(CommonSectionContainer, {
      props: {
        label: 'test-label',
        alternativeBackground: true,
      },
    })

    const container = wrapper.getByRole('region', { name: 'test-label' })

    expect(container).toHaveClass('bg-blue-200')
    expect(container).toHaveClass('dark:bg-gray-700')
  })

  it('renders slot content when provided', () => {
    const wrapper = renderComponent(CommonSectionContainer, {
      props: {
        label: 'test-label',
      },
      slots: { default: '<div>hello world</div>' },
    })

    expect(wrapper.getByText('hello world')).toBeInTheDocument()
  })

  it('renders only the heading when slot is empty', () => {
    const wrapper = renderComponent(CommonSectionContainer, {
      props: {
        label: 'test-label',
      },
    })

    expect(wrapper.getByRole('region', { name: 'test-label' }).textContent?.trim()).toBe(
      'test-label',
    )
  })

  it('renders CommonLabel when noHeading is false', () => {
    const wrapper = renderComponent(CommonSectionContainer, {
      props: {
        label: 'test-label',
      },
    })

    const container = wrapper.getByRole('region')
    const heading = wrapper.getByRole('heading', { level: 2 })

    expect(heading).toBeInTheDocument()
    expect(heading).toHaveTextContent('test-label')

    expect(container).toHaveAttribute('aria-label', 'test-label')
  })

  it('hides CommonLabel when noHeading is true', () => {
    const wrapper = renderComponent(CommonSectionContainer, {
      props: {
        label: 'test-label',
        noHeading: true,
      },
    })

    const container = wrapper.getByRole('region', { name: 'test-label' })

    expect(container).toBeInTheDocument()
    expect(wrapper.queryByText('test-label')).toBeNull()

    expect(container).toHaveAttribute('aria-label', 'test-label')
  })
})
