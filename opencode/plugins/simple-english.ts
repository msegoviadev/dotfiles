import type { Plugin } from "@opencode-ai/plugin"
import { readFileSync, realpathSync } from "node:fs"
import { join } from "node:path"

const HEADER = [
  "SIMPLE ENGLISH SKILL ACTIVE AUTOMATICALLY",
  "",
  "Follow these writing rules without waiting for the user to name the skill. The full skill, with the rule catalog and the check mode, is at skills/simple-english/SKILL.md. Read it for a compliance check or for strict mode.",
  "",
].join("\n")

const FALLBACK = `SIMPLE ENGLISH SKILL ACTIVE AUTOMATICALLY

Apply ASD-STE100 Simplified Technical English to technical-writing tasks. Use short sentences, active voice, one term for one meaning, and conditions before commands. Do not change code, identifiers, commands, or quoted errors.`

function ruleBlock(content: string): string {
  const fence = /^---[ \t]*\r?$/m
  const first = content.search(fence)
  if (first === -1) return content.trim()
  const rest = content.slice(first).replace(fence, "")
  const second = rest.search(fence)
  return (second === -1 ? rest : rest.slice(0, second)).trim()
}

function loadRules(): string {
  try {
    const dir = realpathSync(import.meta.dir)
    const raw = readFileSync(join(dir, "..", "simple-english", "system-prompt.md"), "utf8")
    const rules = ruleBlock(raw)
    return rules || FALLBACK
  } catch {
    return FALLBACK
  }
}

const RULES = loadRules()

export const SimpleEnglishPlugin: Plugin = async () => ({
  "experimental.chat.system.transform": async (_input, output) => {
    try {
      output.system.push(HEADER + RULES)
    } catch {
      return
    }
  },
})
