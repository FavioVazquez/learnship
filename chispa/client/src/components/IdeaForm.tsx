import { useState, FormEvent } from 'react'
import { Loader2, ChevronDown } from 'lucide-react'
import type { AppState } from '../hooks/useAnalysis'

interface IdeaFormProps {
  state: AppState
  onSubmit: (idea: string, country?: string) => void
}

const COUNTRY_OPTIONS = [
  { value: '', label: 'Selecciona un país (opcional)' },
  { value: 'Guatemala', label: 'Guatemala' },
  { value: 'México', label: 'México' },
  { value: 'Colombia', label: 'Colombia' },
  { value: 'Argentina', label: 'Argentina' },
  { value: 'España', label: 'España' },
  { value: 'Otro', label: 'Otro' },
]

export function IdeaForm({ state, onSubmit }: IdeaFormProps) {
  const [idea, setIdea] = useState('')
  const [country, setCountry] = useState('')
  const [validationError, setValidationError] = useState<string | null>(null)

  const isDisabled = state === 'streaming' || state === 'complete'
  const isStreaming = state === 'streaming'
  const charCount = idea.length

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    setValidationError(null)

    if (idea.trim().length < 20) {
      setValidationError('Tu idea debe tener al menos 20 caracteres.')
      return
    }
    if (idea.trim().length > 500) {
      setValidationError('Tu idea no puede superar los 500 caracteres.')
      return
    }

    onSubmit(idea.trim(), country || undefined)
  }

  return (
    <form onSubmit={handleSubmit} className="w-full max-w-2xl mx-auto space-y-4">
      <div className="space-y-2">
        <label htmlFor="idea" className="block text-sm font-medium text-gray-300">
          Describe tu idea de negocio
        </label>
        <textarea
          id="idea"
          value={idea}
          onChange={(e) => setIdea(e.target.value)}
          disabled={isDisabled}
          minLength={20}
          maxLength={500}
          rows={5}
          placeholder="Ej: Una plataforma de delivery de comida saludable para oficinas en Ciudad de Guatemala, con suscripciones semanales y opciones veganas..."
          aria-describedby={validationError ? 'idea-error' : 'idea-counter'}
          aria-invalid={validationError ? 'true' : undefined}
          className="w-full bg-surface-elevated border border-border rounded-lg px-4 py-3 text-white placeholder-gray-600 resize-none focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent disabled:opacity-50 disabled:cursor-not-allowed transition-opacity"
        />
        <div className="flex flex-col gap-1 sm:flex-row sm:justify-between sm:items-center">
          <span
            id="idea-counter"
            className={`text-xs ${charCount < 20 ? 'text-gray-500' : charCount > 450 ? 'text-amber-400' : 'text-gray-400'}`}
            aria-live="polite"
          >
            {charCount}/500 caracteres
          </span>
          {validationError && (
            <span id="idea-error" role="alert" className="text-xs text-red-400">{validationError}</span>
          )}
        </div>
      </div>

      <div className="space-y-2">
        <label htmlFor="country" className="block text-sm font-medium text-gray-300">
          País objetivo
        </label>
        <div className="relative">
          <select
            id="country"
            value={country}
            onChange={(e) => setCountry(e.target.value)}
            disabled={isDisabled}
            className="w-full bg-surface-elevated border border-border rounded-lg px-4 py-3 pr-10 text-white focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent disabled:opacity-50 disabled:cursor-not-allowed appearance-none"
          >
            {COUNTRY_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          <ChevronDown
            className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none"
            aria-hidden="true"
          />
        </div>
      </div>

      <button
        type="submit"
        disabled={isDisabled}
        aria-busy={isStreaming}
        aria-label={isStreaming ? 'Analizando tu idea, por favor espera' : undefined}
        className="w-full bg-primary hover:brightness-110 disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-all flex items-center justify-center gap-2"
      >
        {isStreaming ? (
          <>
            <Loader2 className="w-5 h-5 animate-spin" aria-hidden="true" />
            Analizando...
          </>
        ) : (
          'Analizar mi idea'
        )}
      </button>
    </form>
  )
}
