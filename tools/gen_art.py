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


def card(name, bg_in, bg_out, body, extra_defs='', ray='#FFFFFF', ray_op='.06'):
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 420" width="600" height="840">
<defs>{GOLD_DEFS}
<radialGradient id="bg" cx=".5" cy=".46" r=".62"><stop offset="0" stop-color="{bg_in}"/><stop offset="1" stop-color="{bg_out}"/></radialGradient>
<clipPath id="arch"><path d="{ARCH}"/></clipPath>{extra_defs}
</defs>
<rect x="3" y="3" width="294" height="414" rx="22" fill="#11142F"/>
<rect x="3" y="3" width="294" height="414" rx="22" fill="none" stroke="#000" stroke-opacity=".35" stroke-width="2"/>
<rect x="12" y="12" width="276" height="396" rx="15" fill="none" stroke="url(#gold)" stroke-width="2.2"/>
<rect x="19" y="19" width="262" height="382" rx="10" fill="none" stroke="#D4AE55" stroke-opacity=".3" stroke-width="1"/>
<g clip-path="url(#arch)">
<rect width="300" height="420" fill="url(#bg)"/>
<circle cx="150" cy="214" r="170" fill="none" stroke="{ray}" stroke-opacity="{ray_op}" stroke-width="340" stroke-dasharray="26.7 26.7"/>
<circle cx="150" cy="214" r="96" fill="#fff" opacity=".05"/>
{body}
<rect y="330" width="300" height="90" fill="url(#fade)"/>
</g>
<path d="{ARCH}" fill="none" stroke="url(#gold)" stroke-width="3"/>
<path d="M30 404V184C30 120 92 92 150 46C208 92 270 120 270 184V404" fill="none" stroke="#D4AE55" stroke-opacity=".45" stroke-width="1"/>
<path d="M150 34l6 8-6 8-6-8z" fill="url(#gold)"/>
<g fill="url(#gold)"><path d="M30 30l5 5-5 5-5-5z"/><path d="M270 30l5 5-5 5-5-5z"/><path d="M30 380l5 5-5 5-5-5z"/><path d="M270 380l5 5-5 5-5-5z"/></g>
</svg>'''
    svg = svg.replace('{extra_defs}', '')
    svg = svg.replace('</defs>', '<linearGradient id="fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#11142F" stop-opacity="0"/><stop offset="1" stop-color="#11142F" stop-opacity=".55"/></linearGradient></defs>', 1)
    (OUT / f'{name}.svg').write_text(svg)


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
card('joker', '#B4419A', '#260B2C', joker, extra_defs='')
# inject pattern def for joker
p = OUT / 'joker.svg'
p.write_text(p.read_text().replace('</defs>', joker_defs + '</defs>', 1))

# ---------- CARD BACK ----------
back = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 420" width="600" height="840">
<defs>{GOLD_DEFS}
<pattern id="lat" width="24" height="24" patternUnits="userSpaceOnUse"><path d="M12 2L22 12L12 22L2 12Z" fill="none" stroke="#D4AE55" stroke-opacity=".22" stroke-width="1"/><circle cx="12" cy="12" r="1.4" fill="#D4AE55" fill-opacity=".35"/></pattern>
<radialGradient id="bg" cx=".5" cy=".5" r=".7"><stop offset="0" stop-color="#2A2466"/><stop offset="1" stop-color="#0E1130"/></radialGradient>
</defs>
<rect x="3" y="3" width="294" height="414" rx="22" fill="url(#bg)"/>
<rect x="22" y="22" width="256" height="376" rx="10" fill="url(#lat)"/>
<rect x="12" y="12" width="276" height="396" rx="15" fill="none" stroke="url(#gold)" stroke-width="2.2"/>
<rect x="22" y="22" width="256" height="376" rx="10" fill="none" stroke="#D4AE55" stroke-opacity=".5" stroke-width="1"/>
<circle cx="150" cy="210" r="78" fill="#121637" stroke="url(#gold)" stroke-width="2.5"/>
<circle cx="150" cy="210" r="68" fill="none" stroke="#D4AE55" stroke-opacity=".4" stroke-width="1"/>
<g fill="none" stroke="url(#gold)" stroke-width="2"><rect x="106" y="166" width="88" height="88"/><rect x="106" y="166" width="88" height="88" transform="rotate(45 150 210)"/></g>
<path d="M118 232L114 190L132 206L150 178L168 206L186 190L182 232Z" fill="url(#gold)"/>
<rect x="116" y="228" width="68" height="10" rx="2" fill="url(#goldh)"/>
<circle cx="150" cy="176" r="4" fill="url(#gold)"/>
<path d="M150 200l6 9-6 9-6-9z" fill="#B3243A"/>
<g fill="url(#gold)"><path d="M150 40l7 9-7 9-7-9z"/><path d="M150 362l7 9-7 9-7-9z"/></g>
</svg>'''
(OUT / 'back.svg').write_text(back)
print('ok', sorted(x.name for x in OUT.iterdir()))
