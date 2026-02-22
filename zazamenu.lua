-- ============================================================
-- ZAZA MENU v1.3  |  Matcha executor
-- Features: Auto Clicker | Anti-AFK | Fly | Custom ESP
-- Toggle UI: F2  (rebindable in Options)
-- Fly: W/A/S/D | Space = up | LShift/LCtrl = down
-- ============================================================

local _Players = game:GetService("Players")
local _lp = _Players.LocalPlayer
while not _lp do task.wait(0.1); _lp = _Players.LocalPlayer end
while not _lp.Character do task.wait(0.1) end


--  NASKA UI LIBRARY
local ui = (function()

local rgb = Color3.fromRGB
local function v2(x, y)
    return Vector2.new(math.floor(x or 0), math.floor(y or 0))
end

local ui = {}
do
    ui.__index = ui

    local plrs  = game.Players
    local plr   = plrs.LocalPlayer
    while not plr do task.wait(0.1); plr = plrs.LocalPlayer end
    local mouse = plr:GetMouse()
    local uis   = game:GetService("UserInputService")
    local http  = game:GetService("HttpService")
    local clock = os.clock

    local function hsvToRgb(h, s, v)
        local r, g, b
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)
        i = i % 6
        if i == 0 then r, g, b = v, t, p
        elseif i == 1 then r, g, b = q, v, p
        elseif i == 2 then r, g, b = p, v, t
        elseif i == 3 then r, g, b = p, q, v
        elseif i == 4 then r, g, b = t, p, v
        elseif i == 5 then r, g, b = v, p, q
        end
        return rgb(r * 255, g * 255, b * 255)
    end

    local function rgbToHsv(color)
        local r, g, b = color.R, color.G, color.B
        local max, min = math.max(r, g, b), math.min(r, g, b)
        local h, s, v
        v = max
        local d = max - min
        if max == 0 then s = 0 else s = d / max end
        if max == min then
            h = 0
        else
            if max == r then h = (g - b) / d + (g < b and 6 or 0)
            elseif max == g then h = (b - r) / d + 2
            elseif max == b then h = (r - g) / d + 4
            end
            h = h / 6
        end
        return h, s, v
    end

    local function mp() return v2(mouse.X, mouse.Y) end

    local function mousebound(pos, size)
        local m = mp()
        return m.X >= pos.X and m.X <= pos.X + size.X and m.Y >= pos.Y and m.Y <= pos.Y + size.Y
    end

    local function change(inst, tab)
        if typeof(inst) == "table" and #inst > 0 then
            for _, v_ in inst do
                for i, v in tab do if v_[i] ~= v then v_[i] = v end end
            end
        else
            for i, v in tab do if inst[i] ~= v then inst[i] = v end end
        end
    end

    local function create(drawing, properties)
        local d = Drawing.new(drawing)
        if drawing == "Square" then d.Position = v2(0,0); d.Size = v2(0,0); d.Filled = false
        elseif drawing == "Line" then d.From = v2(0,0); d.To = v2(0,0); d.Thickness = 1
        elseif drawing == "Circle" then d.Position = v2(0,0); d.Radius = 0; d.NumSides = 12; d.Thickness = 1
        elseif drawing == "Text" then d.Position = v2(0,0); d.Text = ""; d.Size = 14; d.Font = Drawing.Fonts.UI
        end
        change(d, properties)
        return d
    end

    local function lerp(a, b, t) return a + (b - a) * t end
    local function getLerp(l, delta) return 1 - (0.5 ^ (delta * l * 60)) end

    local function lerpRGB(c1, c2, t)
        local ok, r = pcall(function()
            return rgb(math.floor(lerp(c1.R*255, c2.R*255, t)), math.floor(lerp(c1.G*255, c2.G*255, t)), math.floor(lerp(c1.B*255, c2.B*255, t)))
        end)
        return ok and r or c1
    end

    local function textbound(str, textSize)
        textSize = textSize or 14
        return #str * (textSize * 0.65), textSize
    end

    local function centertext(text, pos, size)
        local t = textbound(text)
        return v2(pos.X + (size.X/2) - (t/2), pos.Y + (size.Y/2) - 8)
    end

    local function truncate(num, dp)
        local mult = 10^(dp or 0)
        return math.floor(num * mult) / mult
    end

    local function countDecimalPlaces(num)
        local str = tostring(num)
        local dp = string.find(str, "%.")
        return dp and (#str - dp) or 0
    end

    local function createGradient(frameRect, colorStart, colorEnd, breaks)
        local cs, ce = colorStart, colorEnd
        local bands = {}
        if not frameRect.Position then frameRect.Position = v2() end
        if not frameRect.Size then frameRect.Size = v2() end
        local bh = frameRect.Size.Y / breaks
        for i = 0, breaks - 1 do
            local t = i / (breaks - 1)
            local rect = Drawing.new("Square")
            rect.Filled = true; rect.Color = lerpRGB(cs, ce, t)
            rect.Size = Vector2.new(frameRect.Size.X, math.ceil(bh))
            rect.Position = Vector2.new(frameRect.Position.X, frameRect.Position.Y + i * bh)
            table.insert(bands, rect)
        end
        return setmetatable({
            Remove = function() for _,v in bands do v:Remove() end end,
            ChangeColor = function(a, b)
                cs = a; ce = b
                for i, v in bands do v.Color = lerpRGB(cs, ce, i / (breaks - 1)) end
            end
        }, {
            __index = function(_, index)
                if index == "Size" then return frameRect.Size end
                return bands[1][index]
            end,
            __newindex = function(_, index, val)
                for i, v in bands do
                    if index == "Size" then
                        frameRect.Size = val; bh = frameRect.Size.Y / breaks
                        v.Size = v2(val.X, math.ceil(bh))
                        v.Position = v2(frameRect.Position.X, frameRect.Position.Y + i * bh)
                    elseif index == "Position" then
                        frameRect.Position = val
                        v.Position = v2(frameRect.Position.X, frameRect.Position.Y + i * bh)
                    elseif index ~= "Color" then v[index] = val end
                end
            end
        })
    end

    local function createHorizontalGradient(frameRect, colorStart, colorEnd, breaks)
        local cs, ce = colorStart, colorEnd
        local bands = {}
        if not frameRect.Position then frameRect.Position = v2() end
        if not frameRect.Size then frameRect.Size = v2() end
        local bw = frameRect.Size.X / breaks
        for i = 0, breaks - 1 do
            local rect = Drawing.new("Square")
            rect.Filled = true; rect.Color = lerpRGB(cs, ce, i / (breaks - 1))
            rect.Size = Vector2.new(math.ceil(bw), frameRect.Size.Y)
            rect.Position = Vector2.new(frameRect.Position.X + i * bw, frameRect.Position.Y)
            table.insert(bands, rect)
        end
        return setmetatable({
            Remove = function() for _,v in bands do v:Remove() end end,
            ChangeColor = function(_, a, b)
                cs = a; ce = b
                for i, v in bands do v.Color = lerpRGB(cs, ce, i / (breaks - 1)) end
            end
        }, {
            __index = function(_, index)
                if index == "Size" then return frameRect.Size end
                return bands[1][index]
            end,
            __newindex = function(_, index, val)
                for i, v in bands do
                    if index == "Size" then
                        frameRect.Size = val; bw = frameRect.Size.X / breaks
                        v.Size = v2(math.ceil(bw), val.Y)
                        v.Position = v2(frameRect.Position.X + i * bw, frameRect.Position.Y)
                    elseif index == "Position" then
                        frameRect.Position = val
                        v.Position = v2(frameRect.Position.X + i * bw, frameRect.Position.Y)
                    elseif index ~= "Color" then v[index] = val end
                end
            end
        })
    end

    local function createVerticalGradientAlpha(frameRect, color, alphaTop, alphaBottom, breaks)
        local at, ab = alphaTop, alphaBottom
        local bands = {}
        if not frameRect.Position then frameRect.Position = v2() end
        if not frameRect.Size then frameRect.Size = v2() end
        local bh = frameRect.Size.Y / breaks
        for i = 0, breaks - 1 do
            local t = i / (breaks - 1)
            local rect = Drawing.new("Square")
            rect.Filled = true; rect.Color = color
            rect.Transparency = lerp(at, ab, t)
            rect.Size = Vector2.new(frameRect.Size.X, math.ceil(bh))
            rect.Position = Vector2.new(frameRect.Position.X, frameRect.Position.Y + i * bh)
            table.insert(bands, rect)
        end
        return setmetatable({
            Remove = function() for _,v in bands do v:Remove() end end,
            ChangeAlpha = function(_, a, b)
                at = a; ab = b
                for i, v in bands do v.Transparency = lerp(at, ab, i / (breaks - 1)) end
            end
        }, {
            __index = function(_, index)
                if index == "Size" then return frameRect.Size end
                return bands[1][index]
            end,
            __newindex = function(_, index, val)
                for i, v in bands do
                    if index == "Size" then
                        frameRect.Size = val; bh = frameRect.Size.Y / breaks
                        v.Size = v2(val.X, math.ceil(bh))
                        v.Position = v2(frameRect.Position.X, frameRect.Position.Y + i * bh)
                    elseif index == "Position" then
                        frameRect.Position = val
                        v.Position = v2(frameRect.Position.X, frameRect.Position.Y + i * bh)
                    elseif index == "Transparency" then
                        v.Transparency = lerp(at, ab, i / (breaks - 1)) * val
                    else v[index] = val end
                end
            end
        })
    end

    local function createOutline(v, color, zindex)
        local out = Drawing.new("Square")
        change(out, {
            Position = v.Position + Vector2.new(1, 1),
            Size = v.Size + Vector2.new(-2, -2),
            Filled = true,
            Color = color or rgb(148, 156, 187),
            ZIndex = zindex or -1
        })
        return out
    end

    function ui:create(title, settings)
        local self = setmetatable({}, ui)
        settings = settings or {}

        self.keys = {
            delete={mem=0x2E}, minus={mem=0xBD}, mouse1={mem=0x01}, mouse2={mem=0x02},
            mouse3={mem=0x04}, leftshift={mem=0xA0},
            ["0"]={mem=0x30},["1"]={mem=0x31},["2"]={mem=0x32},["3"]={mem=0x33},
            ["4"]={mem=0x34},["5"]={mem=0x35},["6"]={mem=0x36},["7"]={mem=0x37},
            ["8"]={mem=0x38},["9"]={mem=0x39},
            a={mem=0x41},b={mem=0x42},c={mem=0x43},d={mem=0x44},e={mem=0x45},
            f={mem=0x46},g={mem=0x47},h={mem=0x48},i={mem=0x49},j={mem=0x4A},
            k={mem=0x4B},l={mem=0x4C},m={mem=0x4D},n={mem=0x4E},o={mem=0x4F},
            p={mem=0x50},q={mem=0x51},r={mem=0x52},s={mem=0x53},t={mem=0x54},
            u={mem=0x55},v={mem=0x56},w={mem=0x57},x={mem=0x58},y={mem=0x59},
            z={mem=0x5A},tab={mem=0x09},backspace={mem=0x08},
            numpad0={mem=0x60},numpad1={mem=0x61},numpad2={mem=0x62},numpad3={mem=0x63},
            numpad4={mem=0x64},numpad5={mem=0x65},numpad6={mem=0x66},numpad7={mem=0x67},
            numpad8={mem=0x68},numpad9={mem=0x69},
            multiply={mem=0x6A},add={mem=0x6B},separator={mem=0x6C},subtract={mem=0x6D},
            decimal={mem=0x6E},divide={mem=0x6F},
            f1={mem=0x70},f2={mem=0x71},f3={mem=0x72},f4={mem=0x73},f5={mem=0x74},
            f6={mem=0x75},f7={mem=0x76},f8={mem=0x77},f9={mem=0x78},f10={mem=0x79},
            f11={mem=0x7A},f12={mem=0x7B},f13={mem=0x7C},f14={mem=0x7D},f15={mem=0x7E},
            f16={mem=0x7F},f17={mem=0x80},f18={mem=0x81},f19={mem=0x82},f20={mem=0x83},
            f21={mem=0x84},f22={mem=0x85},f23={mem=0x86},f24={mem=0x87},
            numlock={mem=0x90},lcontrol={mem=0xA2},rcontrol={mem=0xA3},
            leftalt={mem=0xA4},rightalt={mem=0xA5},rshift={mem=0xA1},space={mem=0x20},
            return_key={mem=0x0D},escape={mem=0x1B},period={mem=0xBE},comma={mem=0xBC},
            slash={mem=0xBF},semicolon={mem=0xBA},quote={mem=0xDE},lbracket={mem=0xDB},
            rbracket={mem=0xDD},backslash={mem=0xDC},equals={mem=0xBB},
        }
        for _, v in self.keys do v.click = false; v.hold = false end
        self.key_timers = {}

        self.w = settings.size and settings.size.X or 500
        self.h = settings.size and settings.size.Y or 700

        local middle = workspace.CurrentCamera.ViewportSize * 0.5 - v2(self.w, self.h) * 0.5
        self.x = middle.X; self.y = middle.Y

        self.name      = title or "n/a"
        self.padding   = 6
        self.th        = 25
        self.taboffset = 45
        self.tabs      = {}
        self.currenttab = 1
        self.closebind  = "f2"
        self.transparency = 1
        self.open    = true
        self.running = true
        self.border  = 0
        self.focused_textbox = nil

        self.themes = {
            cyberpunk = {
                base=rgb(24,24,24),mantle=rgb(19,19,19),crust=rgb(12,12,12),
                text=rgb(255,255,255),subtext0=rgb(160,160,160),subtext1=rgb(160,160,160),
                surface0=rgb(34,34,34),surface1=rgb(45,45,45),surface2=rgb(50,50,50),
                overlay0=rgb(100,100,100),overlay1=rgb(100,100,100),overlay2=rgb(100,100,100),
                accent=rgb(255,0,85),blue=rgb(255,0,85),red=rgb(255,0,85),green=rgb(255,0,85),
                yellow=rgb(255,0,85),magenta=rgb(255,0,85),teal=rgb(255,0,85),
                rosewater=rgb(255,0,85),flamingo=rgb(255,0,85),pink=rgb(255,0,85),
                mauve=rgb(255,0,85),maroon=rgb(255,0,85),peach=rgb(255,0,85),
                sky=rgb(255,0,85),sapphire=rgb(255,0,85),lavender=rgb(255,0,85),
            },
            gamesense = {
                base=rgb(24,24,24),mantle=rgb(19,19,19),crust=rgb(12,12,12),
                text=rgb(220,220,220),subtext0=rgb(140,140,140),subtext1=rgb(140,140,140),
                surface0=rgb(32,32,32),surface1=rgb(42,42,42),surface2=rgb(52,52,52),
                overlay0=rgb(80,80,80),overlay1=rgb(80,80,80),overlay2=rgb(80,80,80),
                accent=rgb(138,226,52),blue=rgb(138,226,52),red=rgb(138,226,52),
                green=rgb(138,226,52),yellow=rgb(138,226,52),magenta=rgb(138,226,52),
                teal=rgb(138,226,52),rosewater=rgb(138,226,52),flamingo=rgb(138,226,52),
                pink=rgb(138,226,52),mauve=rgb(138,226,52),maroon=rgb(138,226,52),
                peach=rgb(138,226,52),sky=rgb(138,226,52),sapphire=rgb(138,226,52),
                lavender=rgb(138,226,52),
            },
            bitchbot = {
                base=rgb(31,31,31),mantle=rgb(31,31,31),crust=rgb(0,0,0),
                text=rgb(202,201,201),subtext0=rgb(100,100,100),subtext1=rgb(100,100,100),
                surface0=rgb(41,42,40),surface1=rgb(41,42,40),surface2=rgb(53,52,52),
                overlay0=rgb(53,52,52),overlay1=rgb(53,52,52),overlay2=rgb(53,52,52),
                accent=rgb(120,85,147),blue=rgb(120,85,147),red=rgb(120,85,147),
                green=rgb(120,85,147),yellow=rgb(120,85,147),magenta=rgb(120,85,147),
                teal=rgb(120,85,147),rosewater=rgb(120,85,147),flamingo=rgb(120,85,147),
                pink=rgb(120,85,147),mauve=rgb(120,85,147),maroon=rgb(120,85,147),
                peach=rgb(120,85,147),sky=rgb(120,85,147),sapphire=rgb(120,85,147),
                lavender=rgb(120,85,147),
            },
        }

        self.theme      = "gamesense"
        self.themenames = {"cyberpunk","gamesense","bitchbot"}
        self.colors     = self.themes[self.theme]
        self._last      = clock()
        self.minH = 300; self.minW = 400

        local main         = create("Square",{Filled=true, Color=self.colors.base})
        local main_outline = createOutline(main, self.colors.crust, -1)
        local mantle       = create("Square",{Filled=true, Color=self.colors.mantle})
        local text         = create("Text",{Text=self.name, Color=self.colors.text, ZIndex=3, Outline=false})
        local gradient     = createGradient({Position=v2(self.x,self.y), Size=v2(self.w,self.th)}, self.colors.base, self.colors.surface0, 25)
        local gradient_out = create("Line",{ZIndex=1, Thickness=2})
        gradient.ZIndex    = 2
        local resize_handle = create("Square",{Filled=true, Color=self.colors.surface0, Size=v2(10,10), ZIndex=3})
        self._resizing = false

        self.watermark = {
            container  = create("Square",{Filled=true, Color=self.colors.base, ZIndex=2000, Visible=false}),
            outline    = create("Square",{Filled=false, Color=self.colors.crust, ZIndex=1999, Visible=false}),
            accent_bar = create("Square",{Filled=true, Color=self.colors.accent, ZIndex=2001, Visible=false}),
            label      = create("Text",{Text="zazamenu | @"..plr.Name, Color=self.colors.text, Size=17.5, ZIndex=2002, Visible=false})
        }

        self._dcache = {main, main_outline, mantle, text, gradient, gradient_out, resize_handle}

        self.picker = {
            active=nil, h=0, s=0, v=1,
            container    = create("Square",{Filled=true, Color=rgb(100,100,100), ZIndex=50, Visible=false}),
            outline      = nil,
            hue_bar      = {},
            sv_underlay  = createHorizontalGradient({Size=v2(140,140), Position=v2(0,0)}, rgb(255,255,255), rgb(255,0,0), 140),
            sv_overlay   = createVerticalGradientAlpha({Size=v2(140,140), Position=v2(0,0)}, rgb(0,0,0), 0, 1, 140),
            pointer      = create("Circle",{Radius=4, Filled=false, Thickness=2, Color=rgb(255,255,255), ZIndex=55, Visible=false}),
            hue_indicator= create("Square",{Size=v2(2,15), Filled=true, Color=rgb(255,255,255), ZIndex=55, Visible=false}),
        }
        self.picker.sv_underlay.ZIndex = 51
        self.picker.sv_overlay.ZIndex  = 52
        self.picker.hue_indicator.ZIndex = 55
        self.picker.outline = createOutline(self.picker.container, self.colors.crust, 1)
        self.picker.outline.ZIndex = 50; self.picker.outline.Filled = false

        local hue_colors = {rgb(255,0,0),rgb(255,255,0),rgb(0,255,0),rgb(0,255,255),rgb(0,0,255),rgb(255,0,255),rgb(255,0,0)}
        for i = 1, 6 do
            self.picker.hue_bar[i] = createHorizontalGradient({Size=v2(140/6,15), Visible=false}, hue_colors[i], hue_colors[i+1], 30)
            self.picker.hue_bar[i].ZIndex = 51
        end

        self.notifications = {}
        for _, v in self._dcache do v.Transparency = 1 end

        self.overlay = create("Square",{Filled=true, Color=rgb(0,0,0), ZIndex=-10, Visible=false, Transparency=0})

        if uis and uis.InputChanged then
            uis.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel and self.open then
                    for _, tab in ipairs(self.tabs) do
                        if self.tabs[self.currenttab] == tab then
                            for _, section in ipairs(tab.sections) do
                                if mousebound(section.section_container.Position, section.section_container.Size) then
                                    local sub = section.sections[section.index]
                                    if sub then
                                        local max_scroll = math.max(0, sub.total_height - (section.section_container.Size.Y - section.buttonbg.Size.Y - 10))
                                        sub.scroll = math.clamp(sub.scroll - (input.Position.Z * 20), 0, max_scroll)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        return self
    end

    function ui:step()
        local delta = clock() - self._last
        self._last = clock()
        local m = mp()

        setrobloxinput(not self.open)

        for _, v in self.keys do
            local down = iskeypressed(v.mem)
            if down then
                v.click = not v.hold
                v.hold  = true
            else
                v.click = false
                v.hold  = false
            end
        end

        if self.keys[self.closebind].click then self.open = not self.open end
        if not self.open then self.keys.mouse1.click = false; self.keys.mouse1.hold = false end

        if self.focused_textbox then
            local textbox = self.focused_textbox
            if self.keys.return_key.click or self.keys.escape.click or self.keys.mouse1.click then
                textbox.focused = false; self.focused_textbox = nil
            else
                if self.keys.backspace.click or (self.keys.backspace.hold and clock() > (self.bs_timer or 0)) then
                    self.bs_timer = clock() + (self.keys.backspace.click and 0.4 or 0.05)
                    if #textbox.text > 0 then
                        textbox.text = textbox.text:sub(1, -2)
                        if textbox.callback then textbox.callback(textbox.text) end
                        self._needs_save = true
                    end
                end
                local shift = self.keys.leftshift.hold or self.keys.rshift.hold
                for keyname, keydata in pairs(self.keys) do
                    if keydata.click or (keydata.hold and clock() > (self.key_timers[keyname] or 0)) then
                        self.key_timers[keyname] = clock() + (keydata.click and 0.4 or 0.05)
                        local char
                        if #keyname == 1 then char = keyname
                        elseif keyname:match("numpad%d") then char = keyname:sub(7)
                        elseif keyname=="space" then char=" " elseif keyname=="minus" then char="-"
                        elseif keyname=="equals" then char="=" elseif keyname=="period" then char="."
                        elseif keyname=="comma" then char="," elseif keyname=="slash" then char="/"
                        elseif keyname=="semicolon" then char=";" elseif keyname=="quote" then char="'"
                        elseif keyname=="lbracket" then char="[" elseif keyname=="rbracket" then char="]"
                        elseif keyname=="backslash" then char="\\"
                        end
                        if char then
                            if shift then
                                if char:match("%a") then char = char:upper() end
                                local sh = {["1"]="!",["2"]="@",["3"]="#",["4"]="$",["5"]="%",["6"]="^",["7"]="&",["8"]="*",["9"]="(",["0"]=")",
                                    ["-"]="_",["="]="+",["["]="{", ["]"]="}",  [";"]=":", ["'"]='"', [","]="<",["."]=">", ["/"]=">", ["\\"]="|"}
                                if sh[char] then char = sh[char] end
                            end
                            textbox.text = textbox.text .. char
                            if textbox.callback then textbox.callback(textbox.text) end
                            self._needs_save = true
                        end
                    end
                end
            end
        end

        local function ft(transparency)
            local target = self.transparency
            if math.abs(transparency - target) < 0.001 then return target end
            return lerp(transparency, target, getLerp(.35, delta))
        end

        local _d = self._dcache
        local _c = self.colors
        local main         = _d[1]; local main_outline = _d[2]; local mantle = _d[3]
        local title_text   = _d[4]; local gradient = _d[5]; local gradient_out = _d[6]
        local resize_handle = _d[7]

        local tOvTrans = self.open and 0.65 or 0
        if math.abs(self.overlay.Transparency - tOvTrans) > 0.001 then
            self.overlay.Transparency = lerp(self.overlay.Transparency, tOvTrans, getLerp(.15, delta))
        else self.overlay.Transparency = tOvTrans end

        change(self.overlay, {Position=v2(0,0), Size=workspace.CurrentCamera.ViewportSize, Visible=self.overlay.Transparency > 0})

        if self.open then
            local hp = v2(self.x + self.w - 10, self.y + self.h - 10)
            if mousebound(hp, v2(10,10)) and self.keys.mouse1.click then self._resizing = true end
            if not self.keys.mouse1.hold then self._resizing = false end
            if self._resizing then
                self.w = math.max(400, m.X - self.x)
                self.h = math.max(self.minH or 300, m.Y - self.y)
            end
        end

        if self.watermark_enabled ~= false then
            local wt = self.watermark.label.Text
            local tw = textbound(wt)
            local bs = v2(tw + 30, 30)
            local pos = v2(workspace.CurrentCamera.ViewportSize.X - bs.X - 20, 20)
            change(self.watermark.container,  {Size=bs, Position=pos, Visible=true, Transparency=1})
            change(self.watermark.outline,    {Size=bs+v2(2,2), Position=pos-v2(1,1), Visible=true, Transparency=1})
            change(self.watermark.accent_bar, {Size=v2(bs.X,2), Position=pos, Visible=true, Transparency=1, Color=_c.accent})
            change(self.watermark.label,      {Position=pos+v2(15,(bs.Y/2)-8), Visible=true, Transparency=1, Color=_c.text})
        else
            change(self.watermark.container, {Visible=false}); change(self.watermark.outline, {Visible=false})
            change(self.watermark.accent_bar,{Visible=false}); change(self.watermark.label,   {Visible=false})
        end

        change(main,         {Position=v2(self.x,self.y), Size=v2(self.w,self.h), Transparency=ft(main.Transparency)})
        change(main_outline, {Position=v2(self.x,self.y)-v2(.5,.5)*self.border, Size=v2(self.w+self.border,self.h+self.border)})
        change(resize_handle,{Position=v2(self.x+self.w-10,self.y+self.h-10), Visible=self.open, Transparency=ft(0.5)})
        change(title_text,   {Position=v2(self.x+5, self.y+self.th/2-6)})
        change(mantle,       {Position=v2(self.x+self.padding/2, self.y+(self.th+self.taboffset)+self.padding/2), Size=v2(self.w-self.padding, self.h-(self.th+self.taboffset)-self.padding)})
        if gradient then change(gradient, {Position=v2(self.x,self.y), Size=v2(self.w,self.th)}) end
        if gradient_out then
            change(gradient_out, {From=v2(self.x,self.y+self.th+(gradient_out.Thickness or 1)), To=v2(self.x+self.w,self.y+self.th+(gradient_out.Thickness or 1)), Color=_c.crust})
        end
        for _, v in _d do v.Transparency = ft(v.Transparency) end
        self.transparency = self.open and (self.customtransparency or 1) or 0

        if mousebound(main.Position, v2(self.w, self.th)) and self.open then
            if self.keys.mouse1.click then self._dragging = true; self._dragoffset = m - v2(self.x, self.y) end
        end
        if self._dragging then
            if self.keys.mouse1.hold then self.x = m.X - self._dragoffset.X; self.y = m.Y - self._dragoffset.Y
            else self._dragging = false end
            self.keys.mouse1.click = false
        end

        local tabWidth  = (self.w - self.padding * (#self.tabs + 1)) / math.max(#self.tabs, 1)
        local tabHeight = self.taboffset - self.padding

        for i, tab in self.tabs do
            local tabX = self.x + self.padding + (i-1) * (tabWidth + self.padding)
            local tabY = self.y + self.th + self.padding + 1

            change(tab.button, {Position=v2(tabX,tabY), Size=v2(tabWidth,tabHeight-self.padding*2), Transparency=ft(tab.button.Transparency), ZIndex=2})
            change(tab.buttonoutline, {Position=tab.button.Position-v2(1,1), Size=tab.button.Size+v2(2,3), Transparency=ft(tab.button.Transparency), Color=_c.crust})
            if mousebound(tab.button.Position, tab.button.Size) and self.keys.mouse1.click then self.currenttab = i end
            change(tab.text, {Position=centertext(tab.text.Text,tab.button.Position,tab.button.Size), Transparency=ft(tab.text.Transparency), Color=self.currenttab==i and _c.text or _c.subtext1})

            if self.currenttab == i then
                for _, section in ipairs(tab.sections) do for _, d in ipairs(section._dcache) do d.Visible = true end end
                tab.button.ChangeColor(_c.base, _c.overlay)
            else
                tab.button.ChangeColor(_c.mantle, _c.crust)
            end

            if self.currenttab == i then
                local col_offsets = {left=0, right=0}

                for _, section in tab.sections do
                    for _, v in section._dcache do v.Transparency = ft(v.Transparency) end

                    local sc   = section.section_container
                    local side = section.side or "left"
                    local hasLeft   = tab.side.left  > 0
                    local hasRight  = tab.side.right > 0
                    local sidesUsed = (hasLeft and 1 or 0) + (hasRight and 1 or 0)
                    local width     = (mantle.Size.X / sidesUsed) - self.padding * 2
                    local xPos      = self.padding + mantle.Position.X
                    if sidesUsed > 1 and side == "right" then xPos = xPos + width + self.padding * 2 end

                    local calc_h  = section.manual_height or (section.sections[section.index] and (section.sections[section.index].total_height + self.padding*2+15) or 100)
                    local toff    = 18
                    local remain  = math.max(70, mantle.Size.Y - col_offsets[side] - toff)
                    calc_h = math.clamp(calc_h, 70, remain)

                    change(sc, {Position=v2(xPos,(self.padding+mantle.Position.Y)+col_offsets[side]+toff), Size=v2(width,calc_h-self.padding*2), Color=_c.base})
                    col_offsets[side] = col_offsets[side] + calc_h + toff

                    change(section.section_outline, {Position=sc.Position-v2(1,1), Size=sc.Size+v2(2,2), Color=_c.crust})
                    change(section.buttonbg, {Visible=false, Transparency=0})
                    change(section.button,   {Visible=false, Transparency=0})

                    if #section.sections == 1 then
                        local sub = section.sections[1]
                        change(sub.button, {Visible=false})
                        change(sub.buttontext, {Text=sub.name, Position=sc.Position-v2(0,16), Color=_c.text, Visible=true, Transparency=ft(sub.buttontext.Transparency)})
                    end

                    for num, sub in section.sections do
                        local selected = section.index == num
                        local itemY    = (sc.Position.Y + self.padding + 4) + 1
                        local clip_min = sc.Position.Y
                        local clip_max = sc.Position.Y + sc.Size.Y
                        sub.total_height = 0

                        for _, item in sub.elements do
                            if not selected then
                                item.ignoreVisible = true
                                for _, v in item._dcache do v.Visible = false end
                                continue
                            else
                                item.ignoreVisible = false
                            end

                            local curY  = itemY - sub.scroll
                            local iH    = item.height or 22
                            if item.class == "slider" then iH = 30 end
                            local inview = curY >= clip_min - 2 and curY + iH <= clip_max + 2
                            for _, d in item._dcache do d.Visible = inview end

                            local cp = sc.Position
                            local cs = sc.Size

                            if item.class == "button" then
                                local bw = cs.X - self.padding * 2
                                change(item.buttonbase, {Size=v2(bw-self.padding,item.height), Position=v2(cp.X+self.padding+1,curY), Transparency=ft(item.buttonbase.Transparency)})
                                local hov = inview and mousebound(item.buttonbase.Position, item.buttonbase.Size)
                                local cs1, cs2
                                if hov then
                                    item.text.Color = _c.accent
                                    if self.keys.mouse1.click then
                                        if item.last_click_state ~= "clicked" then item.last_click_state="clicked"; item.callback() end
                                        cs1,cs2 = _c.accent, _c.crust
                                    else item.last_click_state="hover"; cs1,cs2 = _c.surface1, _c.surface0 end
                                else
                                    item.text.Color = _c.text; item.last_click_state="idle"; cs1,cs2 = _c.surface0, _c.mantle
                                end
                                if item.last_cs ~= cs1 or item.last_ce ~= cs2 then item.last_cs=cs1; item.last_ce=cs2; item.buttonbase.ChangeColor(cs1,cs2) end
                                change(item.text, {Position=centertext(item.text.Text,item.buttonbase.Position,item.buttonbase.Size), Transparency=ft(item.text.Transparency)})
                                change(item.buttonoutline, {Position=item.buttonbase.Position-v2(1,1), Size=item.buttonbase.Size+v2(2,3), Transparency=ft(item.buttonoutline.Transparency), Color=_c.crust})
                                if item.color_square then
                                    local csq = item.color_square
                                    change(csq, {Position=v2(item.buttonbase.Position.X+item.buttonbase.Size.X-16,item.buttonbase.Position.Y+(item.buttonbase.Size.Y/2)-6), Visible=inview, Transparency=ft(csq.Transparency), Color=item.color})
                                    if mousebound(csq.Position,csq.Size) and self.keys.mouse1.click then
                                        self.keys.mouse1.click=false; self.picker.active=item
                                        local h,s,v = rgbToHsv(item.color); self.picker.h,self.picker.s,self.picker.v=h,s,v
                                    end
                                end
                                itemY += item.height + self.padding*2; sub.total_height += item.height + self.padding*2

                            elseif item.class == "toggle" then
                                change(item.togglebutton, {Position=v2(cp.X+self.padding+4,curY+4), Transparency=ft(item.togglebutton.Transparency)})
                                change(item.toggleoutline, {Position=item.togglebutton.Position-v2(1,1), Transparency=ft(item.toggleoutline.Transparency), Color=_c.crust})
                                change(item.text, {Position=v2(item.togglebutton.Position.X+18,item.togglebutton.Position.Y-1), Transparency=ft(item.text.Transparency), Color=_c.text})
                                local bs = (item.waiting and "..." or (item.bind and "["..item.bind:upper().."]" or "[-]"))
                                local bsz = textbound(bs); local tsz = textbound(item.text.Text)
                                change(item.statetext, {Text=bs, Position=v2(item.text.Position.X+tsz+6,item.togglebutton.Position.Y-1), Transparency=ft(item.statetext.Transparency), Color=_c.subtext0})
                                local hov  = inview and (mousebound(item.togglebutton.Position-v2(9,9),v2(20,20)) or mousebound(item.text.Position,v2(tsz)))
                                local bhov = inview and mousebound(item.statetext.Position,v2(bsz,15))
                                if hov and self.keys.mouse1.click then
                                    item.state = not item.state; item.callback(item.state)
                                    self:notify((item.state and "Enabled " or "Disabled ")..item.name); self._needs_save=true
                                elseif bhov and self.keys.mouse1.click then self.keys.mouse1.click=false; item.waiting=true end
                                if item.waiting then
                                    for key,variable in self.keys do
                                        if variable.click then
                                            item.bind = (key=="backspace" or key=="delete") and nil or key
                                            item.waiting=false; variable.click=false; self._needs_save=true
                                        end
                                    end
                                elseif item.bind and self.keys[item.bind] and self.keys[item.bind].click then
                                    item.state = not item.state; item.callback(item.state)
                                    self:notify((item.state and "Enabled " or "Disabled ")..item.name); self._needs_save=true
                                end
                                local tc = item.state and _c.accent or _c.mantle
                                if item.last_color ~= tc then item.last_color=tc; item.togglebutton.Color=tc end
                                if item.color_square then
                                    local csq = item.color_square
                                    change(csq, {Position=v2(cp.X+cs.X-18,item.togglebutton.Position.Y), Visible=inview, Transparency=ft(csq.Transparency), Color=item.color})
                                    if mousebound(csq.Position,csq.Size) and self.keys.mouse1.click then
                                        self.keys.mouse1.click=false; self.picker.active=item
                                        local h,s,v = rgbToHsv(item.color); self.picker.h,self.picker.s,self.picker.v=h,s,v
                                    end
                                end
                                itemY += 22; sub.total_height += 22

                            elseif item.class == "textbox" then
                                change(item.box,     {Position=v2(cp.X+self.padding,curY+25), Size=v2(cs.X-self.padding*2,20), Transparency=ft(item.box.Transparency), Color=item.focused and _c.surface1 or _c.mantle})
                                change(item.outline, {Position=item.box.Position-v2(1,1), Size=item.box.Size+v2(2,3), Transparency=ft(item.outline.Transparency), Color=item.focused and _c.accent or _c.crust})
                                change(item.label,   {Position=v2(item.box.Position.X,item.box.Position.Y-18), Transparency=ft(item.label.Transparency), Color=_c.text})
                                local dt = (#item.text>0 and item.text) or item.placeholder
                                change(item.value,   {Text=dt, Position=v2(item.box.Position.X+5,centertext(dt,item.box.Position,item.box.Size).Y), Transparency=ft(item.value.Transparency), Color=#item.text>0 and _c.text or _c.subtext0})
                                if inview and mousebound(item.box.Position,item.box.Size) and self.keys.mouse1.click then
                                    if self.focused_textbox and self.focused_textbox ~= item then self.focused_textbox.focused=false end
                                    self.focused_textbox=item; item.focused=true; self.keys.mouse1.click=false
                                elseif self.keys.mouse1.click and self.focused_textbox==item then self.focused_textbox=nil; item.focused=false end
                                itemY += 50; sub.total_height += 50

                            elseif item.class == "keybind" then
                                local bstr  = (item.waiting and "..." or item.state)
                                local bw    = textbound(bstr) + 10
                                change(item.button,    {Size=v2(bw,item.height), Position=v2(cp.X+cs.X-bw-self.padding-5,curY), Transparency=ft(item.button.Transparency)})
                                change(item.outline,   {Position=item.button.Position-v2(1,1), Size=item.button.Size+v2(2,2), Transparency=ft(item.outline.Transparency)})
                                change(item.text,      {Position=v2(cp.X+self.padding+5,centertext(item.text.Text,item.button.Position,item.button.Size).Y), Transparency=ft(item.text.Transparency)})
                                change(item.statetext, {Position=centertext(bstr,item.button.Position,item.button.Size), Transparency=ft(item.statetext.Transparency), Text=bstr})
                                if inview and mousebound(item.button.Position,item.button.Size) and self.keys.mouse1.click then
                                    self.keys.mouse1.click=false; item.waiting=true
                                end
                                if item.waiting then
                                    for key,variable in self.keys do
                                        if variable.click then item.state=key; item.waiting=false; variable.click=false; item.onset(item.state); self._needs_save=true end
                                    end
                                elseif self.keys[item.state] and self.keys[item.state].click then item.callback() end
                                itemY += item.height+self.padding*2; sub.total_height += item.height+self.padding*2

                            elseif item.class == "dropdown" then
                                local bw = cs.X - self.padding*2
                                change(item.button,    {Size=v2(bw-self.padding,item.height), Position=v2(cp.X+self.padding+1,curY), Transparency=ft(item.button.Transparency)})
                                change(item.buttonoutline, {Position=item.button.Position-v2(1,1), Size=item.button.Size+v2(2,3), Transparency=ft(item.buttonoutline.Transparency)})
                                change(item.labeltext, {Position=v2(item.button.Position.X+5,centertext(item.labeltext.Text,item.button.Position,item.button.Size).Y), Transparency=ft(item.labeltext.Transparency)})
                                local vw = textbound(item.selected)
                                change(item.valuetext, {Text=item.selected, Position=v2(item.button.Position.X+item.button.Size.X-vw-15,centertext(item.valuetext.Text,item.button.Position,item.button.Size).Y), Transparency=ft(item.valuetext.Transparency)})
                                change(item.arrow,     {Text=item.open and "-" or "+", Position=v2(item.button.Position.X+item.button.Size.X-10,centertext(item.arrow.Text,item.button.Position,item.button.Size).Y), Transparency=ft(item.arrow.Transparency)})
                                if inview and mousebound(item.button.Position,item.button.Size) and self.keys.mouse1.click then item.open = not item.open end
                                if item.open then
                                    local oh = 16; local th2 = #item.options*oh
                                    change(item.optionsContainer, {Position=v2(item.button.Position.X,item.button.Position.Y+item.height+2), Size=v2(bw-self.padding,th2+self.padding*2), Transparency=ft(item.optionsContainer.Transparency), Visible=inview})
                                    change(item.optionsOutline,   {Position=item.optionsContainer.Position-v2(1,1), Size=item.optionsContainer.Size+v2(2,2), Transparency=ft(item.optionsOutline.Transparency), Visible=inview})
                                    for idx, v in ipairs(item.optionElements) do
                                        local cen = centertext(v.Text,item.optionsContainer.Position,item.optionsContainer.Size)
                                        change(v, {Position=v2(cen.X,item.optionsContainer.Position.Y+self.padding+oh*(idx-1)), Transparency=ft(v.Transparency), Color=item.selected==v.Text and _c.text or _c.subtext1, ZIndex=11, Visible=inview and item.open})
                                        if mousebound(v.Position,v2(item.optionsContainer.Size.X,oh)) and self.keys.mouse1.click and item.selected~=v.Text then
                                            item.selected=v.Text; item.callback(item.selected); item.open=false; self._needs_save=true
                                        end
                                    end
                                else
                                    change(item.optionsContainer,{Transparency=0,Visible=false}); change(item.optionsOutline,{Transparency=0,Visible=false})
                                    for _,v in item.optionElements do change(v,{Transparency=0,Visible=false}) end
                                end
                                itemY += item.height+self.padding*2; sub.total_height += item.height+self.padding*2

                            elseif item.class == "slider" then
                                local sh = 12
                                change(item.sliderbackground, {Size=v2(cs.X-self.padding*2,sh), Position=v2(cp.X+self.padding+1,curY+16), Transparency=ft(item.sliderbackground.Transparency), Color=_c.mantle})
                                change(item.slideroutline,    {Position=item.sliderbackground.Position-v2(1,1), Size=item.sliderbackground.Size+v2(2,2), Transparency=ft(item.slideroutline.Transparency), Color=_c.crust})
                                local ratio = (item.value-item.min)/(item.max-item.min)
                                change(item.slideframe,  {Size=v2(math.clamp(ratio*item.sliderbackground.Size.X,0,item.sliderbackground.Size.X),sh), Position=item.sliderbackground.Position, Transparency=ft(item.slideframe.Transparency), Color=_c.accent})
                                change(item.text,        {Position=v2(item.sliderbackground.Position.X,item.sliderbackground.Position.Y-14), Transparency=ft(item.text.Transparency), Color=_c.text, ZIndex=6, Text=item.name})
                                local vs = tostring(item.value)..item.suffix; local vx = textbound(vs)
                                change(item.valuetext,   {Text=vs, Position=v2(item.sliderbackground.Position.X+item.sliderbackground.Size.X-vx,item.sliderbackground.Position.Y-14), Visible=inview, Color=_c.subtext0, Transparency=ft(item.valuetext.Transparency)})
                                if inview and self.keys.mouse1.hold and mousebound(item.sliderbackground.Position-v2(0,5),item.sliderbackground.Size+v2(0,10)) then
                                    local frac = math.clamp((mouse.X - item.sliderbackground.Position.X), 0, item.sliderbackground.Size.X) / item.sliderbackground.Size.X
                                    local factor = math.floor((item.max - item.min) * frac / item.step + 0.5)
                                    local old = item.value
                                    item.value = truncate(item.min + factor * item.step, countDecimalPlaces(item.step))
                                    if item.value ~= old then item.callback(item.value); self._needs_save=true end
                                end
                                itemY += 28; sub.total_height += 28
                            end
                        end

                        if #section.sections > 1 then
                            local sbw    = textbound(sub.name)*1.1
                            local offset = section.sections[num-1] and (section.sections[num-1].button.Position.X+section.sections[num-1].button.Size.X) or sc.Position.X
                            change(sub.button, {Position=v2(offset,sc.Position.Y), Size=v2(sbw+3,section.buttonbg.Size.Y-2), Visible=true, Transparency=ft(sub.button.Transparency)})
                            change(sub.buttontext, {Text=sub.name, Position=centertext(sub.name,sub.button.Position,sub.button.Size), Color=_c.text, Visible=true, Transparency=ft(sub.buttontext.Transparency)})
                            local tcs = _c.mantle; local tce = section.index==num and _c.base or _c.crust
                            if sub.last_cs~=tcs or sub.last_ce~=tce then sub.last_cs=tcs; sub.last_ce=tce; sub.button.ChangeColor(tcs,tce) end
                            if mousebound(sub.button.Position,sub.button.Size) and self.keys.mouse1.click then section.index=num end
                        end
                    end

                    local mch = math.max(col_offsets.left, col_offsets.right)
                    self.minH = mch + (self.th+self.taboffset) + self.padding*2 + 35
                    if self.minH > self.h then self.h = lerp(self.h, self.minH, getLerp(0.1, delta)) end
                end
            else
                setvisible(tab.sections, false)
            end
        end

        if not self._initialized_autosave then
            self._initialized_autosave = true
            pcall(function()
                if isfile("naska/autosave.cfg") then
                    local ok, data = pcall(function() return http:JSONDecode(readfile("naska/autosave.cfg")) end)
                    if ok and data[tostring(game.PlaceId)] then self:set_config(data[tostring(game.PlaceId)]) end
                end
            end)
        end

        if self._needs_save then
            pcall(function()
                local fd = {}
                if isfile("naska/autosave.cfg") then
                    local ok, d = pcall(function() return http:JSONDecode(readfile("naska/autosave.cfg")) end)
                    if ok then fd = d end
                end
                fd[tostring(game.PlaceId)] = self:get_config()
                if not isfolder("naska") then makefolder("naska") end
                writefile("naska/autosave.cfg", http:JSONEncode(fd))
            end)
            self._needs_save = false
        end

        -- colour picker
        local picker = self.picker
        if picker.active then
            local ps = v2(160,185)
            local pp = v2(self.x+self.w+10, self.y)
            if pp.X+ps.X > workspace.CurrentCamera.ViewportSize.X then pp = v2(self.x-ps.X-10, self.y) end
            change(picker.container, {Position=pp, Size=ps, Visible=true, Color=rgb(31,31,31), Transparency=ft(picker.container.Transparency)})
            change(picker.outline,   {Position=pp-v2(1,1), Size=ps+v2(2,2), Visible=true, Transparency=ft(picker.container.Transparency)})
            local svp = pp+v2(10,10); local svs = v2(140,140)
            picker.sv_underlay:ChangeColor(rgb(255,255,255), hsvToRgb(picker.h,1,1))
            change(picker.sv_underlay, {Position=svp, Size=svs, Visible=true, Transparency=ft(picker.container.Transparency)})
            change(picker.sv_overlay,  {Position=svp, Size=svs+v2(1,1), Visible=true, Transparency=ft(picker.container.Transparency)})
            local hp2 = pp+v2(10,160)
            for i = 1, 6 do
                local sx = math.floor((i-1)*140/6); local ex = math.floor(i*140/6)
                change(picker.hue_bar[i], {Position=hp2+v2(sx,0), Size=v2(ex-sx,15), Visible=true, Transparency=ft(picker.hue_bar[i].Transparency)})
            end
            change(picker.hue_indicator, {Position=hp2+v2(math.floor(picker.h*138),0), Visible=true, Transparency=ft(picker.hue_indicator.Transparency)})
            local m2 = mp()
            if self.keys.mouse1.hold then
                if mousebound(svp,svs) then
                    picker.s = math.clamp((m2.X-svp.X)/139,0,1)
                    picker.v = 1-math.clamp((m2.Y-svp.Y)/139,0,1)
                elseif mousebound(hp2,v2(140,15)) then
                    picker.h = math.clamp((m2.X-hp2.X)/139,0,1)
                elseif not mousebound(pp,ps) and self.keys.mouse1.click then
                    picker.active = nil
                end
                if picker.active then
                    picker.active.color = hsvToRgb(picker.h,picker.s,picker.v)
                    if picker.active.callback then
                        if picker.active.class=="toggle" then picker.active.callback(picker.active.state,picker.active.color)
                        else picker.active.callback(picker.active.color) end
                    end
                    self._needs_save = true
                end
            elseif self.keys.mouse1.click and not mousebound(pp,ps) then picker.active = nil end
            if picker.active then change(picker.pointer, {Position=svp+v2(picker.s*139,(1-picker.v)*139), Visible=true, Transparency=ft(picker.pointer.Transparency)}) end
        else
            change(picker.container,{Visible=false,Transparency=0}); change(picker.outline,{Visible=false,Transparency=0})
            change(picker.sv_underlay,{Visible=false}); change(picker.sv_overlay,{Visible=false})
            change(picker.pointer,{Visible=false,Transparency=0}); change(picker.hue_indicator,{Visible=false,Transparency=0})
            for i=1,6 do change(picker.hue_bar[i],{Visible=false,Transparency=0}) end
        end

        -- notifications
        local nx,ny,ns = 20,60,10; local an = 0
        for i, notif in ipairs(self.notifications) do
            local el = clock()-notif.start_time; local lp2 = math.clamp(el/notif.duration,0,1)
            if lp2 < 1 then
                local alpha = 1
                if el < 0.3 then alpha = el/0.3 elseif el > notif.duration-0.3 then alpha = (notif.duration-el)/0.3 end
                local tw2 = textbound(notif.text,16)
                local bs = v2(tw2+30,35)
                local pos = v2(nx, ny + an*(bs.Y+ns))
                if el < 0.3 then pos = pos - v2((1-alpha)*50,0) end
                change(notif.drawings.container, {Size=bs,Position=pos,Transparency=alpha,Visible=true})
                change(notif.drawings.outline,   {Size=bs+v2(2,2),Position=pos-v2(1,1),Transparency=alpha,Visible=true})
                change(notif.drawings.accent_bar,{Size=v2(bs.X*(1-lp2),2),Position=pos+v2(0,bs.Y-2),Transparency=alpha,Visible=true})
                change(notif.drawings.label,     {Position=pos+v2(15,(bs.Y/2)-7),Transparency=alpha,Visible=true})
                an = an + 1
            else
                for _, d in pairs(notif.drawings) do d:Remove() end
                table.remove(self.notifications, i)
            end
        end
    end

    function ui:get_config()
        local config = {elements={}, settings={theme=self.theme, closebind=tostring(self.closebind):lower(), watermark=self.watermark_enabled}}
        for _, tab in ipairs(self.tabs) do
            for _, section in ipairs(tab.sections) do
                for _, sub in ipairs(section.sections) do
                    for _, el in ipairs(sub.elements) do
                        local id = string.format("%s/%s/%s/%s_%s_%d", tab.name, section.name, sub.name, el.name or "element", el.class or "item", el.index or 0)
                        if el.class=="toggle" then config.elements[id]=el.state; if el.bind then config.elements[id.."_bind"]=el.bind end
                        elseif el.class=="slider" then config.elements[id]=el.value
                        elseif el.class=="dropdown" then config.elements[id]=el.selected
                        elseif el.class=="textbox" then config.elements[id]=el.text
                        elseif el.class=="keybind" then config.elements[id]=el.state end
                        if el.color then config.elements[id.."_color"]={el.color.R,el.color.G,el.color.B} end
                    end
                end
            end
        end
        return config
    end

    function ui:set_config(data)
        if data.settings then
            if data.settings.theme and self.themes[data.settings.theme] then self.theme=data.settings.theme; self.colors=self.themes[self.theme] end
            if data.settings.closebind then self.closebind=data.settings.closebind end
            if data.settings.watermark ~= nil then self.watermark_enabled=data.settings.watermark end
        end
        if data.elements then
            for _, tab in ipairs(self.tabs) do
                for _, section in ipairs(tab.sections) do
                    for _, sub in ipairs(section.sections) do
                        for _, el in ipairs(sub.elements) do
                            local id = string.format("%s/%s/%s/%s_%s_%d", tab.name, section.name, sub.name, el.name or "element", el.class or "item", el.index or 0)
                            local val = data.elements[id]
                            if val ~= nil then
                                if el.class=="toggle" then el.state=val; local bv=data.elements[id.."_bind"]; if bv then el.bind=tostring(bv):lower(); if el.statetext then el.statetext.Text="["..el.bind:upper().."]" end end
                                elseif el.class=="slider" then el.value=val
                                elseif el.class=="dropdown" then el.selected=val
                                elseif el.class=="textbox" then el.text=val; if el.value then el.value.Text=tostring(val) end
                                elseif el.class=="keybind" then el.state=tostring(val):lower(); if el.statetext then el.statetext.Text=el.state:upper() end end
                                if el.callback and el.class~="keybind" then pcall(el.callback,val) end
                                if el.class=="keybind" and el.onset then pcall(el.onset,val) end
                            end
                            local cv = data.elements[id.."_color"]
                            if cv and el.color_square then
                                el.color=Color3.new(cv[1] or 1,cv[2] or 1,cv[3] or 1); el.color_square.Color=el.color
                                if el.callback then if el.class=="toggle" then pcall(el.callback,el.state,el.color) else pcall(el.callback,el.color) end end
                            end
                        end
                    end
                end
            end
        end
    end

    function ui:notify(text, duration)
        if #text > 40 then text = text:sub(1,37).."..." end
        table.insert(self.notifications, {
            text=text, duration=duration or 5, start_time=clock(),
            drawings={
                container  = create("Square",{Filled=true, Color=self.colors.surface0, ZIndex=2000}),
                outline    = create("Square",{Filled=false,Color=self.colors.crust,    ZIndex=1999}),
                accent_bar = create("Square",{Filled=true, Color=self.colors.accent,   ZIndex=2001}),
                label      = create("Text",  {Text=text,   Color=self.colors.text, Size=16, ZIndex=2002})
            }
        })
    end

    function ui:tab(name)
        local tab = {tabindex=#self.tabs+1, name=name, sections={}, side={right=0,left=0}, menu=self}
        tab.button        = createGradient({Size=v2(200,20),ZIndex=3}, self.colors.mantle, self.colors.crust, 15)
        tab.text          = create("Text",{Text=name,ZIndex=4,Outline=false})
        tab.buttonoutline = createOutline(tab.button, self.colors.crust, 1)
        tab._dcache       = {tab.button, tab.text, tab.buttonoutline}
        tab.section       = section
        self.tabs[tab.tabindex] = tab
        return tab
    end

    function addsection(self, name)
        local sec = {colors=self.colors, name=name, section_container=self.section_container, elements={}, scroll=0, total_height=0}
        sec.button     = createGradient({Position=v2(),Size=v2()}, self.colors.mantle, self.colors.base, 25); sec.button.ZIndex=4
        sec.buttontext = create("Text",{Text=name,Color=self.colors.text,ZIndex=5,Outline=false})
        sec.addbutton=button; sec.addtoggle=toggle; sec.addkeybind=keybind; sec.adddropdown=dropdown; sec.addslider=slider
        function sec:clear()
            for _,v in pairs(self.elements) do if v._dcache then for _,d in pairs(v._dcache) do d:Remove() end end end
            self.elements={}; self.total_height=0; self.scroll=0
        end
        sec._dcache = {sec.button, sec.buttontext}
        table.insert(self.sections, sec)
        return sec
    end

    function section(self, name, side)
        local sec = {}
        local side = side and "right" or "left"
        sec.section_container = create("Square",{Filled=true,Color=self.menu.colors.base,ZIndex=2})
        sec.section_outline   = createOutline(sec.section_container, self.menu.colors.crust, 1)
        sec.buttonbg          = create("Square",{Filled=true,Color=self.menu.colors.crust,ZIndex=3})
        sec.button            = createGradient({Position=v2(),Size=v2()}, self.menu.colors.mantle, self.menu.colors.base, 25); sec.button.ZIndex=4
        sec.buttontext        = create("Text",{Text=name,Color=self.menu.colors.text,ZIndex=5,Outline=false})
        self.side[side] += 1
        sec.colors=self.menu.colors; sec.name=name; sec.sections={sec}; sec.index=1
        sec.sideindex=self.side[side]-1; sec.side=side; sec.addsection=addsection
        sec.addbutton=button; sec.addtoggle=toggle; sec.addtextbox=textbox; sec.addkeybind=keybind; sec.adddropdown=dropdown; sec.addslider=slider
        function sec:clear()
            for _,v in pairs(self.elements) do if v._dcache then for _,d in pairs(v._dcache) do d:Remove() end end end
            self.elements={}; self.total_height=0; self.scroll=0
        end
        sec.elements={}; sec.scroll=0; sec.total_height=0
        sec._dcache = {sec.section_container, sec.section_outline, sec.buttonbg, sec.button, sec.buttontext}
        table.insert(self.sections, sec)
        return sec
    end

    local function cleancache(tbl, visited)
        visited = visited or {}
        if visited[tbl] then return end; visited[tbl]=true
        for _, v in pairs(tbl) do
            if type(v)=="table" then
                if v._dcache then for _,d in v._dcache do d:Remove() end end
                cleancache(v, visited)
            end
        end
    end

    function setvisible(tbl, visible, visited)
        visited = visited or {}
        if visited[tbl] then return end; visited[tbl]=true
        for _, v in pairs(tbl) do
            if type(v)=="table" then
                if visible and v.ignoreVisible then continue end
                if v._dcache then for _,d in v._dcache do d.Visible = visible or false end end
                setvisible(v, visible, visited)
            end
        end
    end

    function button(self, data)
        local btn = {class="button", callback=data.Callback or function()end, index=#self.elements+1, height=22, name=data.Name}
        btn.text        = create("Text",{Text=data.Name,Color=self.colors.text,ZIndex=5,Outline=false})
        btn.buttonbase  = createGradient({Position=v2(),Size=v2()}, self.colors.surface0, self.colors.mantle, 25); btn.buttonbase.ZIndex=4
        btn.buttonoutline = createOutline(btn.buttonbase, self.colors.crust, 3)
        btn._dcache = {btn.buttonbase, btn.buttonoutline, btn.text}
        if data.Color then btn.color=data.Color; btn.color_square=create("Square",{Size=v2(12,12),Filled=true,Color=btn.color,ZIndex=5}); table.insert(btn._dcache,btn.color_square) end
        table.insert(self.elements, btn); return btn
    end

    function toggle(self, data)
        local tog = {height=18, class="toggle", callback=data.Callback or function()end, index=#self.elements+1, state=data.Default or false, name=data.Name}
        tog.text          = create("Text",{Text=data.Name,Color=self.colors.text,ZIndex=5,Outline=false})
        tog.togglebutton  = create("Square",{Size=v2(12,12),Filled=true,Color=self.colors.mantle,ZIndex=4})
        tog.toggleoutline = create("Square",{Size=v2(14,14),Filled=false,Thickness=1,Color=self.colors.crust,ZIndex=4})
        tog.statetext     = create("Text",{Text="[-]",Color=self.colors.subtext0,ZIndex=5,Outline=false})
        tog._dcache = {tog.togglebutton, tog.toggleoutline, tog.text, tog.statetext}
        if data.Color then tog.color=data.Color; tog.color_square=create("Square",{Size=v2(12,12),Filled=true,Color=tog.color,ZIndex=5}); table.insert(tog._dcache,tog.color_square) end
        table.insert(self.elements, tog); return tog
    end

    function textbox(self, data)
        local tb = {height=36, index=#self.elements+1, text=data.Default or "", placeholder=data.Placeholder or "", class="textbox", focused=false, callback=data.Callback or function()end, name=data.Name}
        tb.label   = create("Text",{Text=data.Name,Color=self.colors.text,ZIndex=5,Outline=false})
        tb.value   = create("Text",{Text=tb.text,Color=self.colors.subtext0,ZIndex=5,Outline=false})
        tb.box     = createGradient({Position=v2(),Size=v2()}, self.colors.mantle, self.colors.crust, 25); tb.box.ZIndex=4
        tb.outline = createOutline(tb.box, self.colors.crust, 3)
        tb._dcache = {tb.box, tb.outline, tb.label, tb.value}
        table.insert(self.elements, tb); return tb
    end

    function keybind(self, data)
        local kb = {height=18, index=#self.elements+1, state=data.Default or "", class="keybind", onset=data.Changed or function()end, callback=data.Callback or function()end, name=data.Name}
        kb.text      = create("Text",{Text=data.Name,Color=self.colors.text,ZIndex=5,Outline=false})
        kb.statetext = create("Text",{Text=data.Default or "",Color=self.colors.subtext0,ZIndex=5,Outline=false})
        kb.button    = createGradient({Position=v2(),Size=v2()}, self.colors.mantle, self.colors.crust, 25); kb.button.ZIndex=4
        kb.outline   = createOutline(kb.button, self.colors.crust, 3)
        kb._dcache   = {kb.button, kb.outline, kb.text, kb.statetext}
        table.insert(self.elements, kb); return kb
    end

    function dropdown(self, data)
        local opts = data.Options or {}
        local dd = {class="dropdown", callback=data.Callback or function()end, options=opts, selected=data.Default or (opts[1] or "None"), open=false, height=18, index=#self.elements+1, optionElements={}, name=data.Name}
        dd.button           = createGradient({Position=v2(),Size=v2()}, self.colors.mantle, self.colors.crust, 15); dd.button.ZIndex=4
        dd.buttonoutline    = createOutline(dd.button, self.colors.crust, 3)
        dd.labeltext        = create("Text",{Text=data.Name,Color=self.colors.text,ZIndex=5,Outline=false})
        dd.valuetext        = create("Text",{Text=dd.selected,Color=self.colors.subtext0,ZIndex=5,Outline=false})
        dd.arrow            = create("Text",{Color=self.colors.subtext1,ZIndex=5,Outline=false})
        dd.optionsContainer = create("Square",{Filled=true,Color=self.colors.mantle,ZIndex=10,Visible=false})
        dd.optionsOutline   = createOutline(dd.optionsContainer, self.colors.crust, 9); dd.optionsOutline.Visible=false
        for i, v in ipairs(opts) do dd.optionElements[i] = create("Text",{Text=v,ZIndex=11,Outline=false}) end
        dd._dcache = {dd.button,dd.buttonoutline,dd.labeltext,dd.valuetext,dd.arrow,dd.optionsContainer,dd.optionsOutline}
        for _,v in dd.optionElements do table.insert(dd._dcache,v) end
        table.insert(self.elements, dd); return dd
    end

    function slider(self, data)
        local sl = {class="slider", callback=data.Callback or function()end, max=data.Max or 100, min=data.Minimum or 0, step=data.Step or 1, suffix=data.Suffix or "", index=#self.elements+1, height=18, name=data.Name}
        sl.min -= sl.step; sl.value = data.Default or sl.min
        sl.text             = create("Text",{Text=data.Name,Color=self.colors.text,ZIndex=5,Outline=false})
        sl.sliderbackground = create("Square",{Filled=true,Color=self.colors.mantle,ZIndex=4})
        sl.slideroutline    = createOutline(sl.sliderbackground, self.colors.crust, 3)
        sl.slideframe       = create("Square",{Filled=true,Color=self.colors.teal,ZIndex=5})
        sl.valuetext        = create("Text",{Text="0",Color=self.colors.subtext0,ZIndex=5,Outline=false})
        sl._dcache = {sl.sliderbackground,sl.slideroutline,sl.text,sl.slideframe,sl.valuetext}
        table.insert(self.elements, sl); return sl
    end

    function ui:Destroy()
        cleancache(self)
        if self.overlay then self.overlay:Remove() end
        if self.watermark then for _,d in pairs(self.watermark) do d:Remove() end end
        setrobloxinput(true)
    end
end

return ui
end)()


--  SERVICES & RUNSERVICE EMULATOR
local Players = game:GetService("Players")

local RunService = (function()
    local RS = {}
    local _bindings = {}; local _active = true; local _lastTick = os.clock()
    local _sorted = {}; local _sortedCount = 0

    local function Signal()
        local sig = {_conns={}}
        function sig:Connect(fn)
            local c = {fn=fn,connected=true}; table.insert(sig._conns,c)
            return {Disconnect=function() c.connected=false; c.fn=nil end}
        end
        function sig:Fire(...)
            local i=1
            while i<=#sig._conns do
                local c=sig._conns[i]
                if c.connected then pcall(c.fn,...); i=i+1 else table.remove(sig._conns,i) end
            end
        end
        return sig
    end

    RS.Heartbeat=Signal(); RS.RenderStepped=Signal(); RS.Stepped=Signal()
    function RS:BindToRenderStep(n,p,f) if type(n)~="string" or type(f)~="function" then return end _bindings[n]={Priority=p or 0,Function=f}; _sortedCount=-1 end
    function RS:UnbindFromRenderStep(n) _bindings[n]=nil; _sortedCount=-1 end
    function RS:IsRunning() return _active end

    task.spawn(function()
        while _active do
            local now=os.clock(); local dt=math.min(now-_lastTick,1); _lastTick=now
            RS.Stepped:Fire(now,dt)
            local cnt=0; for _ in pairs(_bindings) do cnt=cnt+1 end
            if cnt~=_sortedCount then
                _sorted={}
                for _,b in pairs(_bindings) do if type(b.Function)=="function" then table.insert(_sorted,b) end end
                table.sort(_sorted,function(a,b) return a.Priority<b.Priority end)
                _sortedCount=cnt
            end
            for _,b in ipairs(_sorted) do pcall(b.Function,dt) end
            RS.RenderStepped:Fire(dt); RS.Heartbeat:Fire(dt)
            task.wait()
        end
    end)
    return RS
end)()


--  SHARED LOCALS
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = workspace.CurrentCamera
local Character, Humanoid, HRP

local function refreshChar()
    Character = LocalPlayer.Character
    if not Character then return end
    Humanoid  = Character:FindFirstChildOfClass("Humanoid")
    HRP       = Character:FindFirstChild("HumanoidRootPart")
end
refreshChar()

task.spawn(function()
    local lastChar = LocalPlayer.Character
    while true do
        task.wait(0.5)
        local cur = LocalPlayer.Character
        if cur ~= lastChar then lastChar=cur; task.wait(0.15); refreshChar() end
    end
end)


--  CREATE WINDOW
local lib = ui:create("ZazaMenu", {theme="gamesense", size=Vector2.new(600,420)})

local tabClicker = lib:tab("auto clicker")
local tabAFK     = lib:tab("anti-afk")
local tabFly     = lib:tab("fly")
local tabESP     = lib:tab("esp")
local tabOpts    = lib:tab("options")


--  AUTO CLICKER
local AC = {enabled=false,cps=10,savedX=nil,savedY=nil,_conn=nil,_acc=0}

local function ac_stopLoop() if AC._conn then AC._conn:Disconnect(); AC._conn=nil end; AC._acc=0 end
local function ac_startLoop()
    ac_stopLoop()
    local interval = 1/math.clamp(AC.cps,1,100)
    AC._conn = RunService.Heartbeat:Connect(function(dt)
        if not AC.enabled then return end
        AC._acc = AC._acc + dt
        if AC._acc < interval then return end
        AC._acc = 0
        if AC.savedX and AC.savedY then mousemoveabs(AC.savedX,AC.savedY) end
        mouse1press(); task.wait(0.016); mouse1release()
    end)
end

local secClickerMain = tabClicker:section("clicker settings",false)
local secClickerPos  = tabClicker:section("mouse position",true)

secClickerMain:addtoggle{Name="Enable Auto Clicker",Default=false,Callback=function(v) AC.enabled=v; if v then ac_startLoop() else ac_stopLoop() end end}
secClickerMain:addslider{Name="Clicks Per Second",Minimum=1,Max=50,Step=1,Default=10,Suffix=" CPS",Callback=function(v) AC.cps=v; if AC.enabled then ac_startLoop() end end}
secClickerPos:addkeybind{Name="Save Mouse Position",Default="f3",Changed=function()end,Callback=function() AC.savedX=Mouse.X; AC.savedY=Mouse.Y; lib:notify(("Saved  X:%d  Y:%d"):format(AC.savedX,AC.savedY)) end}
secClickerPos:addbutton{Name="Clear Saved Position",Callback=function() AC.savedX=nil; AC.savedY=nil; lib:notify("Saved position cleared") end}


--  ANTI-AFK
local AFK={enabled=false}
local AFK_KEYS={0x57,0x41,0x53,0x44}

local function afk_stop() AFK.enabled=false end
local function afk_start()
    afk_stop(); AFK.enabled=true
    task.spawn(function()
        while AFK.enabled do
            task.wait(math.random(7,13))
            if not AFK.enabled then break end
            local k=AFK_KEYS[math.random(1,#AFK_KEYS)]
            keypress(k); task.wait(math.random(10,40)*0.01); keyrelease(k)
        end
    end)
end

tabAFK:section("anti-afk settings",false):addtoggle{Name="Enable Anti-AFK",Default=false,Callback=function(v) AFK.enabled=v; if v then afk_start() else afk_stop() end end}


--  FLY
local VK={W=0x57,A=0x41,S=0x53,D=0x44,SPACE=0x20,LSHIFT=0xA0,LCTRL=0xA2}
local Fly={enabled=false,speed=20,_conn=nil,_savedCanCol=true,_vx=0,_vy=0,_vz=0}

local function fly_stop()
    Fly.enabled=false
    if Fly._conn then Fly._conn:Disconnect(); Fly._conn=nil end
    Fly._vx,Fly._vy,Fly._vz=0,0,0
    if HRP then HRP.AssemblyLinearVelocity=Vector3.new(0,0,0); HRP.CanCollide=Fly._savedCanCol end
end
local function fly_start()
    fly_stop()
    if not HRP then lib:notify("No character - try again after spawning"); return end
    Fly.enabled=true; Fly._savedCanCol=HRP.CanCollide; HRP.CanCollide=false
    Fly._conn=RunService.Heartbeat:Connect(function(dt)
        if not Fly.enabled then return end
        if not HRP then fly_stop(); return end
        local cp=Camera.Position; local hp=HRP.Position
        local fdx=hp.X-cp.X; local fdz=hp.Z-cp.Z; local fl=math.sqrt(fdx*fdx+fdz*fdz)
        local fx,fz = fl>0.01 and fdx/fl or 0, fl>0.01 and fdz/fl or -1
        local rx,rz=fz,-fx
        local tx,ty,tz=0,0,0
        if iskeypressed(VK.W) then tx=tx+fx;tz=tz+fz end
        if iskeypressed(VK.S) then tx=tx-fx;tz=tz-fz end
        if iskeypressed(VK.A) then tx=tx+rx;tz=tz+rz end
        if iskeypressed(VK.D) then tx=tx-rx;tz=tz-rz end
        if iskeypressed(VK.SPACE) then ty=Fly.speed end
        if iskeypressed(VK.LSHIFT) or iskeypressed(VK.LCTRL) then ty=-Fly.speed end
        local hl=math.sqrt(tx*tx+tz*tz)
        if hl>0.001 then tx=tx/hl*Fly.speed; tz=tz/hl*Fly.speed end
        local lf=1-(0.5^(dt*14))
        Fly._vx=Fly._vx+(tx-Fly._vx)*lf; Fly._vy=Fly._vy+(ty-Fly._vy)*lf; Fly._vz=Fly._vz+(tz-Fly._vz)*lf
        HRP.AssemblyLinearVelocity=Vector3.new(Fly._vx,Fly._vy,Fly._vz)
    end)
end

local secFlyMain=tabFly:section("fly settings",false); local secFlyInfo=tabFly:section("controls",true)
secFlyMain:addtoggle{Name="Enable Fly",Default=false,Callback=function(v) if v then fly_start() else fly_stop() end end}
secFlyMain:addslider{Name="Speed",Minimum=1,Max=100,Step=1,Default=20,Suffix=" studs/s",Callback=function(v) Fly.speed=v end}
secFlyInfo:addbutton{Name="W / A / S / D  -- directional",Callback=function()end}
secFlyInfo:addbutton{Name="Space           -- ascend",     Callback=function()end}
secFlyInfo:addbutton{Name="LShift / LCtrl  -- descend",   Callback=function()end}


--  ESP
local ESP_ENABLED   = false
local espRenderConn = nil
local ESP_MAX_SHOWN = 20
local ESP_MAX_DIST  = 500
local espNamedTargets  = {}
local espFolderTargets = {}
local espPool = {}; local espPoolSize = 0

local function newESPDrawings()
    local box=Drawing.new("Square"); box.Visible=false; box.Filled=false; box.Color=Color3.fromRGB(255,255,255); box.Transparency=1; box.Thickness=1.5; box.ZIndex=5
    local nt=Drawing.new("Text"); nt.Visible=false; nt.Text=""; nt.Size=14; nt.Font=Drawing.Fonts.UI; nt.Color=Color3.fromRGB(255,255,255); nt.Transparency=1; nt.Outline=true; nt.Center=true; nt.ZIndex=6
    local dt=Drawing.new("Text"); dt.Visible=false; dt.Text=""; dt.Size=13; dt.Font=Drawing.Fonts.UI; dt.Color=Color3.fromRGB(185,185,185); dt.Transparency=1; dt.Outline=true; dt.Center=true; dt.ZIndex=6
    local hbg=Drawing.new("Square"); hbg.Visible=false; hbg.Filled=true; hbg.Color=Color3.fromRGB(15,15,15); hbg.Transparency=0.5; hbg.ZIndex=5
    local hfg=Drawing.new("Square"); hfg.Visible=false; hfg.Filled=true; hfg.Color=Color3.fromRGB(0,255,80); hfg.Transparency=1; hfg.ZIndex=6
    return {box=box,nameText=nt,distText=dt,hpBarBG=hbg,hpBarFG=hfg}
end

local function hideESP(d) d.box.Visible=false; d.nameText.Visible=false; d.distText.Visible=false; d.hpBarBG.Visible=false; d.hpBarFG.Visible=false end

local function getDrawingSet(i)
    while espPoolSize < i do espPoolSize=espPoolSize+1; espPool[espPoolSize]=newESPDrawings() end
    return espPool[i]
end

local PART_CN = {
    Part=true, MeshPart=true, UnionOperation=true,
    WedgePart=true, CornerWedgePart=true, TrussPart=true,
    SpawnLocation=true, Seat=true, VehicleSeat=true,
}

local function isPart(inst)
    return PART_CN[inst.ClassName] == true
end

local function findPartInChildren(container, depth)
    depth = depth or 0
    if depth > 6 then return nil end  

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return nil end

    for _, child in ipairs(children) do
        if isPart(child) then return child end
    end
    for _, child in ipairs(children) do
        local cn = child.ClassName
        if cn == "Model" or cn == "Folder" then
            local found = findPartInChildren(child, depth + 1)
            if found then return found end
        end
    end

    return nil
end

local function getModelPart(model)
    local ok, pp = pcall(function() return model.PrimaryPart end)
    if ok and pp then return pp end
    return findPartInChildren(model)
end

local function collectFromContainer(container, out, seen)
    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for _, child in ipairs(children) do
        local cn = child.ClassName

        if isPart(child) then
            if not seen[child] then
                seen[child] = true
                table.insert(out, { part=child, name=child.Name })
            end

        elseif cn == "Model" then
            local part = getModelPart(child)
            if part and not seen[part] then
                seen[part] = true
                table.insert(out, { part=part, name=child.Name })
            end

        elseif cn == "Folder" then
            collectFromContainer(child, out, seen)
        end
    end
end

local function getScreenBounds(part)
    if not part then return nil end
    local pos = part.Position; local sz = part.Size
    local tp = Vector3.new(pos.X, pos.Y+sz.Y*0.5, pos.Z)
    local bp = Vector3.new(pos.X, pos.Y-sz.Y*0.5, pos.Z)
    local cs, onS = WorldToScreen(pos)
    local ts, toS = WorldToScreen(tp)
    local bs, boS = WorldToScreen(bp)
    if not onS and not toS and not boS then return nil end
    local sh = math.abs(bs.Y-ts.Y); if sh<4 then sh=4 end
    local asp = math.clamp(sz.X/math.max(sz.Y,0.1),0.3,3)
    local sw = sh*asp; if sw<4 then sw=4 end
    local cx=cs.X; local minY=ts.Y; local maxY=bs.Y
    if minY>maxY then minY,maxY=maxY,minY end
    return cx-sw*0.5, minY, cx+sw*0.5, maxY
end

local function hpColor(pct) return Color3.fromRGB(math.floor((1-pct)*255),math.floor(pct*255),0) end

local function startESPLoop()
    if espRenderConn then return end
    espRenderConn = RunService.Heartbeat:Connect(function()
        if not ESP_ENABLED then return end
        if not HRP then return end

        local myPos = HRP.Position
        
        local seen = {}
        local candidates = {}

        local function tryAdd(part, displayName)
            if not part or seen[part] then return end
            seen[part] = true
            local pos = part.Position
            local dx=pos.X-myPos.X; local dy=pos.Y-myPos.Y; local dz=pos.Z-myPos.Z
            local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
            if dist <= ESP_MAX_DIST then
                table.insert(candidates, {part=part, name=displayName, dist=dist})
            end
        end

        for name, _ in pairs(espNamedTargets) do
            local obj = workspace:FindFirstChild(name, true)
            if obj then
                if isPart(obj) then
                    tryAdd(obj, obj.Name)
                elseif obj.ClassName == "Model" then
                    local part = getModelPart(obj)
                    if part then tryAdd(part, obj.Name) end
                end
            end
        end

        for folderName, _ in pairs(espFolderTargets) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                local collected = {}
                local collSeen  = {}
                collectFromContainer(folder, collected, collSeen)
                for _, e in ipairs(collected) do
                    tryAdd(e.part, e.name)
                end
            end
        end

        table.sort(candidates, function(a,b) return a.dist<b.dist end)
        local shown = math.min(#candidates, ESP_MAX_SHOWN)

        for i = 1, shown do
            local entry = candidates[i]
            local part  = entry.part
            local d     = getDrawingSet(i)

            local minX,minY,maxX,maxY = getScreenBounds(part)
            if not minX then hideESP(d); continue end

            local PAD=5
            local bx=minX-PAD; local by=minY-PAD
            local bw=(maxX-minX)+PAD*2; local bh=(maxY-minY)+PAD*2

            local humanoid = part.Parent and part.Parent:FindFirstChild("Humanoid")

            d.box.Position=Vector2.new(bx,by); d.box.Size=Vector2.new(bw,bh); d.box.Visible=true
            d.nameText.Text=entry.name; d.nameText.Position=Vector2.new(bx+bw*0.5,by-17); d.nameText.Visible=true
            d.distText.Text=math.floor(entry.dist).."m"; d.distText.Position=Vector2.new(bx+bw*0.5,by+bh+3); d.distText.Visible=true

            if humanoid and humanoid.MaxHealth>0 then
                local pct=math.clamp(humanoid.Health/humanoid.MaxHealth,0,1)
                local barX=bx-7; local barW=4
                d.hpBarBG.Position=Vector2.new(barX,by); d.hpBarBG.Size=Vector2.new(barW,bh); d.hpBarBG.Visible=true
                local fh=math.max(1,math.floor(bh*pct))
                d.hpBarFG.Position=Vector2.new(barX,by+bh-fh); d.hpBarFG.Size=Vector2.new(barW,fh); d.hpBarFG.Color=hpColor(pct); d.hpBarFG.Visible=true
            else
                d.hpBarBG.Visible=false; d.hpBarFG.Visible=false
            end
        end

        for i=shown+1,espPoolSize do hideESP(espPool[i]) end
    end)
end

local function stopESPLoop()
    if espRenderConn then espRenderConn:Disconnect(); espRenderConn=nil end
    for i=1,espPoolSize do hideESP(espPool[i]) end
end


--  ESP UI
local secESPCtrl   = tabESP:section("esp control",  false)
local secESPConf   = tabESP:section("esp settings", true)
local secESPNamed  = tabESP:section("named targets",false)
local secESPFolder = tabESP:section("folder scan",  true)

secESPCtrl:addtoggle{Name="Enable ESP",Default=false,Callback=function(v) ESP_ENABLED=v; if v then startESPLoop() else stopESPLoop() end end}
secESPConf:addslider{Name="Max Shown",   Minimum=1,  Max=50,   Step=1,  Default=20,  Suffix=" targets",Callback=function(v) ESP_MAX_SHOWN=v end}
secESPConf:addslider{Name="Max Distance",Minimum=10, Max=2000, Step=10, Default=500, Suffix=" studs",  Callback=function(v) ESP_MAX_DIST=v end}

local tbNamedInst = secESPNamed:addtextbox{Name="Instance Name",Placeholder="e.g.  Zombie  or  TreasureChest",Callback=function()end}

local secESPNamedList
local function rebuildNamedList()
    secESPNamedList:clear(); local any=false
    for name, _ in pairs(espNamedTargets) do
        any=true
        secESPNamedList:addbutton{Name="remove:  "..name,Callback=function() espNamedTargets[name]=nil; rebuildNamedList() end}
    end
    if not any then secESPNamedList:addbutton{Name="(none - add one above)",Callback=function()end} end
end

secESPNamed:addbutton{Name="Add Named Target",Callback=function()
    local name=(tbNamedInst.text or ""):match("^%s*(.-)%s*$")
    if name=="" then return end
    if espNamedTargets[name] then lib:notify("Already tracking: "..name); return end
    espNamedTargets[name]=true; rebuildNamedList(); lib:notify("ESP added: "..name)
end}
secESPNamed:addbutton{Name="Clear All Named",Callback=function() espNamedTargets={}; rebuildNamedList() end}

secESPNamedList = tabESP:section("named list",false)
rebuildNamedList()

local tbFolderName = secESPFolder:addtextbox{Name="Folder Name",Placeholder="e.g.  Enemies,  Collectibles",Callback=function()end}

local secESPFolderList
local function rebuildFolderList()
    secESPFolderList:clear(); local any=false
    for name, _ in pairs(espFolderTargets) do
        any=true
        secESPFolderList:addbutton{Name="remove:  "..name,Callback=function() espFolderTargets[name]=nil; rebuildFolderList() end}
    end
    if not any then secESPFolderList:addbutton{Name="(none - add one above)",Callback=function()end} end
end

secESPFolder:addbutton{Name="Add Folder",Callback=function()
    local name=(tbFolderName.text or ""):match("^%s*(.-)%s*$")
    if name=="" then return end
    if espFolderTargets[name] then lib:notify("Already scanning: "..name); return end
    espFolderTargets[name]=true; rebuildFolderList(); lib:notify("Folder added: "..name)
end}
secESPFolder:addbutton{Name="Clear All Folders",Callback=function() espFolderTargets={}; rebuildFolderList() end}

secESPFolderList = tabESP:section("folder list",true)
rebuildFolderList()


--  OPTIONS
local secUISet = tabOpts:section("ui settings",false)
local secTheme = tabOpts:section("theme",true)

secUISet:addtoggle{Name="Watermark",Default=true,Callback=function(v) lib.watermark_enabled=v end}
secUISet:addkeybind{Name="Toggle UI Keybind",Default=lib.closebind,Changed=function(v) lib.closebind=v end}
secUISet:addbutton{Name="Destroy UI",Callback=function() lib.running=false end}
secTheme:adddropdown{Name="Theme",Options=lib.themenames,Default=lib.theme,Callback=function(v) lib.theme=v; lib.colors=lib.themes[v] end}


--  MAIN LOOP
while lib.running do lib:step(); task.wait() end

lib:Destroy(); fly_stop(); ac_stopLoop(); afk_stop(); stopESPLoop()
