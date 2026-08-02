import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

export const plugin: Plugin = async (ctx) => {
  return {
    tool: {
      fetch_original_prompt: tool({
        description: "Fetch the original human prompt from an OpenCode session. Returns the verbatim text, detected language, and metadata. Read-only, does not modify any state.",
        args: {
          session_id: tool.schema.string().describe("The session ID to fetch the original prompt from"),
          message_index: tool.schema.number().optional().describe("Which user message to fetch (0 = first human message, which is typically the original prompt). Defaults to 0."),
          target_language: tool.schema.string().optional().describe("ISO 639-1 code for the desired translation language (e.g., 'en', 'es'). Translation is handled by the calling subagent, not this tool."),
        },
        async execute(args) {
          const sessionID = args.session_id
          const messageIndex = args.message_index ?? 0

          try {
            const response = await ctx.client.session.messages({
              path: { id: sessionID },
            })

            const allMessages = response.data ?? []
            const userMessages = allMessages.filter(
              (m) => m.info.role === "user"
            )

            if (userMessages.length === 0) {
              return JSON.stringify({
                status: "not_found",
                original_language: null,
                original_text: null,
                translated_text: null,
                source: "plugin:prompt-fetcher",
                error: "No user messages found in session",
              })
            }

            if (messageIndex >= userMessages.length) {
              return JSON.stringify({
                status: "not_found",
                original_language: null,
                original_text: null,
                translated_text: null,
                source: "plugin:prompt-fetcher",
                error: `Message index ${messageIndex} out of range (only ${userMessages.length} user messages in session)`,
              })
            }

            const targetMessage = userMessages[messageIndex]

            if (!targetMessage) {
              return JSON.stringify({
                status: "not_found",
                original_language: null,
                original_text: null,
                translated_text: null,
                source: "plugin:prompt-fetcher",
                error: `Message index ${messageIndex} resolved to no message`,
              })
            }

            const textParts = targetMessage.parts.filter(
              (p) => p.type === "text"
            )
            const originalText = textParts.map((p) => p.text).join("\n")

            if (!originalText || originalText.trim().length === 0) {
              return JSON.stringify({
                status: "not_found",
                original_language: null,
                original_text: null,
                translated_text: null,
                source: "plugin:prompt-fetcher",
                error: "Message contains no text parts",
              })
            }

            // Simple language detection heuristic
            const language = detectLanguage(originalText)

            return JSON.stringify({
              status: "ok",
              original_language: language,
              original_text: originalText,
              translated_text: null,
              source: "plugin:prompt-fetcher",
            })
          } catch (error) {
            const reason = error instanceof Error ? error.message : String(error)
            return JSON.stringify({
              status: "error",
              original_language: null,
              original_text: null,
              translated_text: null,
              source: "plugin:prompt-fetcher",
              error: reason,
            })
          }
        },
      }),
    },
  }
}

function detectLanguage(text: string): string {
  // Simple heuristic based on common words/patterns
  const sample = text.slice(0, 500).toLowerCase()

  const spanishIndicators = [
    " el ", " la ", " los ", " las ", " de ", " del ", " en ", " que ",
    " por ", " con ", " una ", " para ", " como ", " pero ", " más ",
    " este ", " esta ", " estos ", " estas ", " ese ", " esa ",
    " necesito ", " quiero ", " puedo ", " hacer ", " tiene ",
    " está ", " son ", " es ", " hay ", " fue ",
  ]

  const englishIndicators = [
    " the ", " is ", " are ", " was ", " were ", " have ", " has ",
    " this ", " that ", " with ", " from ", " they ", " been ",
    " need ", " want ", " can ", " make ", " will ", " would ",
  ]

  let spanishScore = 0
  let englishScore = 0

  for (const indicator of spanishIndicators) {
    if (sample.includes(indicator)) spanishScore++
  }
  for (const indicator of englishIndicators) {
    if (sample.includes(indicator)) englishScore++
  }

  // Check for accented characters (strong Spanish signal)
  if (/[áéíóúñ¿¡]/.test(sample)) spanishScore += 3

  if (spanishScore > englishScore + 2) return "es"
  if (englishScore > spanishScore + 2) return "en"
  return "unknown"
}
