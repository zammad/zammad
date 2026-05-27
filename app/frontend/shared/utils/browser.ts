// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { UAParser } from 'ua-parser-js'

const parser = new UAParser()

export const browser = parser.getBrowser()

export const device = parser.getDevice()
export const isMobile = device.type === 'mobile'

export const os = parser.getOS()

export const generateFingerprint = () => {
  const windowResolution = `${window.screen.availWidth}x${window.screen.availHeight}/${window.screen.pixelDepth}`

  // The timezone identifier is extracted from the string representation of the current date.
  //   Recent versions of Node.js may include the GMT offset for UTC, e.g. ` (GMT+00:00)`.
  //   This is in contrast to previous versions, where the identifier was simply ` (GMT)`.
  //   We want to ensure that the same fingerprint is returned on both versions, hence this small compatibility layer.
  const timezoneIdentifier = new Date().toString().match(/\s\(.+?\)$/)?.[0]
  const timezone = timezoneIdentifier === ' (GMT+00:00)' ? ' (GMT)' : timezoneIdentifier

  const getMajorVersion = (version?: string): string => {
    if (!version) return 'unknown'

    const versionParts = version.split('.')
    return versionParts[0]
  }

  const hashCode = (string: string) =>
    string.split('').reduce((a, b) => {
      a = (a << 5) - a + b.charCodeAt(0)
      return a & a
    }, 0)

  return hashCode(
    `${browser.name}${getMajorVersion(browser.version)}${
      os.name
    }${getMajorVersion(os.version)}${windowResolution}${timezone}`,
  ).toString()
}
