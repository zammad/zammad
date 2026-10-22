// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Hook helper: list the findings a `fallow audit --format json` report attributes
//   to the branch, one per line. Inherited findings in touched files are left out:
//   they do not affect the verdict and are not the author's to fix.
// Exits 1 when the verdict is neither `fail` nor `warn` or the report attributes no
//   finding to the branch, so the hook stays silent; the second case prints why.

import { readFileSync } from 'node:fs'

const report = JSON.parse(readFileSync(process.argv[2], 'utf8'))

if (!['fail', 'warn'].includes(report.verdict)) process.exit(1)

const introduced = (findings) => (findings ?? []).filter((finding) => finding.introduced)

const location = (finding) => {
  if (finding.files) return finding.files.join(' -> ')
  return finding.line ? `${finding.path}:${finding.line}` : finding.path
}

const subject = (finding) =>
  finding.export_name ??
  finding.member_name ??
  finding.package_name ??
  finding.prop_name ??
  finding.emit_name ??
  finding.component_name ??
  ''

const severity = (finding) => `[${finding.effective_severity ?? finding.severity ?? 'error'}]`

const lines = []

for (const [category, findings] of Object.entries(report.dead_code ?? {})) {
  if (!Array.isArray(findings)) continue
  for (const finding of introduced(findings)) {
    lines.push(
      [category.replaceAll('_', '-'), location(finding), subject(finding), severity(finding)]
        .filter(Boolean)
        .join(' '),
    )
  }
}

for (const finding of introduced(report.complexity?.findings)) {
  lines.push(
    `complexity ${location(finding)} ${finding.name} cyclomatic=${finding.cyclomatic} cognitive=${finding.cognitive} ${severity(finding)}`,
  )
}

for (const group of introduced(report.duplication?.clone_groups)) {
  const instances = (group.instances ?? [])
    .map((instance) => `${instance.file}:${instance.start_line}-${instance.end_line}`)
    .join(', ')
  lines.push(`duplication ${instances}`)
}

if (lines.length === 0) {
  console.log(
    `verdict ${report.verdict} without a finding attributed to the branch, run \`pnpm analyse:fallow:audit\` for the full report`,
  )
  process.exit(1)
}

for (const line of lines) console.log(`  ${line}`)
