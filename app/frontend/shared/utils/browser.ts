// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import UAParser from 'ua-parser-js'

const parser = new UAParser()

export const browser = parser.getBrowser()

export const device = parser.getDevice()

export const os = parser.getOS()

export const generateFingerprint = () => {
  const windowResolution = `${window.screen.availWidth}x${window.screen.availHeight}/${window.screen.pixelDepth}`
  const timezone = new Date().toString().match(/\s\(.+?\)$/)?.[0]

  const getMajorVersion = (version?: string): string => {
    if (!version) return 'unknown'

    const versionParts = version.split('.')
    return versionParts[0]
  }

  const hashCode = (string: string) => {
    return string.split('').reduce((a, b) => {
      // eslint-disable-next-line no-bitwise
      a = (a << 5) - a + b.charCodeAt(0)
      // eslint-disable-next-line no-bitwise
      return a & a
    }, 0)
  }

  return hashCode(
    `${browser.name}${getMajorVersion(browser.version)}${
      os.name
    }${getMajorVersion(os.version)}${windowResolution}${timezone}`,
  ).toString()
}
