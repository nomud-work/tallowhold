"""Tallowhold: 1980s Japanese anime-style HUMAN characters as SVG.
viewBox 0 0 200 280 (taller for human proportions). Feet near y=268.
Flame drawn separately for flicker. Cel-shaded: flat fills + hard shadow wedges."""
O = "#1a1010"  # bold outline
SW = 5.5

def g(id, a, b, x2="0%", y2="100%"):
    return (f'<linearGradient id="{id}" x1="0%" y1="0%" x2="{x2}" y2="{y2}">'
            f'<stop offset="0%" stop-color="{a}"/><stop offset="100%" stop-color="{b}"/></linearGradient>')

def defs(*xs):
    return "<defs>" + "".join(xs) + "</defs>"

def eyes(cx, cy, gap=28, rx=11, ry=14, look=3.5, iris="#3a5a9a", lashes=True, angry=False):
    """Big 80s anime eyes with white highlight and lower shine."""
    s = ""
    for side, dx in (("L", -gap/2), ("R", gap/2)):
        x = cx + dx
        # upper lid arc
        if angry:
            s += f'<path d="M{x-rx-1} {cy-ry+2} Q{x} {cy-ry-6} {x+rx+1} {cy-ry+4}" stroke="{O}" stroke-width="4" fill="none" stroke-linecap="round"/>'
        # white
        s += f'<ellipse cx="{x}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#fff" stroke="{O}" stroke-width="3.5"/>'
        # iris
        s += f'<ellipse cx="{x+look}" cy="{cy+1}" rx="{rx*0.62}" ry="{ry*0.7}" fill="{iris}"/>'
        # pupil
        s += f'<ellipse cx="{x+look}" cy="{cy+2}" rx="{rx*0.28}" ry="{ry*0.38}" fill="#0c0810"/>'
        # big top highlight
        s += f'<circle cx="{x+look-rx*0.28}" cy="{cy-ry*0.32}" r="{rx*0.28}" fill="#fff"/>'
        # small lower highlight
        s += f'<circle cx="{x+look+rx*0.2}" cy="{cy+ry*0.25}" r="{rx*0.1}" fill="#fff" opacity="0.85"/>'
        if lashes:
            s += (f'<path d="M{x-rx-2} {cy-ry*0.3} L{x-rx-8} {cy-ry*0.55}" stroke="{O}" stroke-width="2.8" stroke-linecap="round"/>'
                  f'<path d="M{x-rx} {cy-ry*0.55} L{x-rx-5} {cy-ry*0.9}" stroke="{O}" stroke-width="2.5" stroke-linecap="round"/>')
    return s

def mouth(cx, cy, kind="smile"):
    if kind == "grin":
        return (f'<path d="M{cx-10} {cy} Q{cx} {cy+10} {cx+10} {cy}" fill="#7a2430" stroke="{O}" stroke-width="3" stroke-linejoin="round"/>'
                f'<path d="M{cx-6} {cy+3} Q{cx} {cy+7} {cx+6} {cy+3}" fill="#ff8a9a"/>')
    if kind == "smirk":
        return f'<path d="M{cx-4} {cy} Q{cx+4} {cy+5} {cx+12} {cy-1}" fill="none" stroke="{O}" stroke-width="3.2" stroke-linecap="round"/>'
    if kind == "open":
        return (f'<ellipse cx="{cx}" cy="{cy+3}" rx="7" ry="6" fill="#7a2430" stroke="{O}" stroke-width="3"/>'
                f'<path d="M{cx-4} {cy+1} Q{cx} {cy-1} {cx+4} {cy+1}" fill="#ff8a9a"/>')
    if kind == "fierce":
        return f'<path d="M{cx-8} {cy+2} L{cx+8} {cy}" stroke="{O}" stroke-width="3.2" stroke-linecap="round"/>'
    return f'<path d="M{cx-9} {cy} Q{cx} {cy+7} {cx+9} {cy}" fill="none" stroke="{O}" stroke-width="3.2" stroke-linecap="round"/>'

def nose(cx, cy):
    return f'<path d="M{cx} {cy} L{cx+3} {cy+6}" stroke="{O}" stroke-width="2.2" stroke-linecap="round"/>'

def blush(cx, cy, gap=46):
    return (f'<ellipse cx="{cx-gap/2}" cy="{cy}" rx="8" ry="4" fill="#ff8a8a" opacity="0.45"/>'
            f'<ellipse cx="{cx+gap/2}" cy="{cy}" rx="8" ry="4" fill="#ff8a8a" opacity="0.45"/>')

def flame_svg(cx, base_y, h=36, kind="warm"):
    w = h * 0.58
    if kind == "warm":
        a, b, c, e = "#ff6a18", "#ffb020", "#fff0b0", "#8a3008"
    else:
        a, b, c, e = "#2aa8ff", "#8fe0ff", "#f0fcff", "#184a7a"
    def drop(s, col, stroke=None):
        hh, ww = h*s, w*s
        top = base_y - hh
        st = f' stroke="{stroke}" stroke-width="3.5"' if stroke else ""
        return (f'<path d="M{cx} {top} C{cx+ww*0.35} {top+hh*0.28} {cx+ww*0.55} {top+hh*0.55} {cx+ww*0.48} {base_y-ww*0.4} '
                f'A{ww*0.48} {ww*0.48} 0 0 1 {cx-ww*0.48} {base_y-ww*0.4} C{cx-ww*0.55} {top+hh*0.55} {cx-ww*0.2} {top+hh*0.32} {cx} {top} Z" fill="{col}"{st}/>')
    return drop(1.0, a, e) + drop(0.7, b) + drop(0.4, c)

def wick(x, y0, y1):
    return (f'<path d="M{x} {y0} L{x} {y1}" stroke="{O}" stroke-width="6" stroke-linecap="round"/>'
            f'<path d="M{x} {y0} L{x} {y1}" stroke="#6a4020" stroke-width="2.8" stroke-linecap="round"/>')

def shade(pts, col="#000", op=0.18):
    return f'<path d="{pts}" fill="{col}" opacity="{op}"/>'

CHARS = {}
def char(name, family, flame=None):
    def deco(fn):
        CHARS[name] = (fn, family, flame); return fn
    return deco

# ========== WAX ==========
@char("tallowguard", "WAX", (100, 42, 34, "warm"))
def tallowguard():
    # Woman knight: cream cloak, amber shield, blonde hair, sword
    return (defs(g("tg_skin","#ffe4c8","#f0c09a"), g("tg_cloak","#fff6e0","#e8c98a"), g("tg_hair","#ffe08a","#d4a030")) +
        # boots
        f'<path d="M72 248 L68 268 L90 268 L92 248 Z" fill="#5a3820" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M118 248 L116 268 L140 268 L136 248 Z" fill="#5a3820" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        # legs
        f'<path d="M78 200 L74 248 L96 248 L98 200 Z" fill="#c4a070" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M112 200 L110 248 L134 248 L130 200 Z" fill="#c4a070" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M112 200 L110 248 L122 248 L124 200 Z") +
        # tunic
        f'<path d="M70 118 L130 118 L138 200 L68 200 Z" fill="url(#tg_cloak)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 118 L130 118 L138 200 L118 200 Z") +
        # belt
        f'<rect x="72" y="168" width="62" height="12" rx="2" fill="#8a5a28" stroke="{O}" stroke-width="3.5"/>'
        f'<rect x="96" y="166" width="14" height="16" rx="2" fill="#d4a040" stroke="{O}" stroke-width="3"/>'
        # breastplate
        f'<path d="M78 120 L122 120 L126 160 L74 160 Z" fill="#e8d0a0" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>'
        f'<path d="M84 128 L116 128 L118 150 L82 150 Z" fill="#f5e6c0"/>'
        # cloak billow
        f'<path d="M70 118 Q40 140 48 210 Q55 230 70 200" fill="#f2e0b8" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M48 180 Q55 210 68 200 Q50 190 48 180 Z", op=0.22) +
        # arms
        f'<path d="M70 130 Q48 150 52 190" stroke="{O}" stroke-width="16" fill="none" stroke-linecap="round"/>'
        f'<path d="M70 130 Q48 150 52 190" stroke="#ffe4c8" stroke-width="9" fill="none" stroke-linecap="round"/>'
        f'<path d="M130 130 Q160 145 168 120" stroke="{O}" stroke-width="16" fill="none" stroke-linecap="round"/>'
        f'<path d="M130 130 Q160 145 168 120" stroke="#ffe4c8" stroke-width="9" fill="none" stroke-linecap="round"/>'
        # shield
        f'<circle cx="54" cy="178" r="32" fill="#d4903a" stroke="{O}" stroke-width="{SW}"/>'
        f'<circle cx="54" cy="178" r="22" fill="#e8a858" stroke="#8a4a18" stroke-width="3"/>'
        f'<circle cx="54" cy="178" r="8" fill="#f5c878"/>'
        f'<path d="M38 160 Q48 154 58 158" stroke="#fff" stroke-width="3.5" fill="none" opacity="0.5"/>'
        # sword
        f'<path d="M168 118 L172 70" stroke="{O}" stroke-width="10" stroke-linecap="round"/>'
        f'<path d="M168 118 L172 70" stroke="#d8e0f0" stroke-width="5" stroke-linecap="round"/>'
        f'<path d="M160 118 L180 118" stroke="{O}" stroke-width="6" stroke-linecap="round"/>'
        f'<path d="M160 118 L180 118" stroke="#c09040" stroke-width="3" stroke-linecap="round"/>'
        # neck + head
        f'<rect x="90" y="100" width="20" height="20" fill="#ffe4c8" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="78" rx="34" ry="36" fill="url(#tg_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 48 Q128 60 130 90 Q120 100 100 100 Z") +
        # hair back
        f'<path d="M68 70 Q55 110 62 160 Q70 170 78 140 Q72 100 78 70 Z" fill="url(#tg_hair)" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>' +
        f'<path d="M132 70 Q145 110 138 160 Q130 170 122 140 Q128 100 122 70 Z" fill="url(#tg_hair)" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>'
        # hair top / bangs
        f'<path d="M66 78 Q70 40 100 32 Q130 40 134 78 Q120 58 100 56 Q80 58 66 78 Z" fill="url(#tg_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M78 70 Q90 58 100 68 Q110 58 122 70" fill="url(#tg_hair)" stroke="{O}" stroke-width="3" stroke-linejoin="round"/>' +
        wick(100, 40, 32) +
        eyes(100, 78, 30, 11, 13, 3.5, "#4a6aaa", True, False) + nose(102, 88) + blush(100, 96) + mouth(100, 102, "smile")
    )

@char("wickthrower", "WAX", (98, 38, 32, "warm"))
def wickthrower():
    return (defs(g("wt_skin","#ffd8b8","#e8b088"), g("wt_hair","#6a3020","#3a1810"), g("wt_tunic","#f5e6c8","#d8b878")) +
        f'<path d="M78 250 L74 268 L96 268 L98 250 Z" fill="#4a3020" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M114 248 L118 268 L140 268 L132 246 Z" fill="#4a3020" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M82 198 L78 250 L100 250 L102 198 Z" fill="#a08060" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M110 196 L114 248 L136 246 L128 196 Z" fill="#a08060" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M72 110 L128 108 L134 198 L70 200 Z" fill="url(#wt_tunic)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 108 L128 108 L134 198 L116 200 Z") +
        f'<path d="M70 130 Q130 145 132 160" stroke="#c07030" stroke-width="10" fill="none" stroke-linecap="round"/>'
        f'<path d="M70 130 Q130 145 132 160" stroke="#e09050" stroke-width="5" fill="none" stroke-linecap="round"/>'
        f'<path d="M55 175 Q70 200 85 185 L95 210 Q70 220 48 200 Z" fill="#6a4020" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>'
        f'<path d="M72 120 Q40 155 55 200" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M72 120 Q40 155 55 200" stroke="#ffd8b8" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M128 118 Q165 100 170 60" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M128 118 Q165 100 170 60" stroke="#ffd8b8" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M172 62 L176 30" stroke="{O}" stroke-width="7" stroke-linecap="round"/>'
        f'<path d="M172 62 L176 30" stroke="#c09050" stroke-width="3" stroke-linecap="round"/>' +
        flame_svg(176, 32, 22) +
        f'<rect x="88" y="96" width="22" height="16" fill="#ffd8b8" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="74" rx="32" ry="34" fill="url(#wt_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 46 Q126 58 128 86 Q118 96 100 96 Z") +
        f'<path d="M70 78 Q65 50 100 36 Q135 50 130 78 Q120 55 100 52 Q80 55 70 78 Z" fill="url(#wt_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M128 80 Q150 120 142 170 Q130 180 124 150 Q132 110 120 80 Z" fill="url(#wt_hair)" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>' +
        f'<path d="M78 68 Q90 58 100 66 Q110 56 122 68" fill="url(#wt_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 40, 32) +
        eyes(100, 74, 28, 10, 12, 3.5, "#5a3a20", True) + nose(102, 84) + mouth(100, 96, "grin")
    )

@char("drip_matron", "WAX", (100, 48, 34, "warm"))
def drip_matron():
    return (defs(g("dm_skin","#ffe8d0","#f0c8a0"), g("dm_robe","#fff8ec","#e8d0a8"), g("dm_hair","#8a5a30","#5a3018")) +
        f'<path d="M55 248 Q50 268 70 268 L130 268 Q150 268 145 248 Z" fill="#6a4830" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M58 130 L142 130 Q160 180 155 250 L45 250 Q40 180 58 130 Z" fill="url(#dm_robe)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 130 L142 130 Q160 180 155 250 L120 250 Z") +
        f'<path d="M48 200 Q70 188 90 200 Q110 188 130 200 Q150 188 155 205" stroke="#c8a878" stroke-width="4" fill="none"/>'
        f'<path d="M70 140 Q40 160 55 210" stroke="{O}" stroke-width="16" fill="none" stroke-linecap="round"/>'
        f'<path d="M70 140 Q40 160 55 210" stroke="#ffe8d0" stroke-width="9" fill="none" stroke-linecap="round"/>'
        f'<path d="M130 140 Q160 160 145 210" stroke="{O}" stroke-width="16" fill="none" stroke-linecap="round"/>'
        f'<path d="M130 140 Q160 160 145 210" stroke="#ffe8d0" stroke-width="9" fill="none" stroke-linecap="round"/>'
        # baby waxling
        f'<ellipse cx="100" cy="195" rx="22" ry="26" fill="#fff6e8" stroke="{O}" stroke-width="4.5"/>'
        f'<circle cx="92" cy="190" r="3" fill="{O}"/><circle cx="108" cy="190" r="3" fill="{O}"/>'
        f'<path d="M94 200 q6 5 12 0" stroke="{O}" stroke-width="2.5" fill="none" stroke-linecap="round"/>'
        f'<path d="M100 174 L100 168" stroke="#6a4020" stroke-width="3" stroke-linecap="round"/>' +
        flame_svg(100, 168, 14) +
        f'<rect x="88" y="112" width="24" height="20" fill="#ffe8d0" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="86" rx="36" ry="38" fill="url(#dm_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 54 Q130 68 132 100 Q118 112 100 112 Z") +
        f'<path d="M64 90 Q58 55 100 42 Q142 55 136 90 Q125 62 100 60 Q75 62 64 90 Z" fill="url(#dm_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<ellipse cx="100" cy="55" rx="16" ry="12" fill="url(#dm_hair)" stroke="{O}" stroke-width="4"/>' +
        f'<path d="M78 78 Q90 68 100 76 Q110 66 122 78" fill="url(#dm_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 46, 38) +
        eyes(100, 86, 32, 12, 14, 2.5, "#5a3a28", True) + nose(102, 98) + blush(100, 106, 52) + mouth(100, 112, "smile")
    )

@char("waxling", "WAX", (100, 88, 28, "warm"))
def waxling():
    return (defs(g("wx_skin","#fff4e4","#f0d8b0"), g("wx_hair","#fff0c8","#e0c070")) +
        f'<ellipse cx="82" cy="262" rx="16" ry="8" fill="#e8d0a0" stroke="{O}" stroke-width="4"/>'
        f'<ellipse cx="118" cy="262" rx="16" ry="8" fill="#e8d0a0" stroke="{O}" stroke-width="4"/>'
        f'<path d="M70 180 Q65 260 82 262 L118 262 Q135 260 130 180 Z" fill="#fff8ec" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 180 L130 180 Q135 260 118 262 L110 250 Z") +
        f'<ellipse cx="100" cy="140" rx="40" ry="48" fill="url(#wx_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 100 Q132 120 130 160 Q115 175 100 175 Z") +
        f'<path d="M62 140 Q55 100 100 85 Q145 100 138 140 Q125 110 100 108 Q75 110 62 140 Z" fill="url(#wx_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M75 128 Q90 112 100 124 Q110 110 125 128" fill="url(#wx_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 90, 82) +
        eyes(100, 145, 36, 14, 17, 2.5, "#5a3a20", True) + nose(102, 160) + blush(100, 168, 56) + mouth(100, 175, "open")
    )

# ========== FLAME ==========
@char("sparkrunner", "FLAME", (96, 40, 34, "warm"))
def sparkrunner():
    return (defs(g("sr_skin","#ffd0b0","#e8a080"), g("sr_hair","#ff6020","#c02010"), g("sr_fit","#ff8040","#d04020")) +
        f'<path d="M70 248 L55 268 L80 268 L85 248 Z" fill="#5a2010" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M120 245 L135 265 L158 258 L140 242 Z" fill="#5a2010" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M78 195 L70 248 L92 248 L98 195 Z" fill="#c05030" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M112 192 L120 245 L142 242 L130 190 Z" fill="#c05030" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M72 108 L128 105 L134 195 L70 198 Z" fill="url(#sr_fit)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 105 L128 105 L134 195 L116 198 Z") +
        f'<rect x="70" y="95" width="62" height="14" rx="3" fill="#b01018" stroke="{O}" stroke-width="4"/>'
        f'<path d="M70 102 Q40 95 28 110 Q45 112 38 125 Q55 108 70 108 Z" fill="#b01018" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>'
        f'<path d="M72 125 Q38 155 48 195" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M72 125 Q38 155 48 195" stroke="#ffd0b0" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M128 120 Q165 130 175 115" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M128 120 Q165 130 175 115" stroke="#ffd0b0" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M175 118 L195 95 L185 125 Z" fill="#fff0a0" stroke="#b06010" stroke-width="3.5" stroke-linejoin="round"/>'
        f'<circle cx="198" cy="90" r="3" fill="#ffe66b"/><circle cx="188" cy="82" r="2" fill="#ffe66b"/>'
        f'<rect x="88" y="92" width="22" height="16" fill="#ffd0b0" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="70" rx="32" ry="34" fill="url(#sr_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 42 Q126 55 128 82 Q116 92 100 92 Z") +
        f'<path d="M68 75 Q50 40 100 28 Q150 40 132 75 Q145 100 155 130 Q140 120 128 90 Q130 55 100 50 Q72 55 68 75 Z" fill="url(#sr_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M78 65 Q90 52 100 62 Q110 50 122 65" fill="url(#sr_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 36, 28) +
        eyes(102, 70, 28, 10, 12, 4, "#6a2010", True, True) + nose(104, 80) + mouth(102, 92, "fierce")
    )

@char("fusepot", "FLAME", (118, 48, 30, "warm"))
def fusepot():
    return (defs('<radialGradient id="fp" cx="38%" cy="32%" r="70%"><stop offset="0%" stop-color="#ff7050"/><stop offset="100%" stop-color="#b02818"/></radialGradient>',
                 g("fp_skin","#ffd0b0","#e8a080")) +
        f'<ellipse cx="78" cy="258" rx="18" ry="10" fill="#8a2818" stroke="{O}" stroke-width="4"/>'
        f'<ellipse cx="122" cy="258" rx="18" ry="10" fill="#8a2818" stroke="{O}" stroke-width="4"/>'
        f'<path d="M78 220 L70 258 L90 258 L95 220 Z" fill="#c04028" stroke="{O}" stroke-width="4"/>'
        f'<path d="M118 220 L122 258 L142 258 L130 220 Z" fill="#c04028" stroke="{O}" stroke-width="4"/>'
        f'<circle cx="100" cy="165" r="58" fill="url(#fp)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 120 Q145 140 145 180 Q130 210 100 210 Z") +
        f'<ellipse cx="78" cy="145" rx="14" ry="10" fill="#fff" opacity="0.35" transform="rotate(-25 78 145)"/>'
        f'<rect x="82" y="95" width="36" height="20" rx="4" fill="#8a2010" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M100 98 Q100 70 118 72 Q130 78 126 58" stroke="{O}" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M100 98 Q100 70 118 72 Q130 78 126 58" stroke="#a87840" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
        f'<ellipse cx="100" cy="125" rx="34" ry="32" fill="url(#fp_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 100 Q128 112 128 135 Q115 148 100 148 Z") +
        eyes(102, 122, 30, 11, 12, 3.5, "#5a2010", True, True) + nose(104, 132) +
        f'<path d="M84 145 Q104 162 124 145 Z" fill="#fff" stroke="{O}" stroke-width="3.5" stroke-linejoin="round"/>'
        f'<path d="M92 148 v6 M104 150 v8 M116 148 v6" stroke="{O}" stroke-width="2"/>'
    )

@char("flarecaster", "FLAME", (100, 36, 34, "warm"))
def flarecaster():
    return (defs(g("fc_skin","#ffd8b8","#e8b088"), g("fc_robe","#ffd050","#e08820"), g("fc_hair","#c05020","#8a2810")) +
        f'<path d="M78 250 L74 268 L98 268 L100 250 Z" fill="#6a3810" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M112 250 L110 268 L134 268 L130 250 Z" fill="#6a3810" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M80 200 L76 250 L102 250 L104 200 Z" fill="#c07030" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M110 200 L108 250 L134 250 L130 200 Z" fill="#c07030" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M68 105 L132 105 L138 205 L64 205 Z" fill="url(#fc_robe)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 105 L132 105 L138 205 L116 205 Z") +
        f'<path d="M58 95 Q70 40 100 32 Q92 55 100 78 Q130 70 142 100 Q100 90 58 95 Z" fill="#ffc840" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M68 120 Q40 150 52 200" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M68 120 Q40 150 52 200" stroke="#ffd8b8" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M132 125 Q155 140 158 70" stroke="{O}" stroke-width="12" fill="none" stroke-linecap="round"/>'
        f'<path d="M132 125 Q155 140 158 70" stroke="#8a5020" stroke-width="5" fill="none" stroke-linecap="round"/>'
        f'<circle cx="158" cy="58" r="20" fill="#ffb030" opacity="0.3"/>'
        f'<circle cx="158" cy="58" r="14" fill="#ffd070" stroke="#a04810" stroke-width="4"/>'
        f'<circle cx="154" cy="54" r="5" fill="#fff6d0"/>'
        f'<rect x="88" y="90" width="24" height="18" fill="#ffd8b8" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="70" rx="32" ry="34" fill="url(#fc_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 42 Q126 55 128 82 Q116 92 100 92 Z") +
        f'<path d="M68 78 Q60 45 100 34 Q140 45 132 78 Q120 52 100 50 Q80 52 68 78 Z" fill="url(#fc_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M130 80 Q155 130 148 190 Q132 200 126 160 Q138 110 122 80 Z" fill="url(#fc_hair)" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>' +
        f'<path d="M78 68 Q90 55 100 65 Q110 53 122 68" fill="url(#fc_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 38, 30) +
        eyes(100, 70, 28, 10, 12, 3.5, "#6a3010", True, True) + nose(102, 80) + mouth(100, 92, "smirk")
    )

# ========== GLASS ==========
@char("lensmender", "GLASS", (100, 40, 32, "cold"))
def lensmender():
    return (defs(g("lm_skin","#ffe8d8","#f0c8b0"), g("lm_robe","#d0f8ff","#70c8e0"), g("lm_hair","#c0e0f0","#70a0c0")) +
        f'<path d="M78 250 L74 268 L98 268 L100 250 Z" fill="#5080a0" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M112 250 L110 268 L134 268 L130 250 Z" fill="#5080a0" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M80 200 L76 250 L102 250 L104 200 Z" fill="#a0d0e0" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M110 200 L108 250 L134 250 L130 200 Z" fill="#a0d0e0" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M70 108 L130 108 L136 200 L66 200 Z" fill="url(#lm_robe)" fill-opacity="0.92" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        shade("M110 108 L130 108 L136 200 L116 200 Z", "#0a4060", 0.12) +
        f'<circle cx="100" cy="155" r="16" fill="#e8fffb" opacity="0.85"/>'
        f'<path d="M100 145 v20 M90 155 h20" stroke="#2fb58a" stroke-width="6" stroke-linecap="round"/>'
        f'<path d="M70 120 Q42 150 55 200" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M70 120 Q42 150 55 200" stroke="#ffe8d8" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M130 125 Q158 145 165 155" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M130 125 Q158 145 165 155" stroke="#ffe8d8" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M165 155 L172 175" stroke="{O}" stroke-width="8" stroke-linecap="round"/>'
        f'<path d="M165 155 L172 175" stroke="#b07a2a" stroke-width="3.5" stroke-linecap="round"/>'
        f'<circle cx="168" cy="140" r="20" fill="#e0d8ff" fill-opacity="0.7" stroke="#b07a2a" stroke-width="6"/>'
        f'<circle cx="168" cy="140" r="20" fill="none" stroke="{O}" stroke-width="2"/>'
        f'<path d="M158 130 q6 -6 14 -5" stroke="#fff" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
        f'<rect x="88" y="92" width="24" height="18" fill="#ffe8d8" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="72" rx="32" ry="34" fill="url(#lm_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 44 Q126 56 128 84 Q116 94 100 94 Z") +
        f'<path d="M68 80 Q62 48 100 36 Q138 48 132 80 Q120 55 100 52 Q80 55 68 80 Z" fill="url(#lm_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M78 70 Q90 58 100 68 Q110 56 122 70" fill="url(#lm_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 40, 32) +
        eyes(100, 72, 28, 11, 13, 2.5, "#2a6a8a", True) + nose(102, 84) + blush(100, 92) + mouth(100, 98, "smile")
    )

@char("prismshot", "GLASS", (100, 38, 32, "cold"))
def prismshot():
    return (defs(g("ps_skin","#ffe4d0","#f0c0a8"), g("ps_coat","#b8e8ff","#8090e0"), g("ps_hair","#a0d0ff","#5080c0")) +
        f'<path d="M78 250 L74 268 L98 268 L100 250 Z" fill="#405080" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M112 250 L110 268 L134 268 L130 250 Z" fill="#405080" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M80 200 L76 250 L102 250 L104 200 Z" fill="#90b0d0" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M110 200 L108 250 L134 250 L130 200 Z" fill="#90b0d0" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M72 100 L100 88 L128 100 L138 160 L128 205 L72 205 L62 160 Z" fill="url(#ps_coat)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M100 88 L128 100 L100 130 Z" fill="#e0f8ff"/><path d="M72 100 L100 130 L62 160 Z" fill="#c0b0ff"/>'
        f'<path d="M128 100 L100 130 L138 160 Z" fill="#80d0ff"/>'
        f'<path d="M72 100 L100 88 L128 100 L138 160 L128 205 L72 205 L62 160 Z" fill="none" stroke="{O}" stroke-width="{SW}"/>'
        f'<circle cx="120" cy="150" r="3" fill="#ffd0f0"/><circle cx="80" cy="140" r="2.5" fill="#d0fff0"/>'
        f'<path d="M70 120 Q42 155 55 200" stroke="{O}" stroke-width="15" fill="none" stroke-linecap="round"/>'
        f'<path d="M70 120 Q42 155 55 200" stroke="#ffe4d0" stroke-width="8" fill="none" stroke-linecap="round"/>'
        f'<path d="M128 130 Q160 170 162 130" stroke="{O}" stroke-width="12" fill="none" stroke-linecap="round"/>'
        f'<path d="M128 130 Q160 170 162 130" stroke="#d0f0ff" stroke-width="5" fill="none" stroke-linecap="round"/>'
        f'<path d="M162 132 L148 105 M162 132 L178 108" stroke="{O}" stroke-width="8" stroke-linecap="round" fill="none"/>'
        f'<path d="M162 132 L148 105 M162 132 L178 108" stroke="#d0f0ff" stroke-width="3.5" stroke-linecap="round" fill="none"/>'
        f'<path d="M148 105 Q163 122 178 108" stroke="#70d0ff" stroke-width="2.5" fill="none"/>'
        f'<rect x="88" y="88" width="24" height="16" fill="#ffe4d0" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="100" cy="68" rx="30" ry="32" fill="url(#ps_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 42 Q124 54 126 80 Q114 90 100 90 Z") +
        f'<path d="M70 75 Q65 42 100 32 Q135 42 130 75 Q118 50 100 48 Q82 50 70 75 Z" fill="url(#ps_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M78 65 Q90 52 100 62 Q110 50 122 65" fill="url(#ps_hair)" stroke="{O}" stroke-width="3"/>' +
        wick(100, 36, 28) +
        eyes(100, 68, 28, 10, 12, 3.5, "#2a5080", True, True) + nose(102, 78) + mouth(100, 90, "smirk")
    )

# ========== GLOOM ==========
@char("moth", "GLOOM")
def moth():
    W, W2 = "#8b74b8", "#6c5796"
    return (defs(g("mt_skin","#d8c8e8","#a090b8"), g("mt_hair","#3a2848","#1a1028")) +
        f'<path d="M95 130 Q40 40 10 70 Q-5 110 40 135 Z" fill="{W}" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M105 130 Q160 40 190 70 Q205 110 160 135 Z" fill="{W}" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M92 160 Q40 155 25 200 Q45 225 90 185 Z" fill="{W2}" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M108 160 Q160 155 175 200 Q155 225 110 185 Z" fill="{W2}" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M40 90 Q55 105 80 120 M160 90 Q145 105 120 120" stroke="#b9a6dc" stroke-width="3" fill="none" opacity="0.7"/>'
        f'<path d="M75 200 L70 260 L95 260 L98 200 Z" fill="#3a2848" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M110 200 L112 260 L138 260 L130 200 Z" fill="#3a2848" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M72 140 L128 140 L134 210 L68 210 Z" fill="#4a3860" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M85 55 Q75 20 58 12 M115 55 Q125 20 142 12" stroke="{O}" stroke-width="5" fill="none" stroke-linecap="round"/>'
        f'<path d="M60 14 l-8 4 M64 22 l-8 4 M68 32 l-8 3 M140 14 l8 4 M136 22 l8 4 M132 32 l8 3" stroke="{O}" stroke-width="3" stroke-linecap="round"/>'
        f'<ellipse cx="100" cy="95" rx="34" ry="36" fill="url(#mt_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 65 Q128 78 130 110 Q115 120 100 120 Z") +
        f'<path d="M66 100 Q60 60 100 48 Q140 60 134 100 Q120 70 100 68 Q80 70 66 100 Z" fill="url(#mt_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        eyes(100, 95, 30, 12, 12, 2, "#ffd93a", True) +
        f'<path d="M78 82 L98 92 M122 82 L102 92" stroke="{O}" stroke-width="4.5" stroke-linecap="round"/>' +
        nose(102, 105) +
        f'<path d="M90 115 Q100 122 110 115" stroke="{O}" stroke-width="3" fill="none"/>'
        f'<path d="M93 116 l2 6 l2 -5 M105 116 l2 5 l2 -6" fill="#fff" stroke="{O}" stroke-width="1.5"/>'
    )

@char("gloomwisp", "GLOOM")
def gloomwisp():
    return (defs('<radialGradient id="gw" cx="40%" cy="35%" r="70%"><stop offset="0%" stop-color="#c79bff"/><stop offset="100%" stop-color="#6a28c0"/></radialGradient>',
                 g("gw_skin","#e8d8f8","#c0a0e0")) +
        f'<circle cx="110" cy="120" r="70" fill="#a46cff" opacity="0.15"/>'
        f'<path d="M85 180 Q55 210 70 240 Q50 245 40 265 Q75 270 95 245 Q105 270 125 255 Q100 245 115 210 Z" fill="#5a20a8" stroke="{O}" stroke-width="5" stroke-linejoin="round"/>'
        f'<path d="M70 90 Q60 50 100 40 Q145 50 140 100 Q145 160 100 175 Q55 160 70 90 Z" fill="url(#gw)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<ellipse cx="100" cy="105" rx="32" ry="34" fill="url(#gw_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 78 Q126 90 128 118 Q115 130 100 130 Z") +
        f'<ellipse cx="112" cy="100" rx="16" ry="15" fill="#fff" stroke="{O}" stroke-width="3.5"/>'
        f'<circle cx="118" cy="102" r="7" fill="#2a0f4a"/><circle cx="114" cy="97" r="3" fill="#fff"/>'
        f'<path d="M90 88 L125 78" stroke="{O}" stroke-width="4.5" stroke-linecap="round"/>'
        f'<path d="M88 125 Q110 142 130 122 Q110 130 88 125 Z" fill="#3a1268" stroke="{O}" stroke-width="3.5" stroke-linejoin="round"/>'
        f'<circle cx="55" cy="80" r="4" fill="#d9b8ff"/><circle cx="160" cy="160" r="3" fill="#d9b8ff"/><circle cx="145" cy="50" r="3" fill="#d9b8ff"/>'
    )

@char("husk", "GLOOM")
def husk():
    return (defs(g("hk_skin","#c8b8a8","#908070"), g("hk_arm","#8f7f71","#5e5047")) +
        f'<ellipse cx="70" cy="262" rx="20" ry="10" fill="#5a4838" stroke="{O}" stroke-width="4"/>'
        f'<ellipse cx="130" cy="262" rx="20" ry="10" fill="#5a4838" stroke="{O}" stroke-width="4"/>'
        f'<path d="M72 210 L60 262 L90 262 L95 210 Z" fill="#7a6a58" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M118 210 L122 262 L152 262 L140 210 Z" fill="#7a6a58" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M35 150 Q20 170 30 200" stroke="{O}" stroke-width="22" fill="none" stroke-linecap="round"/>'
        f'<path d="M35 150 Q20 170 30 200" stroke="#7d6e62" stroke-width="12" fill="none" stroke-linecap="round"/>'
        f'<path d="M165 150 Q180 170 170 200" stroke="{O}" stroke-width="22" fill="none" stroke-linecap="round"/>'
        f'<path d="M165 150 Q180 170 170 200" stroke="#7d6e62" stroke-width="12" fill="none" stroke-linecap="round"/>'
        f'<ellipse cx="100" cy="150" rx="65" ry="70" fill="url(#hk_arm)" stroke="{O}" stroke-width="{SW}"/>' +
        f'<path d="M40 125 Q100 105 160 125 M38 160 Q100 142 162 160 M48 195 Q100 180 152 195" stroke="#5e5047" stroke-width="5" fill="none" stroke-linecap="round"/>'
        f'<path d="M55 90 Q100 70 145 90" stroke="#b3a393" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.8"/>'
        f'<ellipse cx="100" cy="95" rx="36" ry="38" fill="url(#hk_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 65 Q130 80 132 110 Q115 122 100 122 Z") +
        f'<path d="M65 100 Q58 60 100 48 Q142 60 135 100 Q120 72 100 70 Q80 72 65 100 Z" fill="#6a5a50" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
        f'<path d="M62 108 Q100 95 138 108 L136 128 Q100 118 64 128 Z" fill="#2a1d2e" stroke="{O}" stroke-width="3"/>'
        f'<ellipse cx="84" cy="116" rx="10" ry="6" fill="#c08aff"/><ellipse cx="116" cy="116" rx="10" ry="6" fill="#c08aff"/>'
        f'<circle cx="86" cy="116" r="3" fill="#fff"/><circle cx="118" cy="116" r="3" fill="#fff"/>'
    )

@char("matriarch", "GLOOM")
def matriarch():
    W, W2, E = "#7b3fc4", "#5a2a96", "#ffc93a"
    def wing(flip):
        t = 'transform="translate(200 0) scale(-1 1)"' if flip else ""
        return (f'<g {t}><path d="M98 120 Q50 20 8 45 Q-8 95 35 130 Q65 150 98 140 Z" fill="{W}" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
            f'<path d="M98 150 Q50 155 22 185 Q20 230 58 235 Q92 220 98 175 Z" fill="{W2}" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>'
            f'<ellipse cx="42" cy="75" rx="16" ry="13" fill="{E}" stroke="{O}" stroke-width="4"/><ellipse cx="42" cy="75" rx="7" ry="6" fill="#2a1240"/>'
            f'<circle cx="55" cy="195" r="10" fill="{E}" stroke="{O}" stroke-width="3.5"/><circle cx="55" cy="195" r="4.5" fill="#2a1240"/>'
            f'<path d="M25 105 Q60 115 90 112 M45 40 Q70 75 90 110" stroke="#a676e8" stroke-width="3" fill="none" opacity="0.7"/></g>')
    return (defs(g("mq_skin","#e0d0f0","#a890c0"), g("mq_hair","#2a1838","#100818"), g("mq_gown","#3a2050","#1a1028")) +
        wing(False) + wing(True) +
        f'<path d="M75 220 L70 265 L95 265 L98 220 Z" fill="#2a1838" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M110 220 L112 265 L138 265 L130 220 Z" fill="#2a1838" stroke="{O}" stroke-width="{SW}"/>'
        f'<path d="M70 145 L130 145 L138 230 L64 230 Z" fill="url(#mq_gown)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<path d="M80 145 h40 M78 175 h44 M82 205 h36" stroke="#5a3a70" stroke-width="4" stroke-linecap="round"/>'
        f'<path d="M85 70 Q75 25 55 14 M115 70 Q125 25 145 14" stroke="{O}" stroke-width="6" fill="none" stroke-linecap="round"/>'
        f'<path d="M57 16 l-9 3 M61 26 l-9 4 M67 38 l-8 4 M143 16 l9 3 M139 26 l9 4 M133 38 l8 4" stroke="{O}" stroke-width="3.5" stroke-linecap="round"/>'
        f'<path d="M82 68 L90 48 L100 60 L110 48 L118 68 Z" fill="{E}" stroke="{O}" stroke-width="4" stroke-linejoin="round"/>'
        f'<ellipse cx="100" cy="105" rx="36" ry="38" fill="url(#mq_skin)" stroke="{O}" stroke-width="{SW}"/>' +
        shade("M100 74 Q130 88 132 118 Q115 132 100 132 Z") +
        f'<path d="M64 110 Q58 65 100 52 Q142 65 136 110 Q120 78 100 75 Q80 78 64 110 Z" fill="url(#mq_hair)" stroke="{O}" stroke-width="{SW}" stroke-linejoin="round"/>' +
        f'<circle cx="86" cy="95" r="7" fill="#ff3b3b" stroke="{O}" stroke-width="2.5"/>'
        f'<circle cx="114" cy="95" r="7" fill="#ff3b3b" stroke="{O}" stroke-width="2.5"/>'
        f'<circle cx="100" cy="112" r="6" fill="#ff3b3b" stroke="{O}" stroke-width="2.5"/>'
        f'<circle cx="84" cy="93" r="2" fill="#fff"/><circle cx="112" cy="93" r="2" fill="#fff"/><circle cx="98" cy="110" r="1.8" fill="#fff"/>'
        f'<path d="M90 125 Q100 132 110 125" stroke="#ff9a9a" stroke-width="3" fill="none" stroke-linecap="round"/>'
    )

def svg(name, with_flame=True):
    fn, fam, fl = CHARS[name]
    body = fn()
    if with_flame and fl:
        body += flame_svg(fl[0], fl[1], fl[2], fl[3])
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 280" width="200" height="280">{body}</svg>'

if __name__ == "__main__":
    import json, os
    os.makedirs("svg", exist_ok=True)
    meta = {}
    for n, (fn, fam, fl) in CHARS.items():
        open(f"svg/{n}.svg","w").write(svg(n, True))
        open(f"svg/{n}_noflame.svg","w").write(svg(n, False))
        meta[n] = {"family": fam, "flame": fl}
    open("svg/flame_warm.svg","w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">{flame_svg(100,192,186,"warm")}</svg>')
    open("svg/flame_cold.svg","w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">{flame_svg(100,192,186,"cold")}</svg>')
    json.dump(meta, open("svg/meta.json","w"), indent=1)
    print(len(CHARS), "characters")

