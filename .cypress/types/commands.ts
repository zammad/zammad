// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Cypress {
    interface Chainable<Subject> {
      /**
       * Simulates a paste event.
       * Modified from https://gist.github.com/nickytonline/bcdef8ef00211b0faf7c7c0e7777aaf6
       *
       * @param subject A jQuery context representing a DOM element.
       * @param pasteOptions Set of options for a simulated paste event.
       * @param pasteOptions.pastePayload Simulated data that is on the clipboard.
       * @param pasteOptions.pasteFormat The format of the simulated paste payload. Default value is 'text'.
       * @param pasteOptions.files A list of assisiated file, if any
       *
       * @returns The subject parameter.
       *
       * @example
       * cy.get('body').paste({
       *   pasteType: 'application/json',
       *   pastePayload: {hello: 'yolo'},
       * });
       */
      paste(options: {
        pastePayload?: string
        pasteFormat?: string
        files?: File[]
      }): Chainable<Subject>
      selectText(direction: 'left' | 'right', size: number): Chainable<Subject>
      matchImageSnapshot(
        options?: Partial<Loggable & Timeoutable & ScreenshotOptions>,
      ): Chainable<null>
      matchImageSnapshot(
        fileName: string,
        options?: Partial<Loggable & Timeoutable & ScreenshotOptions>,
      ): Chainable<null>
      mount: typeof import('cypress/vue')['mount']
    }
  }
}

export {}
