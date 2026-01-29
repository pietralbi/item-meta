-- STATIC IMPORTS
local require = GLOBAL.require
local resolvefilepath = GLOBAL.resolvefilepath
local debug = require("itemmeta.util.debug")
local config = require("itemmeta.util.config")

-- INIT
-- Load config
debug.safecall(function()
    for key, _ in pairs(config) do
        local value = GetModConfigData(key)
        if value and value ~= "" then
            config[key] = value
        end
    end
end)

-- LOAD FONT ASSET
local ICONS_FONT_ALIAS = "itemmeta_icons"
local ICONS_FONT_FILE  = "fonts/icons.zip"
local ICONS_FONT_PATH  = resolvefilepath(ICONS_FONT_FILE)

Assets = Assets or {}
table.insert(Assets, Asset("FONT", ICONS_FONT_FILE))

local function insert_once(t, v, pred)
    if type(t) ~= "table" then return end
    for _, x in ipairs(t) do
        if pred(x) then return end
    end
    table.insert(t, v)
end

insert_once(GLOBAL.FONTS, {
    filename = ICONS_FONT_PATH,
    alias = ICONS_FONT_ALIAS,
    disable_color = true,
}, function(x) return type(x) == "table" and x.alias == ICONS_FONT_ALIAS end)

insert_once(GLOBAL.DEFAULT_FALLBACK_TABLE, ICONS_FONT_ALIAS,
    function(x) return x == ICONS_FONT_ALIAS end)

insert_once(GLOBAL.DEFAULT_FALLBACK_TABLE_OUTLINE, ICONS_FONT_ALIAS,
    function(x) return x == ICONS_FONT_ALIAS end)

-- MODIFICATIONS
local mod_interface = require("itemmeta.mod_interface")
-- Add metadata to inventory item tooltips
AddClassPostConstruct("widgets/itemtile", function(self)
    local _ItemTile_GetDescriptionString = self.GetDescriptionString
    function self:GetDescriptionString()
        local metaDescription = debug.safecall(mod_interface.GetItemMetaDescription, self.item) or ""
        return _ItemTile_GetDescriptionString(self) .. metaDescription
    end
end)

-- Add metadata to inventory item tooltips (controller mode)
AddClassPostConstruct("widgets/inventorybar", function(self)
    local _Inv_GetDescriptionString = self.GetDescriptionString
    function self:GetDescriptionString(item)
        local metaDescription = debug.safecall(mod_interface.GetItemMetaDescription, item) or ""
        return _Inv_GetDescriptionString(self, item) .. metaDescription
    end
end)

-- Fix hoverer position to avoid going off-screen
AddClassPostConstruct("widgets/hoverer", function(self)
    local _UpdatePosition = self.UpdatePosition

    function self:UpdatePosition(x, y)
        if not (self and self.shown) then
            return _UpdatePosition(self, x, y)
        end

        -- Apply only to multiline HUD/control tooltips (item tooltip), never to action hover tooltips
        local controls = self.owner and self.owner.HUD and self.owner.HUD.controls
        local is_itemtip =
            controls and controls.GetTooltip and controls:GetTooltip() ~= nil and
            (self.secondarystr == nil or self.secondarystr == "") and
            type(self.str) == "string" and self.str:find("\n", 1, true) ~= nil

        if not is_itemtip then
            return _UpdatePosition(self, x, y)
        end

        -- Need a valid measured region; if not ready yet, fall back to vanilla this tick
        local text = self.text
        if text == nil or text.GetRegionSize == nil then
            return _UpdatePosition(self, x, y)
        end

        local w, h = text:GetRegionSize()
        if not (w and h and w > 0 and h > 0) then
            return _UpdatePosition(self, x, y)
        end

        local scale = self:GetScale()
        w, h = w * scale.x, h * scale.y

        local p = text:GetPosition()
        local cx, cy = (p.x or 0) * scale.x, (p.y or 0) * scale.y

        local left, right  = cx - w/2, cx + w/2
        local bottom, top  = cy - h/2, cy + h/2

        local sw, sh = GLOBAL.TheSim:GetScreenSize()
        local m = 10

        -- Cursor is the lower limit for item tooltips
        y = math.max(y, y + m - bottom)

        -- Clamp to screen
        x = math.max(x, m - left)
        x = math.min(x, sw - m - right)

        y = math.max(y, m - bottom)
        y = math.min(y, sh - m - top)

        self:SetPosition(x, y, 0)
    end
end)

-- DS compatibility: emulate DST-style inst:CollectActions by calling DS-style component collector methods.
if GLOBAL.EntityScript ~= nil and GLOBAL.EntityScript.CollectActions == nil then
    function GLOBAL.EntityScript:CollectActions(actiontype, ...)
        if self == nil or self.components == nil or actiontype == nil then
            return
        end

        -- Map DST actiontype strings to the collector method names typically present on DS components.
        local method =
            (actiontype == "SCENE"     and "CollectSceneActions") or
            (actiontype == "INVENTORY" and "CollectInventoryActions") or
            (actiontype == "EQUIPPED"  and "CollectEquippedActions") or
            (actiontype == "POINT"     and "CollectPointActions") or
            (actiontype == "USEITEM"   and "CollectUseActions") or
            nil

        if method == nil then
            return
        end

        -- Call every component that implements that collector. Extra args are harmless in Lua.
        for _, cmp in pairs(self.components) do
            local fn = cmp[method]
            if fn ~= nil then
                fn(cmp, ...)
            end
        end
    end
end