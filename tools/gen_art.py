#!/usr/bin/env python3
"""Generates the original vector character cards for Shah, Dozd, Vazir."""
import pathlib, sys

OUT = pathlib.Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)

INK = '#22161A'
GOLD_DEFS = '''<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#F6E3A6"/><stop offset=".45" stop-color="#D4AE55"/><stop offset="1" stop-color="#8A6424"/></linearGradient>
<linearGradient id="goldh" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#F6E3A6"/><stop offset=".5" stop-color="#C99E45"/><stop offset="1" stop-color="#7E5A1E"/></linearGradient>'''
ARCH = 'M40 404V184C40 126 98 100 150 58C202 100 260 126 260 184V404Z'


def eye(x, y, look=0):
    return (f'<path d="M{x-9} {y}C{x-5} {y-6} {x+5} {y-6} {x+9} {y}C{x+5} {y+4} {x-5} {y+4} {x-9} {y}Z" fill="#FBF3E4"/>'
            f'<circle cx="{x+look}" cy="{y-0.5}" r="3.6" fill="{INK}"/>'
            f'<circle cx="{x+look+1.3}" cy="{y-1.8}" r="1.1" fill="#fff"/>'
            f'<path d="M{x-9} {y}C{x-5} {y-6} {x+5} {y-6} {x+9} {y}" fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>')


def face(skin, shade, cx=150, cy=212, rx=42, ry=50, ears=True):
    s = ''
    if ears:
        s += (f'<ellipse cx="{cx-rx+1}" cy="{cy+4}" rx="7" ry="11" fill="{shade}"/>'
              f'<ellipse cx="{cx+rx-1}" cy="{cy+4}" rx="7" ry="11" fill="{shade}"/>')
    s += f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{skin}"/>'
    # soft side shadow for volume
    s += (f'<path d="M{cx+rx*0.35} {cy-ry*0.95}C{cx+rx*1.05} {cy-ry*0.6} {cx+rx*1.05} {cy+ry*0.6} {cx+rx*0.2} {cy+ry*0.98}'
          f'C{cx+rx*0.75} {cy+ry*0.5} {cx+rx*0.8} {cy-ry*0.4} {cx+rx*0.35} {cy-ry*0.95}Z" fill="{shade}" opacity=".45"/>')
    return s


def nose(shade, y=212):
    return f'<path d="M151 {y}C147 {y+12} 145 {y+18} 153 {y+20}" fill="none" stroke="{shade}" stroke-width="2.4" stroke-linecap="round"/>'


def neck(shade, w=34, top=246, h=56):
    return f'<rect x="{150-w/2}" y="{top}" width="{w}" height="{h}" rx="8" fill="{shade}"/>'


# ---------- CARD STYLES ----------
# A style decides everything around the character: card base and its
# pattern, frame metal, the arch background, the light rays, and optionally a
# treatment of the character itself (decks). Sold in the shop
# (lib/shop/catalog.dart): 'gold' and deck 'classic' are free.
#   themes → <out>/<name>/<role>.svg   ('gold' → <out>/<role>.svg)
#   decks  → <out>/decks/<name>/<role>.svg

KHATAM = ('<pattern id="basepat" width="16" height="16" patternUnits="userSpaceOnUse">'
          '<rect width="16" height="16" fill="#3A2214"/>'
          '<path d="M8 0L10 4L8 8L6 4Z M0 8L4 6L8 8L4 10Z M8 8L12 6L16 8L12 10Z M8 8L10 12L8 16L6 12Z" fill="#E9DCC0"/>'
          '<path d="M8 3.2L9 4.5L8 5.8L7 4.5Z M8 10.2L9 11.5L8 12.8L7 11.5Z" fill="#2F7A55"/>'
          '<circle cx="8" cy="8" r="1.3" fill="#C9A24A"/><circle cx="0" cy="0" r="1.6" fill="#C9A24A"/>'
          '<circle cx="16" cy="0" r="1.6" fill="#C9A24A"/><circle cx="0" cy="16" r="1.6" fill="#C9A24A"/><circle cx="16" cy="16" r="1.6" fill="#C9A24A"/>'
          '</pattern>')
TILE = ('<pattern id="basepat" width="28" height="28" patternUnits="userSpaceOnUse">'
        '<rect width="28" height="28" fill="#0F6F7C"/>'
        '<path d="M14 3L17 10L24 7L21 14L24 21L17 18L14 25L11 18L4 21L7 14L4 7L11 10Z" fill="#F4F1E6"/>'
        '<path d="M14 8L16 12L20 14L16 16L14 20L12 16L8 14L12 12Z" fill="#1D4FA8"/>'
        '<circle cx="14" cy="14" r="1.6" fill="#E3B341"/>'
        '<path d="M0 0L3 3M28 0L25 3M0 28L3 25M28 28L25 25" stroke="#F4F1E6" stroke-width="1.4"/></pattern>')
MINIATURE = ('<pattern id="basepat" width="30" height="30" patternUnits="userSpaceOnUse">'
             '<rect width="30" height="30" fill="#EFE2C2"/>'
             '<path d="M15 4C19 9 19 13 15 15C11 13 11 9 15 4Z M15 26C11 21 11 17 15 15C19 17 19 21 15 26Z" fill="#C79A3A" fill-opacity=".85"/>'
             '<path d="M4 15C9 11 13 11 15 15C13 19 9 19 4 15Z M26 15C21 19 17 19 15 15C17 11 21 11 26 15Z" fill="#2F5FA8" fill-opacity=".8"/>'
             '<circle cx="15" cy="15" r="2" fill="#B3243A"/>'
             '<circle cx="0" cy="0" r="2.2" fill="#2E8B6A"/><circle cx="30" cy="0" r="2.2" fill="#2E8B6A"/>'
             '<circle cx="0" cy="30" r="2.2" fill="#2E8B6A"/><circle cx="30" cy="30" r="2.2" fill="#2E8B6A"/></pattern>')
SILVER = ('<pattern id="basepat" width="22" height="22" patternUnits="userSpaceOnUse">'
          '<rect width="22" height="22" fill="#14161F"/>'
          '<path d="M0 11C5.5 5 5.5 17 11 11S16.5 5 22 11" fill="none" stroke="#B9C2CF" stroke-opacity=".35" stroke-width="1"/>'
          '<circle cx="11" cy="11" r="1.2" fill="#DDE3EC" fill-opacity=".55"/></pattern>')
PAPER = ('<pattern id="basepat" width="40" height="40" patternUnits="userSpaceOnUse">'
         '<rect width="40" height="40" fill="#E8DABA"/>'
         '<path d="M0 20H40M20 0V40" stroke="#B89A66" stroke-opacity=".12" stroke-width="1"/></pattern>')
LACQUER = ('<pattern id="basepat" width="26" height="26" patternUnits="userSpaceOnUse">'
           '<rect width="26" height="26" fill="#0E0B14"/>'
           '<path d="M13 3C17 8 17 11 13 13C9 11 9 8 13 3Z" fill="none" stroke="#C9A24A" stroke-opacity=".4" stroke-width=".9"/></pattern>')
LANTERN = ('<pattern id="basepat" width="20" height="20" patternUnits="userSpaceOnUse">'
           '<rect width="20" height="20" fill="#1F120A"/>'
           '<path d="M0 10H20" stroke="#5A3418" stroke-opacity=".5" stroke-width="2"/></pattern>')

GOLD_M = ('#F6E3A6', '#D4AE55', '#8A6424')
STYLES = {
    # name: kind, base pattern, metal stops, flat line colour, arch (in,out) or None, ray (colour, opacity), fade colour, css/filter
    'gold': dict(kind='theme', pat='', base='#11142F', metal=GOLD_M, flat='#D4AE55', arch=None, ray=None, fade='#11142F'),
    'silver': dict(kind='theme', pat=SILVER, base='#14161F', metal=('#FBFCFE', '#B9C2CF', '#646C7A'), flat='#C7CFDA',
                   arch=None, ray=('#E6ECF5', '.08'), fade='#14161F'),
    'tile': dict(kind='theme', pat=TILE, base='#0F6F7C', metal=('#FFFFFF', '#E6E1D0', '#9C9480'), flat='#F4F1E6',
                 arch=('#2D63C2', '#0B1F4D'), ray=('#FFFFFF', '.09'), fade='#0B1F4D'),
    'khatam': dict(kind='theme', pat=KHATAM, base='#3A2214', metal=('#F3D9A0', '#B88A3E', '#6E4A1C'), flat='#E9DCC0',
                   arch=('#8A5A33', '#2B160A'), ray=('#F3D9A0', '.10'), fade='#2B160A'),
    'miniature': dict(kind='theme', pat=MINIATURE, base='#EFE2C2', metal=('#F6E3A6', '#C79A3A', '#7E5A1E'), flat='#2F5FA8',
                      arch=('#4AA3C8', '#123E73'), ray=('#F6E3A6', '.16'), fade='#123E73'),
    # Decks: the character itself changes.
    'qajar': dict(kind='deck', pat=PAPER, base='#E8DABA', metal=('#E7CFA0', '#9C7442', '#4E3418'), flat='#7A5A35',
                  arch=('#D8C3A0', '#6E5436'), ray=('#FFFFFF', '.05'), fade='#4E3A24', treat='qajar'),
    'shadow': dict(kind='deck', pat=LANTERN, base='#1F120A', metal=('#E3B26A', '#9E5E22', '#4A260C'), flat='#C9873E',
                   arch=('#FFD58A', '#B8461A'), ray=('#FFF2C9', '.12'), fade='#7A2A0E', treat='shadow'),
    'engraving': dict(kind='deck', pat=LACQUER, base='#0E0B14', metal=GOLD_M, flat='#D4AE55',
                      arch=('#2A2440', '#07060C'), ray=('#D4AE55', '.07'), fade='#07060C', treat='engraving'),
}

TREATMENTS = {
    'qajar': ('<filter id="treat" x="0" y="0" width="1" height="1" color-interpolation-filters="sRGB">'
              '<feColorMatrix type="matrix" values=".393 .769 .189 0 0 .349 .686 .168 0 0 .272 .534 .131 0 0 0 0 0 1 0"/>'
              '<feComponentTransfer><feFuncR type="linear" slope="1.08" intercept="-.02"/><feFuncG type="linear" slope="1.05" intercept="-.02"/>'
              '<feFuncB type="linear" slope=".95" intercept="-.02"/></feComponentTransfer></filter>'
              '<filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".85" numOctaves="2" seed="4"/>'
              '<feColorMatrix type="matrix" values="0 0 0 0 .25 0 0 0 0 .18 0 0 0 0 .1 0 0 0 .55 0"/></filter>'
              '<radialGradient id="vig" cx=".5" cy=".5" r=".6"><stop offset=".55" stop-color="#2A1A0A" stop-opacity="0"/>'
              '<stop offset="1" stop-color="#2A1A0A" stop-opacity=".75"/></radialGradient>', ''),
    'shadow': ('', '<style>.treat *{fill:#1A0E08!important;stroke:#1A0E08!important}.treat [fill="none"]{fill:none!important}</style>'),
    'engraving': ('', '<style>.treat *{fill:#16121F!important;stroke:#E2C277!important;stroke-width:1.3px!important}'
                      '.treat [fill="none"]{fill:none!important}</style>'),
}

CARD_TEMPLATE = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 420" width="600" height="840">
<defs>§GOLD_DEFS§§PAT§§TREAT_DEFS§
<linearGradient id="frm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="§M0§"/><stop offset=".45" stop-color="§M1§"/><stop offset="1" stop-color="§M2§"/></linearGradient>
<radialGradient id="bg" cx=".5" cy=".46" r=".62"><stop offset="0" stop-color="§BG_IN§"/><stop offset="1" stop-color="§BG_OUT§"/></radialGradient>
<clipPath id="arch"><path d="§ARCH§"/></clipPath>
<linearGradient id="fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="§FADE§" stop-opacity="0"/><stop offset="1" stop-color="§FADE§" stop-opacity=".55"/></linearGradient>§EXTRA_DEFS§
</defs>§STYLE§
<rect x="3" y="3" width="294" height="414" rx="22" fill="§BASE§"/>
<rect x="3" y="3" width="294" height="414" rx="22" fill="§BASEFILL§"/>
<rect x="3" y="3" width="294" height="414" rx="22" fill="none" stroke="#000" stroke-opacity=".35" stroke-width="2"/>
<rect x="12" y="12" width="276" height="396" rx="15" fill="none" stroke="url(#frm)" stroke-width="2.6"/>
<rect x="19" y="19" width="262" height="382" rx="10" fill="none" stroke="§FLAT§" stroke-opacity=".45" stroke-width="1"/>
<path d="M36 404V184C36 124 96 98 150 52C204 98 264 124 264 184V404Z" fill="§BASE§" fill-opacity=".55"/>
<g clip-path="url(#arch)"§GROUP_FILTER§>
<rect width="300" height="420" fill="url(#bg)"/>
<circle cx="150" cy="214" r="170" fill="none" stroke="§RAY§" stroke-opacity="§RAY_OP§" stroke-width="340" stroke-dasharray="26.7 26.7"/>
<circle cx="150" cy="214" r="96" fill="#fff" opacity=".05"/>
<g class="treat">§BODY§</g>
<rect y="330" width="300" height="90" fill="url(#fade)"/>
</g>§OVERLAY§
<path d="§ARCH§" fill="none" stroke="url(#frm)" stroke-width="3.2"/>
<path d="M30 404V184C30 120 92 92 150 46C208 92 270 120 270 184V404" fill="none" stroke="§FLAT§" stroke-opacity=".6" stroke-width="1.2"/>
<path d="M150 34l6 8-6 8-6-8z" fill="url(#frm)"/>
<g fill="url(#frm)"><path d="M30 30l5 5-5 5-5-5z"/><path d="M270 30l5 5-5 5-5-5z"/><path d="M30 380l5 5-5 5-5-5z"/><path d="M270 380l5 5-5 5-5-5z"/></g>
</svg>'''


def card(name, bg_in, bg_out, body, extra_defs='', ray='#FFFFFF', ray_op='.06'):
    for style, st in STYLES.items():
        arch_in, arch_out = st['arch'] or (bg_in, bg_out)
        r_col, r_op = st['ray'] or (ray, ray_op)
        treat = st.get('treat')
        tdefs, tstyle = TREATMENTS.get(treat, ('', ''))
        overlay = ''
        group_filter = ''
        if treat == 'qajar':
            group_filter = ' filter="url(#treat)"'
            overlay = ('<g clip-path="url(#arch)"><rect width="300" height="420" fill="url(#vig)"/>'
                       '<rect width="300" height="420" filter="url(#grain)" opacity=".35"/></g>')
        values = [('GOLD_DEFS', GOLD_DEFS), ('PAT', st['pat']), ('TREAT_DEFS', tdefs), ('EXTRA_DEFS', extra_defs),
                  ('STYLE', tstyle), ('GROUP_FILTER', group_filter), ('OVERLAY', overlay), ('ARCH', ARCH),
                  ('BG_IN', arch_in), ('BG_OUT', arch_out), ('BASEFILL', 'url(#basepat)' if st['pat'] else st['base']),
                  ('BASE', st['base']), ('FLAT', st['flat']), ('FADE', st['fade']), ('RAY_OP', r_op), ('RAY', r_col),
                  ('M0', st['metal'][0]), ('M1', st['metal'][1]), ('M2', st['metal'][2]), ('BODY', body)]
        svg = CARD_TEMPLATE
        for k, v in values:
            svg = svg.replace('§' + k + '§', v)
        if style == 'gold':
            folder = OUT
        elif st['kind'] == 'deck':
            folder = OUT / 'decks' / style
        else:
            folder = OUT / style
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f'{name}.svg').write_text(svg)


# ---------- KING (Shah / Raja) ----------
skin, shade = '#CF946A', '#A9704A'
king = f'''
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="#4A2180"/>
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="#000" opacity=".12" transform="translate(150 0) scale(.5 1)"/>
<path d="M116 298L150 350L184 298Z" fill="#F3E7CC"/>
<path d="M112 296L150 352L188 296" fill="none" stroke="url(#gold)" stroke-width="9" stroke-linejoin="round"/>
<path d="M58 372C74 326 104 306 126 300" fill="none" stroke="url(#gold)" stroke-width="7" stroke-linecap="round"/>
<path d="M242 372C226 326 196 306 174 300" fill="none" stroke="url(#gold)" stroke-width="7" stroke-linecap="round"/>
<circle cx="150" cy="372" r="9" fill="#B3243A" stroke="url(#gold)" stroke-width="3"/>
<circle cx="150" cy="398" r="6" fill="url(#gold)"/>
{neck(shade)}
<path d="M104 206C102 170 198 170 196 206L196 244L104 244Z" fill="#1C1620"/>
{face(skin, shade)}
<path d="M121 195Q132 187 143 194" fill="none" stroke="#1C1620" stroke-width="4.5" stroke-linecap="round"/>
<path d="M157 194Q168 187 179 195" fill="none" stroke="#1C1620" stroke-width="4.5" stroke-linecap="round"/>
{eye(132, 207)}{eye(168, 207)}
{nose(shade, 210)}
<path d="M106 212C104 262 126 300 150 320C174 300 196 262 194 212C188 236 176 248 165 251Q150 257 135 251C124 248 112 236 106 212Z" fill="#1C1620"/>
<path d="M150 234C139 228 126 232 117 244C129 239 140 241 150 241C160 241 171 239 183 244C174 232 161 228 150 234Z" fill="#2B2333"/>
<ellipse cx="150" cy="248" rx="7" ry="2.6" fill="#9E4A40"/>
<path d="M101 166L96 112L122 140L150 88L178 140L204 112L199 166Z" fill="url(#gold)"/>
<path d="M101 166L96 112L122 140L150 88L178 140L204 112L199 166Z" fill="none" stroke="#7E5A1E" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M100 156H200V178H100Z" fill="url(#goldh)" stroke="#7E5A1E" stroke-width="1.5"/>
<circle cx="96" cy="110" r="5" fill="url(#gold)"/><circle cx="150" cy="86" r="6" fill="url(#gold)"/><circle cx="204" cy="110" r="5" fill="url(#gold)"/>
<path d="M150 116l9 14-9 14-9-14z" fill="#B3243A" stroke="#F6E3A6" stroke-width="1.2"/>
<circle cx="150" cy="167" r="5.5" fill="#B3243A"/><circle cx="124" cy="167" r="4" fill="#2E8B6A"/><circle cx="176" cy="167" r="4" fill="#2F5DB0"/>
'''
card('king', '#7B4CB8', '#22103F', king)

# ---------- MINISTER (Vazir / Mantri) ----------
skin, shade = '#DDAA80', '#B47E57'
vazir = f'''
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="#17504D"/>
<path d="M128 296L150 420L172 296Z" fill="#F3E7CC"/>
<path d="M126 296L150 420M174 296L150 420" stroke="url(#gold)" stroke-width="4"/>
<g transform="rotate(-18 150 372)"><rect x="98" y="362" width="104" height="20" rx="10" fill="#F6EEDC"/>
<path d="M110 366H190M110 372H178M110 378H186" stroke="#B8A57E" stroke-width="1.4"/>
<circle cx="98" cy="372" r="11" fill="url(#gold)"/><circle cx="202" cy="372" r="11" fill="url(#gold)"/></g>
{neck(shade)}
<path d="M106 196C104 176 196 176 194 196L196 236L104 236Z" fill="#B9B2A6"/>
{face(skin, shade)}
<path d="M120 191Q132 181 143 189" fill="none" stroke="#9C958A" stroke-width="4" stroke-linecap="round"/>
<path d="M157 189Q168 181 180 191" fill="none" stroke="#9C958A" stroke-width="4" stroke-linecap="round"/>
{eye(132, 207, 1)}{eye(168, 207, 1)}
<circle cx="132" cy="207" r="12" fill="#fff" fill-opacity=".08" stroke="url(#gold)" stroke-width="2.2"/>
<circle cx="168" cy="207" r="12" fill="#fff" fill-opacity=".08" stroke="url(#gold)" stroke-width="2.2"/>
<path d="M144 205Q150 201 156 205" fill="none" stroke="url(#gold)" stroke-width="2"/>
{nose(shade, 212)}
<path d="M110 222C112 262 134 298 150 336C166 298 188 262 190 222C182 240 170 248 160 250Q150 255 140 250C130 248 118 240 110 222Z" fill="#E4DED2"/>
<path d="M150 236C142 231 132 233 124 241C134 239 142 241 150 242C158 241 166 239 176 241C168 233 158 231 150 236Z" fill="#CFC8BB"/>
<path d="M144 248Q150 251 156 248" fill="none" stroke="#8F4B3E" stroke-width="2.4" stroke-linecap="round"/>
<path d="M112 178C110 140 116 104 128 76C140 68 160 68 172 76C184 104 190 140 188 178Z" fill="#1E2531"/>
<path d="M128 76C140 68 160 68 172 76C176 86 178 96 180 106C162 98 138 98 120 106C122 96 124 86 128 76Z" fill="#2A3344"/>
<path d="M110 164H190V180H110Z" fill="url(#goldh)" stroke="#7E5A1E" stroke-width="1.2"/>
<path d="M150 112C164 116 166 134 152 140C140 144 136 130 145 125C150 122 154 127 150 130" fill="none" stroke="url(#gold)" stroke-width="3" stroke-linecap="round"/>
'''
card('minister', '#2F8A84', '#0B2628', vazir)

# ---------- THIEF (Dozd / Chor) ----------
skin, shade = '#BC8159', '#94603D'
dozd = f'''
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="#26222E"/>
<path d="M150 300L130 420M150 300L170 420" stroke="#3A3446" stroke-width="3"/>
<ellipse cx="222" cy="338" rx="38" ry="44" fill="#8A6238"/>
<path d="M196 312C204 300 236 300 246 312" fill="none" stroke="#5E4024" stroke-width="5" stroke-linecap="round"/>
<circle cx="206" cy="298" r="9" fill="url(#gold)" stroke="#7E5A1E"/><circle cx="224" cy="292" r="8" fill="url(#gold)" stroke="#7E5A1E"/><circle cx="238" cy="300" r="7" fill="url(#gold)" stroke="#7E5A1E"/>
<path d="M206 338q10 6 20 0" fill="none" stroke="#5E4024" stroke-width="3" stroke-linecap="round"/>
{neck(shade)}
{face(skin, shade, ears=False)}
<g fill="{shade}" opacity=".5"><circle cx="128" cy="240" r="1.4"/><circle cx="136" cy="248" r="1.4"/><circle cx="164" cy="249" r="1.4"/><circle cx="172" cy="241" r="1.4"/><circle cx="150" cy="256" r="1.4"/><circle cx="142" cy="254" r="1.4"/><circle cx="158" cy="255" r="1.4"/></g>
<path d="M122 186Q132 178 143 186" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
<path d="M157 190L180 187" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
<path d="M104 196C130 188 170 188 196 196L196 216C170 209 130 209 104 216Z" fill="#14111A"/>
<path d="M104 200L84 192L92 206L82 214L104 212" fill="#14111A"/>
{eye(132, 203, -3)}{eye(168, 203, -3)}
{nose(shade, 212)}
<path d="M150 233C142 228 133 229 126 236M150 233C158 228 168 227 175 231" fill="none" stroke="{INK}" stroke-width="2.6" stroke-linecap="round"/>
<path d="M134 242Q152 252 168 236" fill="none" stroke="#6E2E26" stroke-width="3" stroke-linecap="round"/>
<path d="M90 304C76 240 90 150 150 130C210 150 224 240 210 304C200 294 190 284 186 270C194 232 186 184 150 176C114 184 106 232 114 270C110 284 100 294 90 304Z" fill="#332C40"/>
<path d="M114 270C106 232 114 184 150 176C186 184 194 232 186 270" fill="none" stroke="#1B1724" stroke-width="3"/>
'''
card('thief', '#8E3346', '#1A0A14', dozd)

# ---------- SECOND THIEF ----------
skin, shade = '#C88B63', '#9E6643'
dozd2 = f'''
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="#1F2546"/>
{neck(shade)}
{face(skin, shade, ears=False)}
<path d="M120 192Q132 182 143 190" fill="none" stroke="{INK}" stroke-width="3.6" stroke-linecap="round"/>
<path d="M157 186Q168 176 180 188" fill="none" stroke="{INK}" stroke-width="3.6" stroke-linecap="round"/>
{eye(132, 206, 2)}{eye(168, 206, 2)}
<path d="M141 204L147 200M177 204L183 200" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>
<path d="M106 222C120 230 180 230 194 222C194 264 174 296 150 300C126 296 106 264 106 222Z" fill="#2E3A6E"/>
<path d="M106 222C120 230 180 230 194 222" fill="none" stroke="url(#gold)" stroke-width="2"/>
<g fill="url(#gold)"><circle cx="116" cy="230" r="3"/><circle cx="130" cy="234" r="3"/><circle cx="144" cy="235" r="3"/><circle cx="158" cy="235" r="3"/><circle cx="172" cy="233" r="3"/><circle cx="185" cy="229" r="3"/></g>
<path d="M88 306C74 240 88 150 150 128C212 150 226 240 212 306C202 296 192 286 188 272C196 232 188 182 150 174C112 182 104 232 112 272C108 286 98 296 88 306Z" fill="#2C3568"/>
<path d="M112 272C104 232 112 182 150 174C188 182 196 232 188 272" fill="none" stroke="url(#gold)" stroke-width="2"/>
<g transform="translate(150 340)"><circle r="14" fill="none" stroke="url(#gold)" stroke-width="5"/><circle r="5" fill="#2C3568"/>
<path d="M0 14V48M0 34H10M0 42H8" stroke="url(#gold)" stroke-width="5" stroke-linecap="round"/></g>
'''
card('thief2', '#4864A6', '#0F1630', dozd2)

# ---------- EXECUTIONER (Jallad) ----------
skin, shade = '#AE7149', '#87522F'
jallad = f'''
<path d="M84 400C118 306 170 206 240 112C232 176 186 268 108 404Z" fill="#D9DEE5"/>
<path d="M84 400C118 306 170 206 240 112" fill="none" stroke="#8C949F" stroke-width="2"/>
<path d="M30 420C36 330 90 290 150 288C210 290 264 330 270 420Z" fill="{skin}"/>
<path d="M30 420C36 330 90 290 150 288C210 290 264 330 270 420Z" fill="{shade}" opacity=".25"/>
<path d="M54 420C58 360 88 318 128 302L136 420Z" fill="#7C1F28"/>
<path d="M246 420C242 360 212 318 172 302L164 420Z" fill="#7C1F28"/>
<path d="M128 302L136 420M172 302L164 420" stroke="url(#gold)" stroke-width="4"/>
<path d="M86 352Q110 330 124 340" fill="none" stroke="#5E1219" stroke-width="2" opacity=".6"/>
{neck(shade, w=46, top=244)}
{face(skin, shade, rx=46, ry=52)}
<ellipse cx="132" cy="176" rx="14" ry="7" fill="#fff" opacity=".22" transform="rotate(-20 132 176)"/>
<path d="M118 192L144 200" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>
<path d="M182 192L156 200" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>
{eye(132, 210)}{eye(168, 210)}
{nose(shade, 214)}
<path d="M150 238C132 228 112 232 100 222C94 234 102 248 116 247C128 248 140 246 150 244C160 246 172 248 184 247C198 248 206 234 200 222C188 232 168 228 150 238Z" fill="#2A1A14"/>
<circle cx="99" cy="226" r="4" fill="none" stroke="#2A1A14" stroke-width="3"/><circle cx="201" cy="226" r="4" fill="none" stroke="#2A1A14" stroke-width="3"/>
<path d="M140 254H160" stroke="#5E2A22" stroke-width="3" stroke-linecap="round"/>
<rect x="66" y="392" width="40" height="14" rx="5" fill="url(#goldh)" transform="rotate(-58 86 399)"/>
'''
card('executioner', '#B03A3A', '#280A0E', jallad)

# ---------- SIPAHI ----------
skin, shade = '#93603F', '#6F4429'
sipahi = f'''
<path d="M222 420V160" stroke="#6B4A2A" stroke-width="6" stroke-linecap="round"/>
<path d="M222 118L231 142L222 160L213 142Z" fill="#DDE2E8" stroke="#8C949F" stroke-width="1.5"/>
<path d="M216 164Q222 180 228 164Z" fill="#B3243A"/><path d="M218 166L214 188M222 166L222 192M226 166L230 188" stroke="#B3243A" stroke-width="3" stroke-linecap="round"/>
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="#8E2C24"/>
<path d="M84 330L222 420" stroke="#F3E7CC" stroke-width="13"/>
<path d="M84 330L222 420" stroke="#D4AE55" stroke-width="2" stroke-dasharray="2 10"/>
<g fill="url(#gold)"><circle cx="150" cy="318" r="4"/><circle cx="150" cy="346" r="4"/><circle cx="150" cy="400" r="4"/></g>
{neck(shade)}
{face(skin, shade)}
<path d="M120 194L143 193" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>
<path d="M157 193L180 194" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>
{eye(132, 207)}{eye(168, 207)}
{nose(shade, 210)}
<path d="M150 234C140 228 128 230 120 238C114 236 110 230 112 224C110 236 118 246 130 242C138 240 145 238 150 238C155 238 162 240 170 242C182 246 190 236 188 224C190 230 186 236 180 238C172 230 160 228 150 234Z" fill="#1A1210"/>
<path d="M142 250H158" stroke="#4E2418" stroke-width="3" stroke-linecap="round"/>
<path d="M100 188C94 142 120 112 150 110C180 112 206 142 200 188C178 176 122 176 100 188Z" fill="#E89A2E"/>
<path d="M104 168C124 150 176 150 196 168M102 152C124 132 176 132 198 152M112 132C132 118 168 118 188 132" fill="none" stroke="#B86F17" stroke-width="3" stroke-linecap="round"/>
<path d="M150 146C146 120 152 100 168 86C162 104 160 124 156 146Z" fill="#F6EEDC"/>
<circle cx="150" cy="152" r="9" fill="url(#gold)"/><circle cx="150" cy="152" r="4.5" fill="#B3243A"/>
<path d="M150 161l4 10-4 6-4-6z" fill="url(#gold)"/>
'''
card('sipahi', '#D49340', '#3A1E0C', sipahi)

# ---------- JOKER ----------
skin, shade = '#F7ECDD', '#E0CDB6'
confetti = ''.join(
    f'<rect x="{x}" y="{y}" width="7" height="3.5" rx="1" fill="{c}" transform="rotate({r} {x} {y})"/>'
    for x, y, r, c in [(70, 250, 30, '#F6E3A6'), (228, 240, -25, '#5ED1C4'), (84, 300, -40, '#F6EEDC'),
                       (220, 290, 60, '#F6E3A6'), (60, 200, 10, '#5ED1C4'), (240, 196, -15, '#F6EEDC'),
                       (110, 120, 45, '#5ED1C4'), (196, 116, 20, '#F6E3A6')])
joker_defs = '''<pattern id="harl" width="36" height="36" patternUnits="userSpaceOnUse"><rect width="36" height="36" fill="#4A1E66"/>
<path d="M18 0L36 18L18 36L0 18Z" fill="#6A2C91"/><path d="M18 14L22 18L18 22L14 18Z" fill="#D4AE55"/></pattern>'''
joker = f'''
{confetti}
<path d="M40 420C46 334 92 298 150 292C208 298 254 334 260 420Z" fill="url(#harl)"/>
{neck(shade)}
<path d="M84 318L98 294L114 320L128 292L142 320L150 290L158 320L172 292L186 320L202 294L216 318C190 334 110 334 84 318Z" fill="#F6EEDC" stroke="url(#gold)" stroke-width="2.5" stroke-linejoin="round"/>
<g fill="url(#gold)"><circle cx="98" cy="294" r="4.5"/><circle cx="128" cy="292" r="4.5"/><circle cx="150" cy="290" r="4.5"/><circle cx="172" cy="292" r="4.5"/><circle cx="202" cy="294" r="4.5"/></g>
{face(skin, shade)}
<circle cx="124" cy="228" r="10" fill="#E8607A" opacity=".45"/><circle cx="176" cy="228" r="10" fill="#E8607A" opacity=".45"/>
<path d="M122 197Q132 191 142 196" fill="none" stroke="{INK}" stroke-width="3.6" stroke-linecap="round"/>
<path d="M156 188Q168 174 182 186" fill="none" stroke="{INK}" stroke-width="3.6" stroke-linecap="round"/>
<path d="M123 209Q132 202 141 209" fill="none" stroke="{INK}" stroke-width="3.4" stroke-linecap="round"/>
<path d="M119 207L124 210M120 213L125 212" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>
{eye(168, 206, 1)}
<path d="M168 218l5 8-5 8-5-8z" fill="#7A2CA0"/>
<circle cx="151" cy="224" r="5.5" fill="#D2546A"/>
<path d="M118 236Q150 280 182 236Q150 252 118 236Z" fill="#7A1F3A"/>
<path d="M124 239Q150 252 176 239Q150 247 124 239Z" fill="#fff"/>
<path d="M140 258Q150 264 160 258Q150 256 140 258Z" fill="#E8607A"/>
<path d="M114 232Q116 238 120 240M186 232Q184 238 180 240" fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>
<path d="M104 184C104 146 196 146 196 184Z" fill="#6A2C91"/>
<path d="M108 182C92 150 70 142 50 152C64 128 100 126 124 152C130 162 132 172 132 176Z" fill="#7A2CA0"/>
<path d="M192 182C208 150 230 142 250 152C236 128 200 126 176 152C170 162 168 172 168 176Z" fill="url(#gold)"/>
<path d="M124 178C120 140 134 102 172 80C166 104 170 136 176 178Z" fill="#C2387F"/>
<path d="M102 176C124 166 176 166 198 176L198 190C176 182 124 182 102 190Z" fill="url(#goldh)" stroke="#7E5A1E" stroke-width="1"/>
<g fill="#7A2CA0"><circle cx="118" cy="183" r="3"/><circle cx="150" cy="180" r="3"/><circle cx="182" cy="183" r="3"/></g>
<circle cx="50" cy="153" r="8" fill="url(#gold)" stroke="#7E5A1E"/><circle cx="250" cy="153" r="8" fill="#F6EEDC" stroke="#7E5A1E"/><circle cx="172" cy="80" r="8" fill="url(#gold)" stroke="#7E5A1E"/>
'''
card('joker', '#B4419A', '#260B2C', joker, extra_defs=joker_defs)

# ---------- CARD BACKS ----------
# 'classic' is the free back (out/back.svg); the others are sold in the shop
# (lib/shop/catalog.dart) and go to out/backs/<name>.svg.
import math

LATTICE = ('<path d="M12 2L22 12L12 22L2 12Z" fill="none" stroke="#D4AE55" stroke-opacity=".22" stroke-width="1"/>'
           '<circle cx="12" cy="12" r="1.4" fill="#D4AE55" fill-opacity=".35"/>', 24)
STARS = ('<circle cx="5" cy="7" r=".9" fill="#fff" fill-opacity=".7"/><circle cx="23" cy="4" r=".6" fill="#fff" fill-opacity=".5"/>'
         '<circle cx="15" cy="19" r="1.2" fill="#F6E3A6" fill-opacity=".8"/><circle cx="30" cy="26" r=".7" fill="#fff" fill-opacity=".6"/>'
         '<circle cx="9" cy="30" r=".5" fill="#fff" fill-opacity=".5"/>', 34)
PAISLEY = ('<path d="M18 6C26 8 28 20 20 24C13 27 9 19 15 16C19 14 21 18 18 20" fill="none" stroke="#D4AE55" stroke-opacity=".35" '
           'stroke-width="1.4" stroke-linecap="round"/><circle cx="6" cy="28" r="1.3" fill="#D4AE55" fill-opacity=".35"/>', 36)
WAVES = ('<path d="M0 10Q7.5 4 15 10T30 10M0 22Q7.5 16 15 22T30 22" fill="none" stroke="#D4AE55" stroke-opacity=".25" stroke-width="1.2"/>', 30)
RAYS = (None, 0)

_sun_rays = ''.join(
    f'<path d="M150 210L{150 + 60 * math.cos(a / 16 * 2 * math.pi):.1f} {210 + 60 * math.sin(a / 16 * 2 * math.pi):.1f}"/>'
    for a in range(16))

EMBLEMS = {
    'crown': ('<g fill="none" stroke="url(#gold)" stroke-width="2"><rect x="106" y="166" width="88" height="88"/>'
              '<rect x="106" y="166" width="88" height="88" transform="rotate(45 150 210)"/></g>'
              '<path d="M118 232L114 190L132 206L150 178L168 206L186 190L182 232Z" fill="url(#gold)"/>'
              '<rect x="116" y="228" width="68" height="10" rx="2" fill="url(#goldh)"/>'
              '<circle cx="150" cy="176" r="4" fill="url(#gold)"/>'
              '<path d="M150 200l6 9-6 9-6-9z" fill="GEM"/>'),
    'moon': ('<path d="M168 172A44 44 0 1 0 168 248A36 36 0 1 1 168 172Z" fill="url(#gold)"/>'
             '<g fill="url(#gold)"><path d="M182 186l3 7 7 3-7 3-3 7-3-7-7-3 7-3z"/><path d="M194 220l2 4 4 2-4 2-2 4-2-4-4-2 4-2z"/></g>'),
    'boteh': ('<path d="M150 166C186 174 194 230 158 250C128 266 108 232 128 214C142 202 160 212 152 226" fill="none" '
              'stroke="url(#gold)" stroke-width="5" stroke-linecap="round"/>'
              '<path d="M150 182C170 190 174 222 156 234" fill="none" stroke="url(#gold)" stroke-width="2" stroke-opacity=".7"/>'
              '<circle cx="141" cy="222" r="5" fill="GEM"/>'),
    'sun': ('<g stroke="url(#gold)" stroke-width="3" stroke-linecap="round">' + _sun_rays + '</g>'
            '<circle cx="150" cy="210" r="30" fill="url(#gold)"/><circle cx="150" cy="210" r="22" fill="none" stroke="#8A6424" stroke-width="2"/>'
            '<path d="M141 205q3-3 6 0M153 205q3-3 6 0M141 218q9 7 18 0" fill="none" stroke="#7E5A1E" stroke-width="2.4" stroke-linecap="round"/>'),
    'star': ('<g fill="none" stroke="url(#gold)" stroke-width="2.5"><rect x="110" y="170" width="80" height="80"/>'
             '<rect x="110" y="170" width="80" height="80" transform="rotate(45 150 210)"/></g>'
             '<circle cx="150" cy="210" r="22" fill="url(#gold)"/><path d="M150 196l4 10 10 4-10 4-4 10-4-10-10-4 10-4z" fill="GEM"/>'),
}


def back(name, c_in, c_out, medallion, pattern, emblem, gem='#B3243A'):
    tile, size = pattern
    if tile is None:  # sunburst
        pat = '<clipPath id="in"><rect x="22" y="22" width="256" height="376" rx="10"/></clipPath>'
        fill = ('<g clip-path="url(#in)"><circle cx="150" cy="210" r="200" fill="none" stroke="#D4AE55" stroke-opacity=".12" '
                'stroke-width="400" stroke-dasharray="20.9 20.9"/></g>')
    else:
        pat = f'<pattern id="pat" width="{size}" height="{size}" patternUnits="userSpaceOnUse">{tile}</pattern>'
        fill = '<rect x="22" y="22" width="256" height="376" rx="10" fill="url(#pat)"/>'
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 420" width="600" height="840">'
           f'<defs>{GOLD_DEFS}{pat}'
           f'<radialGradient id="bg" cx=".5" cy=".5" r=".7"><stop offset="0" stop-color="{c_in}"/><stop offset="1" stop-color="{c_out}"/></radialGradient>'
           f'</defs>'
           f'<rect x="3" y="3" width="294" height="414" rx="22" fill="url(#bg)"/>{fill}'
           f'<rect x="12" y="12" width="276" height="396" rx="15" fill="none" stroke="url(#gold)" stroke-width="2.2"/>'
           f'<rect x="22" y="22" width="256" height="376" rx="10" fill="none" stroke="#D4AE55" stroke-opacity=".5" stroke-width="1"/>'
           f'<circle cx="150" cy="210" r="78" fill="{medallion}" stroke="url(#gold)" stroke-width="2.5"/>'
           f'<circle cx="150" cy="210" r="68" fill="none" stroke="#D4AE55" stroke-opacity=".4" stroke-width="1"/>'
           f'{EMBLEMS[emblem].replace("GEM", gem)}'
           f'<g fill="url(#gold)"><path d="M150 40l7 9-7 9-7-9z"/><path d="M150 362l7 9-7 9-7-9z"/></g>'
           f'</svg>')
    if name == 'classic':
        (OUT / 'back.svg').write_text(svg)
    else:
        (OUT / 'backs').mkdir(exist_ok=True)
        (OUT / 'backs' / f'{name}.svg').write_text(svg)


back('classic', '#2A2466', '#0E1130', '#121637', LATTICE, 'crown')
back('emerald', '#1F6B5E', '#06201C', '#0A2A25', LATTICE, 'star')
back('ruby', '#8E2338', '#2A0710', '#330A14', WAVES, 'crown', gem='#2F5DB0')
back('paisley', '#2F3A86', '#0D1233', '#151B4A', PAISLEY, 'boteh', gem='#C2387F')
back('starry', '#1B2A5E', '#05081C', '#0A1030', STARS, 'moon')
back('sun', '#6B3FA0', '#1E0E3A', '#2A1452', RAYS, 'sun')
print('ok', sorted(str(x.relative_to(OUT)) for x in OUT.rglob('*.svg')))
