local modname="DamageNumber"
local configfile=modname..".json"
log.info("["..modname.."]".." Старт")

-- Настройки интерфейса ImGui на русском языке (С возвращенными шрифтами)
local _config={
    {name="Стиль индикаторов урона",type="mutualbox"},
    {name="fontsize",type="fontsize",default=30,min=1,max=250,needrestart=true,widthscale=0.4,label="Размер обычного шрифта"},
    {name="",type="sameline"},
    {name="bigfontsize",type="fontsize",default=45,needrestart=true,widthscale=0.4,label="Размер шрифта крит. урона"},
    {name="font",type="font",default="times.ttf",needrestart=true,widthscale=0.4,label="Шрифт"},

    {name="color1",type="rgba32",default=0xffEEEEEE,label="Цвет урона союзников"},
    {name="",type="sameline"},
    {name="color11",type="rgba32",default=0xffEEEEEE,label="Цвет наносимого врагам урона"},
    {name="color3",type="rgba32",default=0xff00FFFF,label="Цвет критического урона"},
    {name="",type="sameline"},
    {name="color2",type="rgba32",default=0xff60609C,label="Цвет получаемого игроком урона"},
    {name="color4",type="rgba32",default=0xff2E9B16,label="Цвет периодического урона (DOT/Падение)"},

    {name="Режимы отображения",type="mutualbox"},
    {name="showDamage",type="bool",default=true,label="Показывать урон"},
    {name="showKnockdownDamage",type="bool",default=false,label="Показывать урон нокдауна (Равновесие)"},
    {name="showDamageReaction",type="bool",default=true,label="Показывать реакции (Отброшен, Сбит и т.д.)"},

    {name="Параметры анимации чисел",type="mutualbox"},
    {name="time",type="int",default=120,min=2,max=4000,label="Время отображения числа (Кадры)"},
    {name="rndoffset",type="float",default=0.2,min=0.0,max=10.0,label="Случайное смещение позиции"},
    
    {name="Формат вывода данных",type="mutualbox"},
    {name="showlefthp",type="bool",default=false,label="Показывать оставшееся здоровье цели"},{name="",type="sameline"},
    {name="showmultiplier",type="bool",default=true,label="Показывать множитель урона"},{name="",type="sameline"},
    {name="showActionRate",type="bool",default=false,label="Показывать коэффициент действия (Action Rate)"},
    {name="showDamageType",type="bool",default=false,label="Показывать тип атаки/стихию"},{name="",type="sameline"},
    {name="showDamageComposition",type="bool",default=false,label="Показывать детальную структуру урона"},{name="",type="sameline"},
    {name="showBigcapPostfix",type="bool",default=true,label="Добавлять знак '!' при критическом уроне"},
    {name="precisevalue",type="bool",default=false,label="Показывать точные значения (Дробные)"},
    {name="showDamageAtkDefAbsorption",type="bool",default=false,label="Показывать Атаку/Защиту/Поглощение игрока"},
    {name="showDamageReactionLevel",type="bool",default=false,label="Показывать уровень реакции на урон"},
    {name="showHitBodyPart",type="bool",default=false,label="Показывать пораженную часть тела NPC"},

    {name="Фильтры целей",type="mutualbox"},
    {name="showenemydamage",type="bool",default=true,label="Отображать урон по врагам"},{name="",type="sameline"},
    {name="showfrienddamage",type="bool",default=true,label="Отображать урон по союзникам/пешкам"},
    {name="shownonplayerdealandtakendamage",type="bool",default=true,label="Показывать урон сторонних NPC"},{name="",type="sameline"},
    {name="showNonBossEnemyTakenDamage",type="bool",default=true,label="Показывать урон по обычным монстрам"},
    {name="showDOT",type="bool",default=true,label="Показывать периодический урон и урон от падения"},
    
    {name="bigcap",type="int",default=1200,min=0,max=1000000,label="Порог критического урона",widthscale=0.4},
    {name="",type="sameline"},
    {name="ignorecap",type="int",default=-1,min=-1,max=1000000,label="Игнорировать урон ниже порога",widthscale=0.4},

    {name="Разное",type="mutualbox"},
    {name="showBattleLogOnScreen",type="bool",default=false,label="Выводить боевой лог на экран"},
}

local function recurse_def_settings(tbl, new_tbl)
    for key, value in pairs(new_tbl) do
        if type(tbl[key]) == type(value) then
            if type(value) == "table" then
                tbl[key] = recurse_def_settings(tbl[key], value)
            else
                tbl[key] = value
            end
        end
    end
    return tbl
end

local config = {} 
for key,para in pairs(_config) do
    config[para.name]=para.default
end
config= recurse_def_settings(config, json.load_file(configfile) or {})

local function OnChanged()
end

local battleLog={text="",lines=0}
local damageNumbers={} 
local damageTmpInfos={} 
local mainplayer=nil
local mainplayerGO=nil
local damageFieldsInDamageInfo={
    ["Рубящий"]="SlashDamage",
    ["Удар"]="BlowDamage",
    ["Выстрел"]="ShootDamage",
    ["Магия"]="MagicDamage",
    ["Зачар"]="EnchantDamage",
    ["Стихия"]="NonMagicElementDamage"
}

local guiManager=sdk.get_managed_singleton("app.GuiManager")
local colorDelta=math.floor(0xff000000/(config.time-1))&0xff000000
local posDelta=2/(config.time-1)

local GLYPH_RANGES = {
    0x0020, 0x00FF,
    0x0400, 0x04FF,
    0x2000, 0x206F,
    0,
}

-- ЗАЩИЩЕННАЯ ЗАГРУЗКА: Шрифты запрашиваются безопасно, исключая аппаратный сбой при Reset Scripts
local font = nil
local bigfont = nil

pcall(function()
    if config.font and config.font ~= "" then
        font = imgui.load_font(config.font, config.fontsize, GLYPH_RANGES)
        bigfont = imgui.load_font(config.font, config.bigfontsize, GLYPH_RANGES)
    end
    if font == nil then
        font = imgui.load_font("NotoSancSB_RU.ttf", config.fontsize, GLYPH_RANGES)
    end
    if bigfont == nil then
        bigfont = imgui.load_font("NotoSancSB_RU.ttf", config.bigfontsize, GLYPH_RANGES)
    end
end)

local function prequire(...)
    local status, lib = pcall(require, ...)
    if(status) then return lib end
    return nil
end

local function Log(msg)
    log.info(modname..msg)
end

local function getCharacterPos(char)
    if not char or not sdk.is_managed_object(char) then return Vector3f.new(0,0,0) end
    local go = char:get_GameObject()
    if not go then return Vector3f.new(0,0,0) end
    local transform = go:get_Transform()
    if not transform then return Vector3f.new(0,0,0) end
    
    local joint=transform:getJointByName("Head_0")
    local ground_joint=transform:getJointByName("root")
    
    if joint == nil then
        return ground_joint and ground_joint:get_Position() or Vector3f.new(0,0,0)
    end
    if ground_joint and (joint:get_Position().y - ground_joint:get_Position().y > 2) then
        return ground_joint:get_Position()
    end
    return joint:get_Position()
end

local function refreshplayer()
    local player_man=sdk.get_managed_singleton("app.CharacterManager")
    if not player_man then return end
    
    local ok, res = pcall(function() return player_man:get_ManualPlayer() end)
    if ok and res and sdk.is_managed_object(res) then
        mainplayer = res
        mainplayerGO = mainplayer:get_GameObject()
    else
        mainplayer = nil
        mainplayerGO = nil
    end
end

local function f2s(float)
    if config.precisevalue then return tostring(float) end
    return tostring(math.floor(float or 0))
end

local function f2s2(float)
    if config.precisevalue then return tostring(float) end
    return string.format("%.2f",float or 0)
end

local function GetEnumMap(enumName)
    local ret={}
    local tdef = sdk.find_type_definition(enumName)
    if not tdef then return ret end
    for _,field in pairs(tdef:get_fields()) do
        local value=field:get_data()
        if value~=nil and value >0 then
            ret[value]=field:get_name()
        end
    end
    return ret
end

local PhysicsAttrSettingType2Str=GetEnumMap("app.AttackUserData.PhysicsAttrSettingType")
local DamageTypeEnum2Str=GetEnumMap("app.DamageTypeEnum") or GetEnumMap("app.AttackUserData.DamageTypeEnum")
local ElementTypeEnum2Str=GetEnumMap("app.AttackUserData.ElementType")

local EN2RU_ELEMENT={
    ["None"]="нет", ["Fire"]="огонь", ["Ice"]="лёд", ["Thunder"]="молния",
    ["Holy"]="свет", ["Dark"]="тьма", ["Physical"]="физ",
}
local EN2RU_PHYSICS={
    ["Slash"]="рубящий", ["Blow"]="удар", ["Shoot"]="выстрел",
    ["Magic"]="магия", ["Enchant"]="зачар",
}
local EN2RU_DAMAGETYPE={
    ["Hitback_Weak"]="слабый", ["Hitback_Normal"]="норм", ["Hitback_Strong"]="сильный",
    ["Blown_Weak"]="слабый", ["Blown_Normal"]="норм", ["Blown_Strong"]="сильный",
    ["Blown_Launch"]="запуск", ["Blown_LaunchSmall"]="запуск(м)",
    ["Blown_Knock"]="стук", ["Blown_Spin"]="верч",
    ["RightWeapon"]="правая рука", ["LeftWeapon"]="левая рука",
    ["BothWeapons"]="оба оружия", ["Shield"]="щит", ["Magic"]="магия",
}
local EN2RU_ALL={}
for _,t in pairs({EN2RU_ELEMENT,EN2RU_PHYSICS,EN2RU_DAMAGETYPE}) do
    for k,v in pairs(t) do EN2RU_ALL[k]=v end
end

local function translate_enum_map(map)
    for k,v in pairs(map) do
        local stripped=v:gsub("^[Hh]itback_",""):gsub("^[Bb]lown_",""):gsub("^[Bb]lown","")
        if EN2RU_ALL[v] then map[k]=EN2RU_ALL[v]
        elseif EN2RU_DAMAGETYPE[v] then map[k]=EN2RU_DAMAGETYPE[v]
        elseif stripped~=v and stripped~="" then map[k]=stripped
        end
    end
end

translate_enum_map(ElementTypeEnum2Str)
translate_enum_map(PhysicsAttrSettingType2Str)
translate_enum_map(DamageTypeEnum2Str)

local function Common2Message(character,damageInfo,AttackUserData,_msg)
    local msg=_msg
    if config.showDamageType and AttackUserData~=nil then
        local parts={}
        local function add(v)
            if v and v~="" then table.insert(parts,v) end
        end
        if AttackUserData._ElementType > 0 and ElementTypeEnum2Str then
            add(ElementTypeEnum2Str[AttackUserData._ElementType])
        end
        if AttackUserData._NonMagicElementType > 0 and ElementTypeEnum2Str then
            local v=ElementTypeEnum2Str[AttackUserData._NonMagicElementType]
            if v and v~="" then add("физ"..v) end
        end
        if AttackUserData.PhysicsAttrSettingTypeValue > 0 and PhysicsAttrSettingType2Str then
            add(PhysicsAttrSettingType2Str[AttackUserData.PhysicsAttrSettingTypeValue])
        end
        if AttackUserData.DamageTypeLean > 0 and DamageTypeEnum2Str then
            add(DamageTypeEnum2Str[AttackUserData.DamageTypeLean])
        end
        if AttackUserData.DamageTypeBlown > 0 and DamageTypeEnum2Str then
            add(DamageTypeEnum2Str[AttackUserData.DamageTypeBlown])
        end
        if #parts>0 then msg=msg.." ["..table.concat(parts,"/").."]" end
    end

    if damageInfo.Damage > config.bigcap and config.showBigcapPostfix then
        msg=msg.." !"
    end
    if config.showHitBodyPart then
        msg=msg.." Часть."..tostring(damageInfo.RegionNo).."-"..tostring(damageInfo.RegionStatusNo)
    end     
    if config.showDamageReactionLevel then
        msg=msg..string.format(" Ур.Реакции.%d ",damageInfo.DmgReactionLv)
    end
    return msg
end

local function DamageNumber2Message(character,damageInfo,AttackUserData,isPlayerAttackHit)
    local msg=""
    msg=f2s(damageInfo.Damage)

    if config.showDamageComposition then
        local _msg=""
        if damageInfo.SlashDamage > 0 then _msg=_msg.." Рубящий:"..f2s(damageInfo.SlashDamage) end
        if damageInfo.BlowDamage > 0 then _msg=_msg.." Удар:"..f2s(damageInfo.BlowDamage) end
        if damageInfo.ShootDamage > 0 then _msg=_msg.." Выстрел:"..f2s(damageInfo.ShootDamage) end
        if damageInfo.MagicDamage > 0 then _msg=_msg.." Магия:"..f2s(damageInfo.MagicDamage) end
        if damageInfo.EnchantDamage > 0 then _msg=_msg.." Зачар:"..f2s(damageInfo.EnchantDamage).."*"..f2s2(damageInfo.EnchantRate) end
        if damageInfo.NonMagicElementDamage > 0 then _msg=_msg.." Стихия:"..f2s(damageInfo.NonMagicElementDamage) end
        if damageInfo.FixedDamage > 0 then _msg=_msg.." Фикс:"..f2s(damageInfo.FixedDamage) end
        if _msg ~= "" then msg=msg.." /".._msg end
    end

    if config.showActionRate and AttackUserData~=nil then
        msg=string.format("%s [%s]",msg, f2s2(AttackUserData.ActionRate))
    end
    if damageInfo.DamageRate ~=1 and config.showmultiplier==true then
        msg=msg.." (x"..f2s2(damageInfo.DamageRate) ..")"
    end

    if config.showDamageAtkDefAbsorption and isPlayerAttackHit then
        local damageTmpInfo=damageTmpInfos[damageInfo:get_address()]
        if damageTmpInfo~=nil then
            for name,field in pairs(damageFieldsInDamageInfo) do
                if damageInfo[field] > 0.01 then
                    msg=string.format("%s <%s=(%s-%s)*%s>",msg,name,f2s2(damageTmpInfo[name]),f2s2(damageTmpInfo[name.."_DEF"]),f2s2(damageTmpInfo[name.."_Ab"]))
                end
            end
        end
    end

    msg=Common2Message(character,damageInfo,AttackUserData,msg)

    if config.showlefthp and character:get_Hp() > 0 then
        msg=msg.." -> ОЗ:"..f2s(character:get_Hp()-damageInfo.Damage)
    end
    return msg
end

local function KnockdownNumber2Message(character,damageInfo,AttackUserData,isPlayerAttackHit)
    local msg=""
    local ldamage=damageInfo:get_LeanReaction()
    local bdamage=damageInfo:get_BlownReaction()
    local postrate=1
    local overthreshold=(damageInfo.OverThresholdType>0)
    if not overthreshold then
        postrate=1-damageInfo.DamageReactionSubBelowThresholdRate
        ldamage=ldamage*postrate
        bdamage=bdamage*postrate
    end

    if ldamage<=config.ignorecap and bdamage<= config.ignorecap then return nil end

    if ldamage~=bdamage then
        msg=msg..string.format(" [L:%s / B:%s]",f2s(ldamage),f2s(bdamage))
    else
        msg=msg..string.format(" [Нокд:%s]",f2s(ldamage))
    end

    if config.showActionRate and AttackUserData~=nil then
        msg=string.format("%s [%s]",msg, f2s2(AttackUserData.DmgReactionRate))
    end

    if (damageInfo.LeanReactionRate ~=1 or damageInfo.BlownReactionRate~=1 or postrate~=1) and config.showmultiplier==true then
        if damageInfo.LeanReactionRate==damageInfo.BlownReactionRate then
            msg=msg..string.format(" (x%s)",f2s2(damageInfo.LeanReactionRate))
        else
            msg=msg..string.format(" (Lx%s/Bx%s)",f2s2(damageInfo.LeanReactionRate),f2s2(damageInfo.BlownReactionRate))
        end
    end

    if config.showDamageAtkDefAbsorption and isPlayerAttackHit then
        local damageTmpInfo=damageTmpInfos[damageInfo:get_address()]
        if damageTmpInfo~=nil and damageTmpInfo["Knockdown_Msg"]~=nil then
            local tmpMsg=damageTmpInfo["Knockdown_Msg"]
            msg=string.format("%s <Нокдаун=%s>",msg,tmpMsg)
        end
    end
    
    msg=Common2Message(character,damageInfo,AttackUserData,msg)
    return msg
end

local function AddDamageNumber(character,damageInfo,reactionMsg)
    if not damageInfo or not sdk.is_managed_object(damageInfo) then return nil end
    local damageNumber={}
    local AttackUserData=damageInfo["<AttackUserData>k__BackingField"]

    if character==nil then
        local hitCtrl = damageInfo["<DamageHitController>k__BackingField"]
        character = hitCtrl and hitCtrl:get_CachedCharacter()
    end
    if character==nil or not sdk.is_managed_object(character) then return nil end

    damageNumber.pos=damageInfo:get_Position()
    if damageNumber.pos.x==0 and damageNumber.pos.y==0 and damageNumber.pos.z==0 then
        damageNumber.pos=getCharacterPos(character)
    end
    
    local isDOT=(AttackUserData==nil)
    local owner_gameobj = damageInfo["<AttackOwnerObject>k__BackingField"]    
    local isPlayerAttackHit = (owner_gameobj == mainplayerGO)
    local isPlayerTakenHit = (mainplayer == character)
    local isBossTakenHit=character:get_IsBoss()
    
    local enemyCtrl = character:get_EnemyController()
    local isEnemy = enemyCtrl and enemyCtrl:get_IsHostileArisen() or false

    local ofx=(math.random(7)-4)*config.rndoffset
    local ofy=(math.random(7)-4)*config.rndoffset
    damageNumber.pos.x=damageNumber.pos.x+ofx
    damageNumber.pos.y=damageNumber.pos.y+ofy

    if config.showKnockdownDamage then
        damageNumber.pos2=Vector3f.new(damageNumber.pos.x, damageNumber.pos.y+0.3, damageNumber.pos.z)
    end

    damageNumber.finalDamage=damageInfo.Damage    
    damageNumber.bigfont=false

    if damageInfo.Damage < config.ignorecap then return nil end

    if isDOT then
        if config.showDOT == false then return nil end
    else
        if config.shownonplayerdealandtakendamage==false and isPlayerAttackHit==false and isPlayerTakenHit==false then
            return nil
        end    
        if config.showNonBossEnemyTakenDamage==false and isBossTakenHit==false then
            return nil
        end
    end

    if isEnemy==true and config.showenemydamage==false then return nil end
    if config.showfrienddamage==false and isEnemy==false then return nil end

    if reactionMsg==nil then 
        if config.showDamage then
            damageNumber.msg=DamageNumber2Message(character,damageInfo,AttackUserData,isPlayerAttackHit)
        end
        if config.showKnockdownDamage then
            damageNumber.msg2=KnockdownNumber2Message(character,damageInfo,AttackUserData,isPlayerAttackHit)
        end
    else    
        damageNumber.msg=reactionMsg
        damageNumber.pos.y=damageNumber.pos.y+0.6
    end

    if damageInfo.Damage > config.bigcap then
        damageNumber.bigfont=true
    end  

    damageNumber.color=config.color1
    if isDOT then
        damageNumber.color=config.color4
    elseif damageInfo.Damage > config.bigcap then
        damageNumber.color=config.color3
    elseif isPlayerTakenHit then
        damageNumber.color=config.color2
    elseif isEnemy==true then
        damageNumber.color=config.color11    
    end

    if config.showBattleLogOnScreen then
        local log_str=""
        if isPlayerAttackHit==true then
            log_str=log_str.."[Нанесён урон] -> "
        elseif isPlayerTakenHit==true then
            log_str=log_str.."[Получен урон] <- "
        elseif isDOT then
            log_str=log_str.."[Урон от DOT] ~ "
        else
            log_str=log_str.."[Урон от НПЦ] "
        end
        
        if AttackUserData~=nil then
            local skill_name = tostring(AttackUserData:get_Name() or "Навык")
            if not skill_name:match("[^%s%w_%-]") then
                log_str=log_str..skill_name
            else
                log_str=log_str.."Атака"
            end
        end
        
        if damageNumber.msg~=nil then
            local safe_msg = string.gsub(damageNumber.msg, "%c", "")
            battleLog.text=battleLog.text..log_str..": "..safe_msg.."\n"
            battleLog.lines=battleLog.lines+1
        end
    end

    damageNumbers[damageNumber]=config.time
    return damageNumber
end

local function AddDamageTmpInfoBeforeCalcDef(damageInfo)
    local address=damageInfo:get_address()
    local damageTmpInfo=damageTmpInfos[address] or {lifetime=3}
    damageTmpInfos[address]=damageTmpInfo
    for name,field in pairs(damageFieldsInDamageInfo) do
        damageTmpInfo[name]=damageInfo[field]
    end
end

local function AddDamageTmpInfoAfterCalcDef(damageInfo)
    if damageInfo==nil then return end
    local address=damageInfo:get_address()
    local damageTmpInfo=damageTmpInfos[address]
    if damageTmpInfo==nil then return end
    for name,field in pairs(damageFieldsInDamageInfo) do
        damageTmpInfo[name.."_DEF"]=damageTmpInfo[name]-damageInfo[field]
    end
end

local function AddDamageTmpInfoBeforeCalcAbsorption(damageInfo)
    local address=damageInfo:get_address()
    local damageTmpInfo=damageTmpInfos[address] or {lifetime=3}
    damageTmpInfos[address]=damageTmpInfo
    for name,field in pairs(damageFieldsInDamageInfo) do
        damageTmpInfo[name.."_Ab"]=damageInfo[field]
    end
end

local function AddDamageTmpInfoAfterCalcAbsorption(damageInfo)
    if damageInfo==nil then return end
    local address=damageInfo:get_address()
    local damageTmpInfo=damageTmpInfos[address]
    if damageTmpInfo==nil then return end
    for name,field in pairs(damageFieldsInDamageInfo) do
        if damageTmpInfo[name.."_Ab"] > 0 then
            damageTmpInfo[name.."_Ab"]=damageInfo[field]/damageTmpInfo[name.."_Ab"]
        else
            damageTmpInfo[name.."_Ab"] = 0
        end
    end
end

local function AddDamageTmpInfoAfterCalcReactionAttack(playerDamageCalculator,damageInfo)
    if damageInfo==nil or playerDamageCalculator==nil then return end
    local address=damageInfo:get_address()
    local damageTmpInfo=damageTmpInfos[address]
    if damageTmpInfo==nil then return end

    local LeftWeapon=sdk.find_type_definition("app.AttackUserData.AttackWeaponTypeEnum"):get_field("LeftWeapon"):get_data()
    local msg=""
    local shellGen=playerDamageCalculator.Human and playerDamageCalculator.Human["<ShellInstantiateInfoGenerator>k__BackingField"]
    local playerAttackParameter = nil
    if shellGen ~=nil then
        local humanShellInstantiateInfo =shellGen:getShellInfo(damageInfo)
        playerAttackParameter=humanShellInstantiateInfo and humanShellInstantiateInfo["<AttackParam>k__BackingField"]
    end
    playerAttackParameter = playerAttackParameter or playerDamageCalculator.AttackParam
    if not playerAttackParameter then return end

    local playerAttackDefenceStatus =playerAttackParameter["<Status>k__BackingField"];
    if not playerAttackDefenceStatus then return end

    msg="Удар"..f2s2(playerAttackDefenceStatus["<Blow>k__BackingField"])
    damageTmpInfo["Knockdown_Msg"]=msg
    damageTmpInfo["Knockdown_ATK"]=damageInfo.DamageReaction
end

local function AddDamageTmpInfoAfterCalcReaction(damageInfo)
    if damageInfo==nil then return end
    local address=damageInfo:get_address()
    local damageTmpInfo=damageTmpInfos[address]
    if damageTmpInfo==nil then return end
    if damageTmpInfo["Knockdown_ATK"]==nil or damageTmpInfo["Knockdown_ATK"]==0 then return end
    damageTmpInfo["Knockdown_Msg"]=string.format("(%s)xПогл%s",damageTmpInfo["Knockdown_Msg"],f2s2(damageInfo.DamageReaction/damageTmpInfo["Knockdown_ATK"]))
end

local tmpUpdateDamageDamageInfo=nil
local tmpUpdateDamageHitController=nil
sdk.hook(
    sdk.find_type_definition("app.HitController"):get_method("updateDamage"),
    function(args)
        tmpUpdateDamageHitController=sdk.to_managed_object(args[2])
        tmpUpdateDamageDamageInfo=sdk.to_managed_object(args[3])
    end,
    function()
        if tmpUpdateDamageHitController and tmpUpdateDamageDamageInfo then
            local chara = tmpUpdateDamageHitController:get_CachedCharacter()
            if chara then
                local tmpUpdateDamageDamageNumber=AddDamageNumber(chara,tmpUpdateDamageDamageInfo)
            end
        end       
        tmpUpdateDamageDamageInfo=nil
        tmpUpdateDamageHitController=nil
    end
)

local tmpDamageInfoArg=nil
sdk.hook(
    sdk.find_type_definition("app.ExceptPlayerDamageCalculator"):get_method("calcDamageValueDefence(app.HitController.DamageInfo)"),
    function(args)
        if config.showDamageAtkDefAbsorption and config.showDamage then
            tmpDamageInfoArg=sdk.to_managed_object(args[3])
            if tmpDamageInfoArg then AddDamageTmpInfoBeforeCalcDef(tmpDamageInfoArg) end
        end
    end,
    function()
        if config.showDamageAtkDefAbsorption and config.showDamage and tmpDamageInfoArg then
            AddDamageTmpInfoAfterCalcDef(tmpDamageInfoArg)
        end
        tmpDamageInfoArg=nil
    end
)

local tmpDamageInfoArg2=nil
local tmpDamageInfoArg2this=nil
sdk.hook(
    sdk.find_type_definition("app.PlayerDamageCalculator"):get_method("calcDamageRactionValueAttack(app.HitController.DamageInfo)"),
    function(args)
        if config.showDamageAtkDefAbsorption and config.showKnockdownDamage then
            tmpDamageInfoArg2this=sdk.to_managed_object(args[2])
            tmpDamageInfoArg2=sdk.to_managed_object(args[3])
        end
    end,
    function()
        if config.showDamageAtkDefAbsorption and config.showKnockdownDamage and tmpDamageInfoArg2this and tmpDamageInfoArg2 then
            AddDamageTmpInfoAfterCalcReactionAttack(tmpDamageInfoArg2this,tmpDamageInfoArg2)
        end
        tmpDamageInfoArg2this=nil
        tmpDamageInfoArg2=nil
end)

local tmpDamageInfoArg3=nil
sdk.hook(
    sdk.find_type_definition("app.HitController"):get_method("calcRegionDamageRate(app.HitController.DamageInfo)"),
    function(args)
        if config.showDamageAtkDefAbsorption then
            tmpDamageInfoArg3=sdk.to_managed_object(args[3])
            if tmpDamageInfoArg3 then AddDamageTmpInfoBeforeCalcAbsorption(tmpDamageInfoArg3) end
        end
    end,
    function()
        if config.showDamageAtkDefAbsorption and tmpDamageInfoArg3 then
            AddDamageTmpInfoAfterCalcAbsorption(tmpDamageInfoArg3)
        end
        tmpDamageInfoArg3=nil
    end
)

local tmpDamageInfoArg4=nil
sdk.hook(sdk.find_type_definition("app.HitController"):get_method("calcDamageReaction"),
    function(args)
        if config.showDamageAtkDefAbsorption and config.showKnockdownDamage then
            tmpDamageInfoArg4=sdk.to_managed_object(args[3])
        end
    end,
    function ()
        if config.showDamageAtkDefAbsorption and config.showKnockdownDamage and tmpDamageInfoArg4 then
            AddDamageTmpInfoAfterCalcReaction(tmpDamageInfoArg4)
        end
        tmpDamageInfoArg4=nil
end)

local function onDamageReactionTriggered(args,msg)
    local this=sdk.to_managed_object(args[2])
    if not this or not config.showDamageReaction then return end
    local damageInfo=this["<DamageInfo>k__BackingField"]
    if damageInfo and damageInfo.DamageType>0 then
        local hitDamageType=DamageTypeEnum2Str[damageInfo.DamageActType] or "Удар"
        hitDamageType=string.gsub(hitDamageType,"Hitback_","")
        hitDamageType=string.gsub(hitDamageType,"Blown_","")
        msg =msg.."("..hitDamageType..")!"
    end
    if damageInfo then
        AddDamageNumber(this["<Chara>k__BackingField"],damageInfo,msg)
    end
end

sdk.hook(sdk.find_type_definition("app.CommonDamageReaction"):get_method("selectDamageActionShrink"), function(args) onDamageReactionTriggered(args,"Сжатие") end, nil)
sdk.hook(sdk.find_type_definition("app.CommonDamageReaction"):get_method("selectDamageActionHitdown"), function(args) onDamageReactionTriggered(args,"Сбит") end, nil)
sdk.hook(sdk.find_type_definition("app.CommonDamageReaction"):get_method("selectDamageActionBlown"), function(args) onDamageReactionTriggered(args,"Отброшен") end, nil)
sdk.hook(sdk.find_type_definition("app.CommonDamageReaction"):get_method("selectDamageActionLargeCharaDown"), function(args) onDamageReactionTriggered(args,"Падение") end, nil)

local function DrawDamageNumber(damageNumber)
    if not damageNumber or not damageNumber.pos then return end
    
    local screenPos = draw.world_to_screen(damageNumber.pos)
    if screenPos and damageNumber.msg then
        draw.text(damageNumber.msg, screenPos.x, screenPos.y, damageNumber.color)
    end
    
    if damageNumber.pos2 and damageNumber.msg2 then
        local screenPos2 = draw.world_to_screen(damageNumber.pos2)
        if screenPos2 then
            draw.text(damageNumber.msg2, screenPos2.x, screenPos2.y, damageNumber.color)
        end
    end

    damageNumbers[damageNumber]=damageNumbers[damageNumber]-1
    damageNumber.pos.y=damageNumber.pos.y+posDelta
    if damageNumber.pos2~=nil then 
        damageNumber.pos2.y=damageNumber.pos2.y+posDelta
    end
    damageNumber.color=damageNumber.color-colorDelta
    if damageNumbers[damageNumber] <= 0 then
        damageNumbers[damageNumber]=nil
    end    
end

local frame_ct=0
re.on_frame(function()
    frame_ct=frame_ct+1
    
    -- Безопасное наложение кастомных шрифтов через условную валидацию
    if font then imgui.push_font(font) end
    for k,v in pairs(damageNumbers) do
        if k.bigfont==nil or k.bigfont==false then
            DrawDamageNumber(k)
        end
    end
    if font then imgui.pop_font() end

    if bigfont then imgui.push_font(bigfont) end
    for k,v in pairs(damageNumbers) do
        if k.bigfont then            
            DrawDamageNumber(k)
        end
    end
    if bigfont then imgui.pop_font() end
    
    if frame_ct>30 then
        frame_ct=0
        for k,v in pairs(damageTmpInfos) do
            v.lifetime=v.lifetime-1
            if v.lifetime<0 then damageTmpInfos[k]=nil end
        end
    end

    if config.showBattleLogOnScreen and battleLog.lines > 0 then
        draw.text(battleLog.text, 50, 50, 0xffffffff)
        if battleLog.lines > 35 then 
            battleLog.text=""
            battleLog.lines=0
        end
    end
end)

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),nil, function() pcall(refreshplayer) end)
pcall(refreshplayer)

local myapi = prequire("_XYZApi/_XYZApi")
if myapi~=nil then myapi.DrawIt(modname,configfile,_config,config,OnChanged) end