import { useState, useRef, useCallback } from 'react'
import type { SSEMessage, AnalysisResult } from '../types/analysis'

export type AppState = 'idle' | 'streaming' | 'complete' | 'error'

interface UseAnalysisReturn {
  state: AppState
  steps: Extract<SSEMessage, { type: 'step' }>[]
  result: AnalysisResult | null
  error: string | null
  submit: (idea: string, country?: string) => void
  abort: () => void
}

export function useAnalysis(): UseAnalysisReturn {
  const [state, setState] = useState<AppState>('idle')
  const [steps, setSteps] = useState<Extract<SSEMessage, { type: 'step' }>[]>([])
  const [result, setResult] = useState<AnalysisResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const abortControllerRef = useRef<AbortController | null>(null)

  const abort = useCallback(() => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort()
      abortControllerRef.current = null
    }
  }, [])

  const submit = useCallback((idea: string, country?: string) => {
    // Cancel any in-flight request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort()
    }

    const controller = new AbortController()
    abortControllerRef.current = controller

    // Reset state for new submission
    setState('streaming')
    setSteps([])
    setResult(null)
    setError(null)

    const run = async () => {
      try {
        const response = await fetch('/api/analyze', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ idea, country }),
          signal: controller.signal,
        })

        if (response.status === 429) {
          setError('Demasiados análisis en curso. Espera un momento e intenta de nuevo.')
          setState('error')
          return
        }

        if (!response.ok) {
          const text = await response.text()
          setError(`Error de servidor (${response.status}). Intenta de nuevo.`)
          setState('error')
          return
        }

        if (!response.body) {
          setError('No response body from server')
          setState('error')
          return
        }

        const reader = response.body.getReader()
        const decoder = new TextDecoder()
        let buffer = ''
        let hasResult = false

        while (true) {
          const { done, value } = await reader.read()
          if (done) break

          buffer += decoder.decode(value, { stream: true })
          const parts = buffer.split('\n\n')
          buffer = parts.pop()!

          for (const part of parts) {
            const trimmed = part.trim()
            if (!trimmed) continue

            for (const line of trimmed.split('\n')) {
              if (!line.startsWith('data: ')) continue
              const jsonStr = line.slice(6)

              let msg: SSEMessage
              try {
                msg = JSON.parse(jsonStr) as SSEMessage
              } catch {
                continue
              }

              if (msg.type === 'step') {
                setSteps((prev) => [...prev, msg as Extract<SSEMessage, { type: 'step' }>])
              } else if (msg.type === 'result') {
                hasResult = true
                // Validate minimal shape before accepting — Claude can return malformed JSON
                const data = msg.data
                if (!data || !data.verdict || !Array.isArray(data.competitors) || !Array.isArray(data.risks)) {
                  // Keep whatever partial data exists; show error so user knows it's incomplete
                  if (data) setResult(data)
                  setError('Análisis incompleto. Los datos no están en el formato esperado.')
                  setState('error')
                } else {
                  setResult(data)
                  setState('complete')
                }
              } else if (msg.type === 'error') {
                hasResult = true
                setError(msg.message)
                setState('error')
              }
              // type === 'ping': do nothing
            }
          }
        }

        if (!hasResult) {
          setError('El análisis no completó correctamente. Intenta de nuevo.')
          setState('error')
        }
      } catch (err) {
        // Silently swallow AbortError — React 18 StrictMode fires cleanup on first mount,
        // and users may call abort() explicitly. Neither case is an error.
        if (err instanceof Error && err.name === 'AbortError') return
        setError('Error de conexión. Intenta de nuevo.')
        setState('error')
      }
    }

    run()
  }, [])

  return { state, steps, result, error, submit, abort }
}
