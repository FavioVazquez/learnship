import type { Competitor } from '../types/analysis'

interface CompetitorCardProps {
  competitor: Competitor
}

export function CompetitorCard({ competitor }: CompetitorCardProps) {
  const { name, description, funding, website } = competitor

  return (
    <div className="bg-surface border border-border rounded-xl p-5 flex flex-col gap-3">
      {/* Header: favicon + name */}
      <div className="flex items-center gap-3">
        {website && (
          <img
            src={`https://www.google.com/s2/favicons?domain=${encodeURIComponent(website)}&sz=32`}
            alt=""
            width={28}
            height={28}
            className="rounded-sm flex-shrink-0"
            onError={(e) => {
              ;(e.target as HTMLImageElement).style.display = 'none'
            }}
          />
        )}
        <h4 className="font-semibold text-white text-base leading-tight">{name}</h4>
      </div>

      {/* Description */}
      <p className="text-gray-400 text-sm leading-relaxed">{description}</p>

      {/* Funding badge — only when present */}
      {funding && (
        <div className="mt-auto">
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-primary/20 text-primary-light border border-primary/30">
            {funding}
          </span>
        </div>
      )}
    </div>
  )
}
