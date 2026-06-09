local RU_FONT_NAME = "NotoSancSB_RU.ttf"
local RU_FONT_SIZE = 18
local GLYPH_RANGES = {
    0x0020, 0x00FF,
    0x0400, 0x04FF,
    0x2000, 0x206F,
    0,
}

fontRU = imgui.load_font(RU_FONT_NAME, RU_FONT_SIZE, GLYPH_RANGES)
_G.ru_font = fontRU

log.info("[_XYZAPI]Use Default Font")
