// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/** The auto-stamped, customer-facing CSS contract attribute. */
export const MARKER_ATTRIBUTE: string

/** Qualify a name with its nearest PascalCase ancestor folder (else the bare name). */
export function qualifiedName(file: string): string

/** The marker value: plain component name, or qualified when the name is ambiguous. */
export function markerValue(file: string, ambiguousNames: Set<string>): string

/** File names used by more than one component able to render in the same app. */
export function findAmbiguousNames(files: string[]): Set<string>

/** Stamp one SFC's source; returns it unchanged when there is nothing to mark. */
export function stampSource(code: string, id: string, ambiguousNames?: Set<string>): string

interface SkinMarkerPlugin {
  name: string
  enforce: 'pre'
  transform(code: string, id: string): { code: string; map: null } | null
}

export default function skinMarkerPlugin(ambiguousNames?: Set<string>): SkinMarkerPlugin
