// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export default function toBeDescribedBy(
  this: any,
  received: unknown,
  expectedText: string,
) {
  if (!received || !(received instanceof HTMLElement)) {
    return {
      message: () => 'received is not an HTMLElement',
      pass: false,
    }
  }

  const notDescribedMessage = `expected element to be described by ${expectedText}`

  const describedById = received.getAttribute('aria-describedby')
  if (!describedById) {
    return {
      message: () => notDescribedMessage,
      pass: false,
    }
  }

  const descriptionElement = document.getElementById(describedById)
  const pass = descriptionElement?.textContent?.includes(expectedText)

  if (pass) {
    return {
      message: () => `expected element not to be described by ${expectedText}`,
      pass: true,
    }
  }

  return {
    message: () => notDescribedMessage,
    pass: false,
  }
}
