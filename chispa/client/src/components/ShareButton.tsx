import { useState } from 'react'

export function ShareButton() {
  const [copied, setCopied] = useState(false)

  const handleShare = () => {
    // URL is already set by App.tsx on completion — just copy it to clipboard
    navigator.clipboard.writeText(window.location.href).catch(() => {
      // Clipboard API may be blocked in non-HTTPS contexts; silently ignore
    })
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <button
      onClick={handleShare}
      aria-label={copied ? 'Enlace copiado al portapapeles' : 'Copiar enlace del análisis'}
      className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-surface border border-border text-gray-300 hover:border-primary hover:text-primary-light"
    >
      {copied ? (
        <>
          <span className="text-green-400" aria-hidden="true">✓</span>
          ¡Copiado!
        </>
      ) : (
        <>
          <span aria-hidden="true">↗</span>
          Compartir análisis
        </>
      )}
    </button>
  )
}
