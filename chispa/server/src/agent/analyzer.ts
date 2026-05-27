import Anthropic from '@anthropic-ai/sdk'
import type { AnalysisResult, SSEMessage } from '../types/analysis.js'

const client = new Anthropic({ timeout: 90_000 })

const SYSTEM_PROMPT = `Eres un analista de startups experto en mercados de Latinoamérica.

Tu tarea es analizar una idea de negocio usando búsqueda web para encontrar información REAL y actualizada — no inventes competidores ni datos de mercado.

Instrucciones:
1. Usa la herramienta de búsqueda web para encontrar competidores reales, tamaño de mercado y tendencias.
2. Si se especifica un país, prioriza competidores y contexto de mercado en Latinoamérica y especialmente en ese país.
3. Busca al menos 3-5 competidores directos con información verificable.
4. Evalúa el timing del mercado (too_early / right_time / too_late).
5. Identifica los principales riesgos con mitigaciones concretas.

Formato de respuesta:
Devuelve ÚNICAMENTE un objeto JSON válido, sin bloques de código markdown, sin explicaciones previas, sin texto después del JSON. El objeto debe tener exactamente esta forma:

{
  "competitors": [
    { "name": "...", "description": "...", "funding": "...", "founded": "...", "website": "..." }
  ],
  "marketSize": "...",
  "marketGrowth": "...",
  "marketTiming": "right_time",
  "risks": [
    { "title": "...", "severity": "high|medium|low", "mitigation": "...", "category": "Mercado|Competencia|Técnico|Regulatorio|Timing|Capital" }
  ],
  "verdict": "LAUNCH|VALIDATE|PIVOT|AVOID",
  "verdictReason": "...",
  "firstSteps": ["paso 1", "paso 2", "paso 3", "paso 4", "paso 5"],
  "searchedAt": ""
}

CRÍTICO: firstSteps debe contener EXACTAMENTE 5 elementos concretos y accionables. verdict debe ser exactamente uno de: LAUNCH, VALIDATE, PIVOT, AVOID. marketTiming debe ser exactamente uno de: too_early, right_time, too_late. Para cada riesgo, category debe ser exactamente uno de: Mercado, Competencia, Técnico, Regulatorio, Timing, Capital.`

const STEP_TEXTS = [
  'Buscando competidores directos...',
  'Analizando el mercado...',
  'Revisando actividad de inversión...',
  'Sintetizando resultados...',
]

export async function* analyzeIdea(
  idea: string,
  country?: string,
  signal?: AbortSignal
): AsyncGenerator<SSEMessage> {
  try {
    const countryContext = country
      ? `\n\nPaís objetivo: ${country}. Prioriza competidores y contexto de mercado en Latinoamérica, especialmente en ${country}.`
      : ''
    const userMessage = `Analiza esta idea de negocio:${countryContext}\n\n${idea}`

    const stream = client.messages.stream({
      model: 'claude-opus-4-7',
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      // web_search_20250305 is not yet in the SDK's tool type union
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      tools: [{ type: 'web_search_20250305', name: 'web_search' }] as any,
      messages: [{ role: 'user', content: userMessage }],
    }, { signal })

    let stepCount = 0

    for await (const event of stream) {
      if (
        event.type === 'content_block_start' &&
        event.content_block.type === 'tool_use'
      ) {
        const text = STEP_TEXTS[stepCount % STEP_TEXTS.length]
        stepCount++
        yield {
          type: 'step',
          text,
          source: event.content_block.name,
        }
      }
    }

    const finalMsg = await stream.finalMessage()

    if (finalMsg.stop_reason === 'max_tokens') {
      yield {
        type: 'error',
        message: 'El análisis fue demasiado largo. Intenta con una idea más concisa.',
      }
      return
    }

    const textBlocks = finalMsg.content.filter((b) => b.type === 'text')
    // Join ALL text blocks — web_search interleaves server_tool_use blocks between
    // text fragments, so .at(-1) only gets the last fragment (partial JSON).
    const rawText = textBlocks.map((b) => b.text).join('')

    // Extract the JSON object by finding the outermost braces — more reliable than
    // stripping markdown fences with regexes, which break when Claude adds preamble.
    const start = rawText.indexOf('{')
    const end = rawText.lastIndexOf('}')
    if (start === -1 || end === -1 || end < start) {
      throw new Error('No JSON object found in model response')
    }
    const cleaned = rawText.slice(start, end + 1)

    const result = JSON.parse(cleaned) as AnalysisResult

    // Runtime shape guard — TypeScript casts don't validate at runtime
    if (
      !['LAUNCH', 'VALIDATE', 'PIVOT', 'AVOID'].includes(result.verdict) ||
      !Array.isArray(result.competitors) ||
      !Array.isArray(result.risks) ||
      !Array.isArray(result.firstSteps) ||
      !result.marketTiming ||
      !result.marketSize
    ) {
      yield { type: 'error', message: 'Respuesta incompleta del modelo. Intenta de nuevo.' }
      return
    }

    if (!result.searchedAt) {
      result.searchedAt = new Date().toISOString()
    }

    yield { type: 'result', data: result }
  } catch (err: unknown) {
    // Ignore abort errors — client disconnected, no response needed.
    // The Anthropic SDK throws APIUserAbortError (not the native AbortError).
    if (err instanceof Error && (err.name === 'AbortError' || err.name === 'APIUserAbortError')) return

    const msg = err instanceof Error ? err.message : ''
    let userMessage = 'Error interno del servidor. Intenta de nuevo.'
    if (msg.includes('timeout') || msg.includes('timed out')) {
      userMessage = 'El análisis tardó demasiado. Intenta de nuevo.'
    } else if (msg.includes('No JSON object found') || msg.includes('JSON')) {
      userMessage = 'El modelo no devolvió un resultado válido. Intenta de nuevo.'
    } else if (msg.includes('rate_limit') || msg.includes('429')) {
      userMessage = 'El servicio de IA está saturado. Intenta en unos minutos.'
    }
    yield { type: 'error', message: userMessage }
  }
}
