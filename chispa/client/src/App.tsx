import { useEffect, useState } from 'react'
import lzstring from 'lz-string'
import { useAnalysis } from './hooks/useAnalysis'
import { IdeaForm } from './components/IdeaForm'
import { ActivityFeed } from './components/ActivityFeed'
import { Dashboard } from './components/Dashboard'
import { ShareButton } from './components/ShareButton'
import type { AnalysisResult } from './types/analysis'

export default function App() {
  const { state, steps, result, error, submit } = useAnalysis()
  const [urlLoadError, setUrlLoadError] = useState<string | null>(null)
  const [lastIdea, setLastIdea] = useState<string>('')
  const [lastCountry, setLastCountry] = useState<string | undefined>(undefined)
  const [urlResult, setUrlResult] = useState<AnalysisResult | null>(null)

  // Auto-push URL when analysis completes (SHARE-01)
  useEffect(() => {
    if (result) {
      try {
        const encoded = lzstring.compressToEncodedURIComponent(JSON.stringify(result))
        window.history.replaceState({}, '', '/?r=' + encoded)
      } catch {
        // Compression failure — URL just won't update
      }
    }
  }, [result])

  // On mount: check for ?r= param and load a shared result directly
  useEffect(() => {
    const param = new URLSearchParams(window.location.search).get('r')
    if (!param) return

    try {
      const decompressed = lzstring.decompressFromEncodedURIComponent(param)
      if (!decompressed) throw new Error('Decompression returned empty string')
      const parsed = JSON.parse(decompressed) as AnalysisResult
      // Validate minimal shape — unknown verdict would crash VerdictCard
      if (
        !['LAUNCH', 'VALIDATE', 'PIVOT', 'AVOID'].includes(parsed.verdict) ||
        !Array.isArray(parsed.competitors) ||
        !Array.isArray(parsed.risks)
      ) {
        throw new Error('Resultado inválido en la URL')
      }
      // Load the shared result by submitting a synthetic complete state
      // We can't call setResult directly (it's encapsulated in the hook),
      // so we use a workaround: store the URL-loaded result in local state
      setUrlResult(parsed)
    } catch {
      setUrlLoadError('El enlace compartido no es válido o está corrupto.')
      // Clear the bad ?r= param from the URL without reloading
      window.history.replaceState({}, '', '/')
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // Determine what to display — URL-loaded result takes precedence over hook state
  const displayResult = urlResult ?? result
  const displayState = urlResult ? 'complete' : state
  // Form uses actual analysis state — keeps form enabled when viewing a URL-loaded result
  const formState = urlResult ? 'idle' : state

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="px-6 py-8 text-center">
        <h1 className="text-4xl font-black text-white tracking-tight mb-1">
          ✦ Chispa
        </h1>
        <p className="text-gray-400 text-base">Valida tu idea. En segundos.</p>
      </header>

      {/* Main content */}
      <main className="px-4 pb-16 max-w-4xl mx-auto space-y-6">

        {/* Error from corrupt ?r= param */}
        {urlLoadError && (
          <div role="alert" className="bg-red-950/30 border border-red-800 rounded-xl p-4 text-red-300 text-sm flex items-start justify-between gap-4">
            <span>{urlLoadError}</span>
            <button
              onClick={() => setUrlLoadError(null)}
              aria-label="Cerrar aviso de enlace inválido y volver al inicio"
              className="shrink-0 text-xs text-red-400 hover:text-red-200 underline underline-offset-2 transition-colors"
            >
              Volver al inicio
            </button>
          </div>
        )}

        {/* IdeaForm — always shown, disabled when streaming or complete */}
        <IdeaForm
          state={formState}
          onSubmit={(idea, country) => {
            setLastIdea(idea)
            setLastCountry(country)
            setUrlResult(null)
            // Clear the ?r= param immediately so a mid-stream refresh doesn't reload stale data
            window.history.replaceState({}, '', '/')
            submit(idea, country)
          }}
        />

        {/* Streaming state: activity feed + loading skeleton */}
        {displayState === 'streaming' && (
          <>
            <ActivityFeed steps={steps} />

            {/* Loading skeleton — suggests dashboard card layout while streaming */}
            <div className="w-full space-y-4 animate-pulse" aria-hidden="true">
              <div className="h-32 bg-surface border border-border rounded-xl" />
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="h-72 bg-surface border border-border rounded-xl" />
                <div className="h-72 bg-surface border border-border rounded-xl" />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="h-40 bg-surface border border-border rounded-xl" />
                <div className="h-40 bg-surface border border-border rounded-xl" />
              </div>
            </div>
          </>
        )}

        {/* Error state from analysis failure */}
        {displayState === 'error' && error && (
          <div role="alert" className="bg-red-950/30 border border-red-800 rounded-xl p-6 space-y-3">
            <p className="text-red-300 text-sm">{error}</p>
            {(error.startsWith('Error de conexión') || error.startsWith('Demasiados análisis en curso')) ? (
              <button
                onClick={() => submit(lastIdea, lastCountry)}
                disabled={!lastIdea}
                className="text-sm px-4 py-2 rounded-lg bg-surface border border-border text-gray-300 hover:border-primary hover:text-primary-light transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Reintentar
              </button>
            ) : (
              <p className="text-gray-500 text-xs">Ajusta tu idea e intenta de nuevo con el formulario de arriba.</p>
            )}
          </div>
        )}

        {/* Complete state: collapsed activity feed + full dashboard */}
        {displayState === 'complete' && displayResult && (
          <>
            {/* Collapsed activity feed — show step count only */}
            {steps.length > 0 && (
              <div className="text-xs text-gray-500 text-center">
                {steps.length} pasos de análisis completados
              </div>
            )}

            <div className="flex justify-end">
              <ShareButton />
            </div>

            <Dashboard result={displayResult} />
          </>
        )}
      </main>
    </div>
  )
}
