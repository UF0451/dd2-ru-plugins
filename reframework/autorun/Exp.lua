-- ============================================================
-- EXP Bar for Dragon's Dogma 2
-- Thresholds extracted directly from lvupparameteruserdata.user.2
-- ============================================================

local config_file = "reframework\\data\\exp_bar_config.json"

local exp_thresholds = {
    [2] = 200,
    [3] = 400,
    [4] = 650,
    [5] = 950,
    [6] = 1300,
    [7] = 1700,
    [8] = 2150,
    [9] = 2650,
    [10] = 3200,
    [11] = 3800,
    [12] = 4450,
    [13] = 5150,
    [14] = 5900,
    [15] = 6700,
    [16] = 7550,
    [17] = 8450,
    [18] = 9400,
    [19] = 10400,
    [20] = 11430,
    [21] = 12490,
    [22] = 13580,
    [23] = 14700,
    [24] = 15850,
    [25] = 17030,
    [26] = 18240,
    [27] = 19480,
    [28] = 20750,
    [29] = 22050,
    [30] = 23380,
    [31] = 24740,
    [32] = 26130,
    [33] = 27550,
    [34] = 29000,
    [35] = 30480,
    [36] = 31980,
    [37] = 33500,
    [38] = 35040,
    [39] = 36600,
    [40] = 38180,
    [41] = 39780,
    [42] = 41400,
    [43] = 43040,
    [44] = 44700,
    [45] = 46380,
    [46] = 48080,
    [47] = 49800,
    [48] = 51540,
    [49] = 53300,
    [50] = 55080,
    [51] = 56880,
    [52] = 58700,
    [53] = 60540,
    [54] = 62400,
    [55] = 64280,
    [56] = 66180,
    [57] = 68100,
    [58] = 70040,
    [59] = 72000,
    [60] = 73980,
    [61] = 75980,
    [62] = 77980,
    [63] = 79980,
    [64] = 81980,
    [65] = 83980,
    [66] = 85980,
    [67] = 87980,
    [68] = 89980,
    [69] = 91980,
    [70] = 93980,
    [71] = 95980,
    [72] = 97980,
    [73] = 99980,
    [74] = 101980,
    [75] = 103980,
    [76] = 105980,
    [77] = 107980,
    [78] = 109980,
    [79] = 111980,
    [80] = 113980,
    [81] = 115980,
    [82] = 117980,
    [83] = 119980,
    [84] = 121980,
    [85] = 123980,
    [86] = 125980,
    [87] = 127980,
    [88] = 129980,
    [89] = 131980,
    [90] = 133980,
    [91] = 135980,
    [92] = 137980,
    [93] = 139980,
    [94] = 141980,
    [95] = 143980,
    [96] = 145980,
    [97] = 147980,
    [98] = 149980,
    [99] = 151980,
    [100] = 153980,
    [101] = 154980,
    [102] = 155980,
    [103] = 156980,
    [104] = 157980,
    [105] = 158980,
    [106] = 159980,
    [107] = 160980,
    [108] = 161980,
    [109] = 162980,
    [110] = 163980,
    [111] = 164980,
    [112] = 165980,
    [113] = 166980,
    [114] = 167980,
    [115] = 168980,
    [116] = 169980,
    [117] = 170980,
    [118] = 171980,
    [119] = 172980,
    [120] = 173980,
    [121] = 174980,
    [122] = 175980,
    [123] = 176980,
    [124] = 177980,
    [125] = 178980,
    [126] = 179980,
    [127] = 180980,
    [128] = 181980,
    [129] = 182980,
    [130] = 183980,
    [131] = 184980,
    [132] = 185980,
    [133] = 186980,
    [134] = 187980,
    [135] = 188980,
    [136] = 189980,
    [137] = 190980,
    [138] = 191980,
    [139] = 192980,
    [140] = 193980,
    [141] = 194980,
    [142] = 195980,
    [143] = 196980,
    [144] = 197980,
    [145] = 198980,
    [146] = 199980,
    [147] = 200980,
    [148] = 201980,
    [149] = 202980,
    [150] = 203980,
    [151] = 204980,
    [152] = 205980,
    [153] = 206980,
    [154] = 207980,
    [155] = 208980,
    [156] = 209980,
    [157] = 210980,
    [158] = 211980,
    [159] = 212980,
    [160] = 213980,
    [161] = 214980,
    [162] = 215980,
    [163] = 216980,
    [164] = 217980,
    [165] = 218980,
    [166] = 219980,
    [167] = 220980,
    [168] = 221980,
    [169] = 222980,
    [170] = 223980,
    [171] = 224980,
    [172] = 225980,
    [173] = 226980,
    [174] = 227980,
    [175] = 228980,
    [176] = 229980,
    [177] = 230980,
    [178] = 231980,
    [179] = 232980,
    [180] = 233980,
    [181] = 234980,
    [182] = 235980,
    [183] = 236980,
    [184] = 237980,
    [185] = 238980,
    [186] = 239980,
    [187] = 240980,
    [188] = 241980,
    [189] = 242980,
    [190] = 243980,
    [191] = 244980,
    [192] = 245980,
    [193] = 246980,
    [194] = 247980,
    [195] = 248980,
    [196] = 249980,
    [197] = 250980,
    [198] = 251980,
    [199] = 252980,
    [200] = 253980,
    [201] = 254480,
}

-- Config stores position as 0.0-1.0 fraction of screen size for resolution independence
local cfg = json.load_file(config_file) or {
    bar_x_pct = 0.5,   -- center of screen
    bar_y_pct = 0.95,  -- near bottom
    bar_w = 400,
    bar_h = 18,
    seg_count = 10,
    seg_gap = 2,
}

local function save_config()
    json.dump_file(config_file, cfg)
end

local last_exp_gain = 0

-- Capture last EXP awarded
sdk.hook(
    sdk.find_type_definition("app.ExpDispenser"):get_method("calcExp"),
    function(args)
        return sdk.PreHookResult.CALL_ORIGINAL
    end,
    function(retval)
        local exp = sdk.to_int64(retval)
        if exp and exp > 0 then
            last_exp_gain = exp
        end
        return retval
    end
)

local font = nil

d2d.register(function()
    font = d2d.Font.new("Arial", 14, true)
end,
function()
    local sw, sh = d2d.surface_size()

    -- Convert relative position to absolute pixels
    local bar_x = math.floor(cfg.bar_x_pct * sw - cfg.bar_w / 2)
    local bar_y = math.floor(cfg.bar_y_pct * sh)

    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if not cm then return end

    local player = cm:get_field("<ManualPlayerHuman>k__BackingField")
    if not player then return end

    local status = player:get_field("<StatusContext>k__BackingField")
    if not status then return end

    local level = status:get_field("_Level")
    local exp = status:get_field("_Exp")
    local max_exp = exp_thresholds[level] or 0

    local pct = 0
    if max_exp > 0 then
        pct = math.min(exp / max_exp, 1.0)
    end

    local bar_w = cfg.bar_w
    local bar_h = cfg.bar_h
    local seg_count = cfg.seg_count
    local seg_gap = cfg.seg_gap
    local seg_w = (bar_w - (seg_count - 1) * seg_gap) / seg_count

    -- Background border
    d2d.fill_rect(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4, 0xFF000000)

    -- Segments
    for i = 0, seg_count - 1 do
        local seg_x = bar_x + i * (seg_w + seg_gap)
        local seg_fill = math.max(0, math.min(1, pct * seg_count - i))

        d2d.fill_rect(seg_x, bar_y, seg_w, bar_h, 0xFF1A1A1A)

        if seg_fill > 0 then
            d2d.fill_rect(seg_x, bar_y, seg_w * seg_fill, bar_h, 0xFF00AAFF)
        end

        d2d.outline_rect(seg_x, bar_y, seg_w, bar_h, 1, 0xFF333333)
    end

    if font then
        local max_display = max_exp > 0 and tostring(max_exp) or "МАКС"
        d2d.text(font, "Ур " .. level .. "  " .. exp .. " / " .. max_display, bar_x, bar_y - 18, 0xFFFFFFFF)

        if last_exp_gain > 0 then
            d2d.text(font, "Последнее: +" .. last_exp_gain .. " ОП", bar_x, bar_y + bar_h + 6, 0xFFAAFF00)
        end
    end
end)

re.on_draw_ui(function()
    if imgui.tree_node("Конфигурация полосы опыта") then
        local changed, val

        changed, val = imgui.slider_float("Позиция X", cfg.bar_x_pct, 0.0, 1.0, "%.2f")
        if changed then cfg.bar_x_pct = val end

        changed, val = imgui.slider_float("Позиция Y", cfg.bar_y_pct, 0.0, 1.0, "%.2f")
        if changed then cfg.bar_y_pct = val end

        changed, val = imgui.slider_int("Ширина", cfg.bar_w, 100, 1200)
        if changed then cfg.bar_w = val end

        changed, val = imgui.slider_int("Высота", cfg.bar_h, 8, 60)
        if changed then cfg.bar_h = val end

        changed, val = imgui.slider_int("Сегменты", cfg.seg_count, 2, 20)
        if changed then cfg.seg_count = val end

        changed, val = imgui.slider_int("Зазор", cfg.seg_gap, 0, 10)
        if changed then cfg.seg_gap = val end

        imgui.spacing()

        if imgui.button("Сохранить") then
            save_config()
        end

        imgui.tree_pop()
    end
end)