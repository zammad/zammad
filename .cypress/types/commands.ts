// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      matchImage(
        options?: Partial<{
          // screenshot configuration, passed directly to the the Cypress screenshot method: https://docs.cypress.io/api/cypress-api/screenshot-api#Arguments
          // default: { }
          screenshotConfig: Partial<Cypress.ScreenshotOptions>
          // pixelmatch options, see: https://www.npmjs.com/package/pixelmatch#pixelmatchimg1-img2-output-width-height-options
          // default: { includeAA: true }
          diffConfig: Partial<{
            // Matching threshold, ranges from 0 to 1. Smaller values make the comparison more sensitive. 0.1 by default.
            threshold: number
            // If true, disables detecting and ignoring anti-aliased pixels.
            includeAA: boolean
            // Blending factor of unchanged pixels in the diff output. Ranges from 0 for pure white to 1 for original brightness. 0.1 by default.
            alpha: number
            // The color of anti-aliased pixels in the diff output in [R, G, B] format. [255, 255, 0] by default.
            aaColor: [number, number, number]
            // The color of differing pixels in the diff output in [R, G, B] format. [255, 0, 0] by default.
            diffColor: [number, number, number]
            // An alternative color to use for dark on light differences to differentiate between "added" and "removed" parts. If not provided, all differing pixels use the color specified by diffColor. null by default.
            diffColorAlt: [number, number, number] | null
            // Draw the diff over a transparent background (a mask), rather than over the original image. Will not draw anti-aliased pixels (if detected).
            diffMask: boolean
          }>
          // whether to update images automatically, without making a diff - useful for CI
          // default: false
          updateImages: boolean
          // directory path in which screenshot images will be stored
          // image visualiser will normalise path separators depending on OS it's being run within, so always use / for nested paths
          // default: '__image_snapshots__'
          imagesDir: string
          // maximum threshold above which the test should fail
          // default: 0.01
          maxDiffThreshold: number
          // forces scale factor to be set as value "1"
          // helps with screenshots being scaled 2x on high-density screens like Mac Retina
          // default: true
          forceDeviceScaleFactor: boolean
          // title used for naming the image file
          // default: Cypress.currentTest.titlePath (your test title)
          title: string
        }>,
      ): Chainable<Subject>
      mount: typeof import('cypress/vue')['mount']
    }
  }
}

export {}
