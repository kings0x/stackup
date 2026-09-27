const COLORS: Record<string, string> = { NVDA: "#76b900", AAPL: "#c7c9cc", META: "#3b82f6", GOOGL: "#f59e0b" };
const STAGE_BG: Record<string, [string, string]> = {
  stacked: ["#101828", "#1d2939"],
  watching: ["#1a1407", "#3a2c07"],
  "at-risk": ["#1d0a0a", "#451717"],
};

export function portraitSvg(symbol: string, stage: string): string {
  const sym = (symbol || "STACK").slice(0, 6).toUpperCase();
  const [bg1, bg2] = STAGE_BG[stage] ?? STAGE_BG.stacked;
  const accent = COLORS[sym] ?? "#8b5cf6";
  const worried = stage === "at-risk";
  const eyes = worried ? "M150 205 q12 -10 24 0 M226 205 q12 -10 24 0" : "M150 200 q12 10 24 0 M226 200 q12 10 24 0";
  const mouth = worried ? "M185 260 q15 -12 30 0" : "M180 258 q20 14 40 0";
  const sweat = worried ? `<circle cx="255" cy="180" r="7" fill="#7dd3fc"/><circle cx="145" cy="180" r="5" fill="#7dd3fc"/>` : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="640" viewBox="0 0 400 400">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${bg1}"/><stop offset="1" stop-color="${bg2}"/></linearGradient></defs>
<rect width="400" height="400" fill="url(#g)"/>
<circle cx="200" cy="185" r="95" fill="#e8b98a"/>
<path d="M105 175 q-8 -90 95 -95 q103 5 95 95 l-14 4 q4 -70 -81 -72 q-85 2 -81 72 z" fill="#111827"/>
<rect x="105" y="118" width="190" height="44" rx="20" fill="#0b0e14"/>
<text x="200" y="148" text-anchor="middle" font-family="monospace" font-size="26" font-weight="bold" fill="${accent}">${sym}</text>
<rect x="272" y="118" width="34" height="16" rx="6" fill="#0b0e14"/>
<path d="${eyes}" stroke="#111827" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="${mouth}" stroke="#7c2d12" stroke-width="5" fill="none" stroke-linecap="round"/>
${sweat}
<rect x="120" y="280" width="160" height="10" rx="5" fill="none" stroke="${accent}" stroke-width="6"/>
<circle cx="200" cy="320" r="26" fill="none" stroke="${accent}" stroke-width="7"/>
<text x="200" y="329" text-anchor="middle" font-family="monospace" font-size="17" font-weight="bold" fill="${accent}">${sym}</text>
<text x="200" y="382" text-anchor="middle" font-family="monospace" font-size="15" fill="#9ca3af">STACKUP · ${stage.toUpperCase()}</text>
</svg>`;
}
