# FEATURES.md — Startup Idea Validation Tool Research
# Chispa: LatAm-focused AI startup validator

Research date: 2026-05-26
Sources: WebSearch across 10+ queries, competitor product pages, ecosystem reports

---

## Market Context

The AI startup validator market is crowded in 2025-2026 with direct competitors including:
- **IdeaProof** (120s, TAM/SAM/SOM, Lean Canvas, brand assets, 10K+ users)
- **Preuve AI** (60s, 50+ live sources, sourced claims, $89 for 5-pack)
- **ValidatorAI** (conversational AI "Val", 200K+ users, $29/month, email follow-up)
- **WorthBuild** ($5/report, Go/Pivot/Stop verdict, unit economics)
- **ProductGapHunt** (SaaS-focused, gap analysis, indie hacker niche)
- **Mode: Idealist** (3-min, 3,400+ failed startup database, real competitor profiles)
- **Killswitch** (founder-market fit + willingness to pay + momentum + execution risk scoring)

No identified competitor is LatAm-specific or Spanish/Portuguese-first. This is a real gap.
(Confidence: MEDIUM — based on search results; no product directly advertising LatAm focus was found)

---

## Table Stakes

These are features users expect from any serious validator. Absence causes immediate abandonment.

### 1. Instant Verdict with Clear Label
**What:** A binary or small-set verdict label — LAUNCH / VALIDATE / PIVOT / AVOID (or equivalent GO / PIVOT / STOP / NO-GO). Users must leave knowing what to do.
**Why table stakes:** Every top competitor (WorthBuild, IdeaProof, Preuve AI, Killswitch, Mode: Idealist) produces a verdict label. Users validated this is the primary value they seek — "should I build this or not?"
**Confidence: HIGH** — verified across 5+ competitor products.

### 2. Competitor List with Real Companies
**What:** Named, real companies competing in the stated space — not generic categories. Minimum 3-5 named competitors with brief positioning.
**Why table stakes:** Preuve AI, ValidatorAI, IdeaProof, Mode: Idealist, and WorthBuild all do this. Users who get "no competitors found" or generic placeholders leave and don't return.
**Confidence: HIGH** — consistent across all sources.

### 3. Market Size Estimate (TAM)
**What:** A dollar figure for Total Addressable Market. Users want a number, not a range description. TAM/SAM/SOM is the gold standard; TAM alone is table stakes.
**Why table stakes:** 100% of competitors produce market sizing. Investors and founders both need this number to make a go/no-go call.
**Confidence: HIGH** — verified across all major competitors.

### 4. Speed Under 2 Minutes
**What:** Results returned within 90-120 seconds of submitting the idea.
**Why table stakes:** IdeaProof markets "120s," Preuve AI markets "60s," Mode: Idealist markets "3 minutes." Users have been conditioned to expect sub-2-minute results. Longer waits require a progress indicator or users assume it's broken.
**Confidence: HIGH** — multiple competitor marketing claims verified.

### 5. Risk Factors
**What:** Specific, named risk factors for the idea — not generic "market risk" platitudes. Risks tied to the specific idea (regulatory, timing, competition density, customer acquisition cost).
**Why table stakes:** All major competitors surface risks. Users cite risk identification as a primary reason to use validators before investing time and money.
**Confidence: HIGH** — consistent across competitor feature lists.

### 6. Actionable Next Steps
**What:** Concrete first actions — not "do market research" but "run 10 customer discovery interviews targeting [persona]" or "validate willingness-to-pay with a Stripe link before building."
**Why table stakes:** IdeaProof, WorthBuild, and ValidatorAI all produce first-step roadmaps. Users who get a verdict with no "what now?" feel stuck and rate the tool lower.
**Confidence: HIGH** — multiple sources confirm this as a user expectation.

### 7. No Login Required for Core Output
**What:** Users can submit an idea and receive the full validation output without creating an account.
**Why table stakes:** StartupsValidator, Feedough, and Inodash all offer no-login validation. Friction at the top of the funnel kills conversion. LatAm users in particular have higher drop-off rates with forced registration.
**Confidence: MEDIUM** — pattern observed across free-tier competitors; LatAm friction claim is inferred from general LatAm mobile-first adoption patterns, not a validated study.

### 8. Market Trend Signal (Growing / Shrinking / Flat)
**What:** A directional signal on market momentum — is this market expanding, mature, or contracting?
**Why table stakes:** Timing is one of the top 3 reasons startups fail (CB Insights). Users building in 2026 need to know if they're ahead, on time, or behind the wave.
**Confidence: MEDIUM** — inferred from competitor feature lists and CB Insights data cited in multiple sources; not all competitors make this explicit.

---

## Differentiators

Features that are rare or absent in the current market. Building these creates genuine separation.

### 1. LatAm-Specific Competitor Intelligence
**What:** When analyzing an idea, the tool explicitly searches for and surfaces LatAm-region competitors (Brazil, Mexico, Colombia, Argentina, Chile, etc.) — not just global players. Includes local players a global tool would miss.
**Why it differentiates:** No current competitor markets LatAm-specific competitor search. IdeaProof supports 18+ languages but does not advertise regional competitor intelligence. LatAm founders consistently underestimate local competition.
**Confidence: MEDIUM** — gap confirmed by search results; verified IdeaProof does not surface LatAm-specific competitor layers.

### 2. Spanish-First UI and Output
**What:** The product's default language is Spanish (with Portuguese option). Output reports are in Spanish. The verdict reason and first steps are written in clear Latin American Spanish (not Castilian).
**Why it differentiates:** Zero identified competitors are Spanish-first. ValidatorAI, IdeaProof, and Preuve AI are English-first. Language is a genuine barrier for non-English-fluent LatAm entrepreneurs.
**Confidence: MEDIUM** — language gap confirmed; user impact on LatAm founders is inferred from LatAm localization research, not user interview data.

### 3. Verdict Reason in Plain Language
**What:** The verdict (LAUNCH / VALIDATE / PIVOT / AVOID) comes with a 2-4 sentence explanation written for a first-time founder, not an MBA. No jargon. Specific to the submitted idea.
**Why it differentiates:** Most tools produce structured report sections. Few produce a conversational, frank explanation of "why this verdict." ValidatorAI is closest (conversational), but it's English-only and subscription-gated.
**Confidence: MEDIUM** — inferred from competitor UX observations; not validated with user interviews.

### 4. Market Timing Assessment ("Is Now the Right Time?")
**What:** Beyond market size, an explicit assessment of whether now is a good entry window — e.g., "regulation is tightening in this space, creating a 12-month window before incumbents adapt" or "this market is post-hype and consolidating."
**Why it differentiates:** No competitor explicitly surfaces a timing assessment as a named output field. CB Insights attributes 42% of startup failures to "no market need" — timing is a core subcomponent.
**Confidence: LOW** — gap inferred; needs user validation that this is a pain point distinct from market trend signal.

### 5. Stateless Architecture as Trust Signal
**What:** Explicitly communicate that no idea data is stored. "Your idea is not saved. We don't have a database." This is a feature, not just an implementation choice.
**Why it differentiates:** LatAm founders have documented distrust of data storage by US platforms (especially for pre-patent or pre-NDA ideas). Making statelessness a visible feature — not just a footnote — builds trust.
**Confidence: LOW** — LatAm trust concern is inferred from general LatAm market research; not validated through user interviews. Worth testing.

### 6. Grounded Claims (Source-Linked Intelligence)
**What:** When stating competitor names or market sizes, link to or cite the source (Crunchbase entry, Google Trends data, Statista report). Show the work.
**Why it differentiates:** Preuve AI does source-linking and markets it heavily. IdeaProof and ValidatorAI do not — their data is LLM-generated without external verification. Source-linking separates "trustworthy analysis" from "confident hallucination."
**Confidence: HIGH** — Preuve AI's differentiator is well-documented; hallucination risk in LLM-only validators is widely discussed.

---

## Anti-Features

Features to deliberately exclude. Building these wastes time, adds complexity, and degrades the core value proposition.

### 1. User Accounts and Saved History
**Exclude because:** The core constraint is statelessness. Accounts require auth infrastructure, session management, data storage, GDPR/LGPD compliance, and ongoing maintenance. None of this serves the "90-second verdict" value proposition. Users who want history can screenshot or download a PDF.
**Risk if built:** Adds 4-8 weeks of engineering for zero core-value gain. Creates data liability under Brazil's LGPD.

### 2. Lean Canvas Builder / Business Plan Generator
**Exclude because:** IdeaProof already does this and it competes on document creation, not insight quality. Chispa's value is the 90-second verdict — adding a Canvas builder extends session time, muddies the use case, and requires UI complexity that conflicts with speed.
**Risk if built:** Feature creep. Users come for a verdict, not a document editor.

### 3. AI Logo / Brand Identity / Visual Assets
**Exclude because:** IdeaProof offers this. It's a completely different job-to-be-done (brand design vs. idea validation). Adding it dilutes Chispa's positioning and creates scope that will never be done well alongside the core product.
**Risk if built:** Chispa becomes "another IdeaProof clone" rather than a focused validator.

### 4. Conversational / Multi-Turn Interview Flow
**Exclude because:** ValidatorAI's conversational "Val" approach takes longer, requires more user effort, and has dropout risk at each step. Chispa's 90-second constraint is a feature, not a limitation. The one-shot input model (describe your idea once → get output) is the right UX for time-pressed founders.
**Risk if built:** Contradicts the speed promise. Adds LLM conversation state management complexity.

### 5. Email Follow-Up / Nurture Sequences
**Exclude because:** ValidatorAI sends follow-up emails. This requires email collection, a marketing automation stack, and turns a validation tool into a lead funnel. Stateless means no contact capture.
**Risk if built:** Requires storing PII. Conflicts with stateless architecture. LatAm users distrust unsolicited email from unfamiliar platforms.

### 6. Social Sharing / Community / User Feed
**Exclude because:** No evidence in the research that users of validation tools want to share their unvalidated ideas publicly. Ideas are pre-competitive — sharing them before validation is a non-starter for most founders.
**Risk if built:** Privacy concern kills trust. Engineering cost with zero validated user demand.

### 7. Financial Projections / Revenue Modeling
**Exclude because:** WorthBuild and IdeaProof include unit economics and financial calculators. These require user inputs (pricing, CAC, LTV assumptions) which extend session time significantly. For a 90-second tool, this belongs in a separate, later-stage tool.
**Risk if built:** Forces the user to know their numbers before validating the idea — backwards from the use case. Session time balloons past the 120-second constraint.

### 8. Investor-Ready Report / Pitch Deck Export
**Exclude because:** IdeaProof markets this. It's a document generation feature that serves a different moment (fundraising prep, not idea validation). Chispa is for "should I build this?" not "how do I pitch this?"
**Risk if built:** Creates a document-formatting scope that never ends and pulls engineering from the core intelligence layer.

---

## Feature Priority for Chispa v1

Based on the research, the minimum feature set for Chispa to be competitive on day one:

**Must have (table stakes):**
- Verdict label (LAUNCH / VALIDATE / PIVOT / AVOID)
- Verdict reason in plain language (2-4 sentences)
- Competitors[] — named real companies, minimum 3
- Market size (TAM estimate with basis)
- Market growth signal (growing / flat / shrinking)
- Market timing assessment
- Risks[] — specific named risks, minimum 3
- First steps[] — concrete, not generic, minimum 3 actions
- Sub-120-second total response time
- No login required

**Must have for LatAm differentiation:**
- Spanish-first UI (Portuguese toggle as v2)
- LatAm competitor search layer in the research prompt
- Explicit statelessness as a visible trust signal

**Defer to later:**
- PDF export (v2)
- Portuguese UI (v2)
- Source citations / grounded claims (v2 — adds latency)
- Comparison of multiple ideas (v3)
