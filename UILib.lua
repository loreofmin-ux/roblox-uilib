-- UILib v2 : librairie de UI flottante/déplaçable pour Roblox.
-- Placer ce ModuleScript dans ReplicatedStorage (ou le loader via loadstring).
--
-- Structure : Hub > Onglet (rangé par catégorie dans la sidebar) > Section (carte)
-- Les sections se répartissent en colonnes au lieu d'une longue liste à scroller.
--
--   local UILib = require(game.ReplicatedStorage.UILib)
--   local Hub = UILib.new({
--       Title = "Samuraii Hub",
--       Subtitle = "Restaurant Tycoon 3 | v2.0.0",
--       Theme = "Green",
--       ConfigFile = "SamuraiiHub",
--       Width = 940, Height = 580, -- optionnel, bornés à la taille de l'écran
--   })
--
--   local tab = Hub:AddTab("Main", "Game")
--   local sec = tab:AddSection("Auto Farm", { Toggle = true, Column = 1 })
--   local btn = sec:AddButton("Select Everything", function() end)
--   sec:AddToggle("Auto Cook Food", false, function(on) end)
--   sec:AddSlider("WalkSpeed", 16, 100, 16, function(v) end)
--   sec:AddTextbox("New restaurant name...", function(txt) end)
--   sec:AddNote("Note: ...")
--
--   Hub:AutoLoad() -- à appeler en dernier : recharge la config précédente
--
-- Chaque élément se modifie après coup, tout argument nil restant inchangé :
--   btn:UpdateButton("Nouveau texte")            -- garde le callback
--   btn:UpdateButton(nil, function() end)        -- garde le texte
--   toggle:UpdateToggle("Titre", true)
--   slider:UpdateSlider("Vitesse", 0, 500)
--   textbox:UpdateTextbox("Nouveau placeholder")
--   dropdown:UpdateDropdown(nil, { "A", "B" }, "A")
--   label:UpdateLabel("Texte")   /   note:UpdateNote("Texte")
--
-- Déchargement complet (interface + connexions) :
--   Hub:OnUnload(function() ... end) -- nettoyage propre au module
--   Hub:Unload()      -- ou sec:Unload() / tab:Unload(), même effet

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold

--==============================================================
-- Thèmes
--==============================================================

local THEMES = {
	Dark = {
		Background = Color3.fromRGB(13, 14, 17),
		Sidebar = Color3.fromRGB(17, 18, 22),
		Card = Color3.fromRGB(23, 24, 29),
		Element = Color3.fromRGB(32, 34, 40),
		ElementHover = Color3.fromRGB(44, 46, 54),
		Stroke = Color3.fromRGB(38, 40, 47),
		Accent = Color3.fromRGB(99, 112, 245),
		AccentText = Color3.fromRGB(255, 255, 255),
		Text = Color3.fromRGB(232, 233, 240),
		SubText = Color3.fromRGB(138, 141, 153),
	},
	Light = {
		Background = Color3.fromRGB(244, 245, 248),
		Sidebar = Color3.fromRGB(255, 255, 255),
		Card = Color3.fromRGB(255, 255, 255),
		Element = Color3.fromRGB(236, 238, 242),
		ElementHover = Color3.fromRGB(224, 227, 234),
		Stroke = Color3.fromRGB(223, 226, 232),
		Accent = Color3.fromRGB(70, 90, 224),
		AccentText = Color3.fromRGB(255, 255, 255),
		Text = Color3.fromRGB(26, 28, 34),
		SubText = Color3.fromRGB(108, 112, 124),
	},
	Blue = {
		Background = Color3.fromRGB(9, 13, 19),
		Sidebar = Color3.fromRGB(13, 19, 27),
		Card = Color3.fromRGB(17, 26, 36),
		Element = Color3.fromRGB(25, 38, 51),
		ElementHover = Color3.fromRGB(35, 54, 72),
		Stroke = Color3.fromRGB(29, 44, 59),
		Accent = Color3.fromRGB(56, 160, 255),
		AccentText = Color3.fromRGB(6, 18, 28),
		Text = Color3.fromRGB(230, 240, 250),
		SubText = Color3.fromRGB(118, 142, 165),
	},
	Green = {
		Background = Color3.fromRGB(10, 13, 11),
		Sidebar = Color3.fromRGB(14, 18, 15),
		Card = Color3.fromRGB(19, 24, 20),
		Element = Color3.fromRGB(27, 34, 29),
		ElementHover = Color3.fromRGB(38, 48, 40),
		Stroke = Color3.fromRGB(32, 42, 34),
		Accent = Color3.fromRGB(46, 204, 113),
		AccentText = Color3.fromRGB(6, 20, 11),
		Text = Color3.fromRGB(230, 240, 232),
		SubText = Color3.fromRGB(122, 143, 127),
	},
	Yellow = {
		Background = Color3.fromRGB(18, 15, 9),
		Sidebar = Color3.fromRGB(24, 20, 12),
		Card = Color3.fromRGB(31, 26, 15),
		Element = Color3.fromRGB(43, 36, 20),
		ElementHover = Color3.fromRGB(58, 48, 26),
		Stroke = Color3.fromRGB(48, 40, 22),
		Accent = Color3.fromRGB(242, 193, 62),
		AccentText = Color3.fromRGB(30, 24, 8),
		Text = Color3.fromRGB(245, 240, 226),
		SubText = Color3.fromRGB(160, 145, 100),
	},
}

local THEME_ORDER = { "Dark", "Light", "Blue", "Green", "Yellow" }

--==============================================================
-- Stockage des configs
--
-- Les exécuteurs exposent writefile/readfile ; dans Studio ces globales
-- n'existent pas, on retombe alors sur un stockage mémoire (perdu au
-- redémarrage, mais l'UI reste fonctionnelle).
--==============================================================

local Storage = {}
do
	-- Une globale absente vaut nil, donc ces tests sont sûrs dans Studio.
	local hasFS = (type(writefile) == "function")
		and (type(readfile) == "function")
		and (type(isfile) == "function")

	local memory = {}

	function Storage.IsPersistent()
		return hasFS
	end

	function Storage.Read(fileName)
		if hasFS then
			local ok, content = pcall(function()
				if isfile(fileName) then
					return readfile(fileName)
				end
				return nil
			end)
			if ok and content then
				local decoded
				local decodeOk = pcall(function()
					decoded = HttpService:JSONDecode(content)
				end)
				if decodeOk then
					return decoded
				end
			end
			return nil
		end
		return memory[fileName]
	end

	function Storage.Write(fileName, tbl)
		if hasFS then
			local encoded
			local ok = pcall(function()
				encoded = HttpService:JSONEncode(tbl)
			end)
			if ok then
				pcall(function()
					writefile(fileName, encoded)
				end)
			end
			return
		end
		memory[fileName] = tbl
	end
end

--==============================================================
-- Helpers
--==============================================================

local function new(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function stroke(parent, color, thickness)
	return new("UIStroke", {
		Color = color or Color3.fromRGB(0, 0, 0),
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- connections : table où déposer les connexions globales, pour que Destroy()
-- puisse les couper (contrairement aux signaux d'instance, elles survivent à
-- la destruction du ScreenGui).
local function makeDraggable(handle, target, connections)
	local dragging = false
	local dragStart, startPos
	local moved = false

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	-- Le suivi passe par UserInputService plutôt que par handle.InputChanged :
	-- ce dernier ne se déclenche que sous le curseur, donc un mouvement rapide
	-- qui sort de la poignée interrompait le déplacement en plein glisser.
	local movedConn = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			if delta.Magnitude > 3 then
				moved = true
			end
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- Idem au relâchement : le bouton peut très bien être lâché hors de la poignée.
	local endedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	if connections then
		table.insert(connections, movedConn)
		table.insert(connections, endedConn)
	end

	return function()
		return moved
	end
end

--==============================================================
-- Classes
--==============================================================

local UILib = {}
UILib.__index = UILib
UILib.Themes = THEMES
UILib.ThemeOrder = THEME_ORDER

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

--------------------------------------------------------------
-- Thème
--------------------------------------------------------------

-- Enregistre fn puis l'exécute tout de suite avec le thème courant : chaque
-- composant s'initialise et se remet à jour automatiquement à chaque SetTheme.
function UILib:OnTheme(fn)
	table.insert(self.ThemeListeners, fn)
	fn(self.Theme)
end

function UILib:SetTheme(name)
	local theme = THEMES[name]
	if not theme then
		return
	end
	self.Theme = theme
	self.ThemeName = name
	for _, fn in ipairs(self.ThemeListeners) do
		fn(theme)
	end
end

--------------------------------------------------------------
-- Flags (valeurs sauvegardables)
--------------------------------------------------------------

function UILib:_Register(flag, getter, setter)
	if not flag then
		return
	end
	self.Flags[flag] = { Get = getter, Set = setter }
end

function UILib:_Unregister(flag)
	if flag then
		self.Flags[flag] = nil
	end
end

function UILib:_Store()
	return Storage.Read(self.ConfigFile) or { Configs = {}, LastUsed = nil, AutoLoad = false }
end

function UILib:ListConfigs()
	local names = {}
	for name in pairs(self:_Store().Configs) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function UILib:SaveConfig(name)
	if not name or name == "" then
		return false
	end
	local store = self:_Store()
	local values = {}
	for flag, entry in pairs(self.Flags) do
		local ok, v = pcall(entry.Get)
		if ok then
			values[flag] = v
		end
	end
	store.Configs[name] = { Theme = self.ThemeName, Values = values }
	store.LastUsed = name
	Storage.Write(self.ConfigFile, store)
	self:_RefreshConfigList()
	return true
end

function UILib:LoadConfig(name)
	local store = self:_Store()
	local cfg = store.Configs[name]
	if not cfg then
		return false
	end
	if cfg.Theme then
		self:SetTheme(cfg.Theme)
	end
	for flag, value in pairs(cfg.Values or {}) do
		local entry = self.Flags[flag]
		if entry then
			pcall(entry.Set, value)
		end
	end
	store.LastUsed = name
	Storage.Write(self.ConfigFile, store)
	return true
end

function UILib:DeleteConfig(name)
	local store = self:_Store()
	if not store.Configs[name] then
		return false
	end
	store.Configs[name] = nil
	if store.LastUsed == name then
		store.LastUsed = nil
	end
	Storage.Write(self.ConfigFile, store)
	self:_RefreshConfigList()
	return true
end

function UILib:SetAutoLoad(enabled)
	local store = self:_Store()
	store.AutoLoad = enabled and true or false
	Storage.Write(self.ConfigFile, store)
end

-- À appeler à la toute fin du script, une fois tous les éléments créés.
function UILib:AutoLoad()
	local store = self:_Store()
	if store.AutoLoad and store.LastUsed then
		self:LoadConfig(store.LastUsed)
	end
	self:_RefreshConfigList()
end

--------------------------------------------------------------
-- Construction du hub
--------------------------------------------------------------

function UILib.new(options, legacyTheme)
	-- Compat v1 : UILib.new("Titre", "Blue") fonctionne toujours.
	if type(options) == "string" then
		options = { Title = options, Theme = legacyTheme }
	end
	options = options or {}

	local self = setmetatable({}, UILib)

	self.ThemeName = THEMES[options.Theme] and options.Theme or "Dark"
	self.Theme = THEMES[self.ThemeName]
	self.ThemeListeners = {}
	self.Flags = {}
	self.Tabs = {}
	self.Categories = {}
	self.Connections = {}
	self.UnloadCallbacks = {}
	self.ConfigFile = (options.ConfigFile or "UILib_Config") .. ".json"

	local parentGui = playerGui
	if type(gethui) == "function" then
		local ok, hidden = pcall(gethui)
		if ok and hidden then
			parentGui = hidden
		end
	end

	local screenGui = new("ScreenGui", {
		Name = "UILib_Hub",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parentGui,
	})
	self.ScreenGui = screenGui

	----------------------------------------------------------
	-- Icône flottante
	----------------------------------------------------------
	local hubIcon = new("Frame", {
		Name = "HubIcon",
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.new(0, 20, 0.5, -24),
		Parent = screenGui,
	})
	corner(hubIcon, 24)
	local hubStroke = stroke(hubIcon, nil, 2)
	self:OnTheme(function(theme)
		hubIcon.BackgroundColor3 = theme.Accent
		hubStroke.Color = theme.Background
	end)

	local hubLabel = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "☰",
		TextSize = 22,
		Font = FONT_BOLD,
		Parent = hubIcon,
	})
	self:OnTheme(function(theme)
		hubLabel.TextColor3 = theme.AccentText
	end)

	----------------------------------------------------------
	-- Panneau
	----------------------------------------------------------
	-- Taille du panneau, bornée à l'écran : sur une petite résolution, un
	-- panneau plus grand que la fenêtre serait pire que des cartes serrées.
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local PANEL_W = math.min(options.Width or 940, math.max(viewport.X - 60, 480))
	local PANEL_H = math.min(options.Height or 580, math.max(viewport.Y - 60, 320))
	local panel = new("Frame", {
		Name = "Panel",
		Size = UDim2.fromOffset(PANEL_W, PANEL_H),
		Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2),
		Visible = false,
		ClipsDescendants = true,
		Parent = screenGui,
	})
	corner(panel, 10)
	local panelStroke = stroke(panel)
	self:OnTheme(function(theme)
		panel.BackgroundColor3 = theme.Background
		panelStroke.Color = theme.Stroke
	end)
	self.Panel = panel

	-- Barre du haut
	local topBar = new("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	local burger = new("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.fromOffset(12, 9),
		Text = "☰",
		TextSize = 15,
		Font = FONT,
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(burger, 6)

	local titleLabel = new("TextLabel", {
		Size = UDim2.new(1, -200, 0, 16),
		Position = UDim2.fromOffset(48, 7),
		BackgroundTransparency = 1,
		Text = options.Title or "UI Lib",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT_BOLD,
		TextSize = 15,
		Parent = topBar,
	})

	local subtitleLabel = new("TextLabel", {
		Size = UDim2.new(1, -200, 0, 13),
		Position = UDim2.fromOffset(48, 23),
		BackgroundTransparency = 1,
		Text = options.Subtitle or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 11,
		Parent = topBar,
	})

	local closeBtn = new("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -38, 0, 9),
		Text = "✕",
		TextSize = 13,
		Font = FONT,
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(closeBtn, 6)

	local minBtn = new("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -70, 0, 9),
		Text = "—",
		TextSize = 13,
		Font = FONT,
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(minBtn, 6)

	self:OnTheme(function(theme)
		titleLabel.TextColor3 = theme.Text
		subtitleLabel.TextColor3 = theme.SubText
		for _, b in ipairs({ burger, closeBtn, minBtn }) do
			b.BackgroundColor3 = theme.Element
			b.TextColor3 = theme.Text
		end
	end)

	-- Sidebar
	local sidebar = new("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 168, 1, -44),
		Position = UDim2.fromOffset(0, 44),
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = panel,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = sidebar,
	})
	self:OnTheme(function(theme)
		sidebar.BackgroundColor3 = theme.Sidebar
		sidebar.ScrollBarImageColor3 = theme.Stroke
	end)
	self.Sidebar = sidebar

	local content = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -168, 1, -44),
		Position = UDim2.fromOffset(168, 44),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = panel,
	})
	self.Content = content

	----------------------------------------------------------
	-- Interactions fenêtre
	----------------------------------------------------------
	local isDragged = makeDraggable(hubIcon, hubIcon, self.Connections)
	hubIcon.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not isDragged() then
				panel.Visible = not panel.Visible
			end
		end
	end)
	makeDraggable(topBar, panel, self.Connections)

	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = minimized and UDim2.fromOffset(PANEL_W, 44) or UDim2.fromOffset(PANEL_W, PANEL_H),
		}):Play()
	end)

	local sidebarOpen = true
	burger.MouseButton1Click:Connect(function()
		sidebarOpen = not sidebarOpen
		local w = sidebarOpen and 168 or 0
		TweenService:Create(sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, w, 1, -44),
		}):Play()
		TweenService:Create(content, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(1, -w, 1, -44),
			Position = UDim2.fromOffset(w, 44),
		}):Play()
	end)

	self:_BuildSettingsTab()

	return self
end

--------------------------------------------------------------
-- Sidebar : catégories + onglets
--------------------------------------------------------------

function UILib:_GetCategory(name, order)
	if self.Categories[name] then
		return self.Categories[name]
	end

	local label = new("TextLabel", {
		Name = name .. "Category",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 11,
		LayoutOrder = order,
		Parent = self.Sidebar,
	})
	self:OnTheme(function(theme)
		label.TextColor3 = theme.SubText
	end)

	local cat = { Label = label, Order = order, Count = 0 }
	self.Categories[name] = cat
	return cat
end

function UILib:AddTab(name, categoryName, internal)
	categoryName = categoryName or "Menu"
	local baseOrder = internal and 9000 or (100 * (1 + #self.Tabs))
	local cat = self:_GetCategory(categoryName, internal and 9000 or baseOrder)
	cat.Count = cat.Count + 1

	local tab = Tab.new(self, name, cat.Order + cat.Count)
	table.insert(self.Tabs, tab)

	-- L'onglet réglages est créé en premier : il reste affiché tant qu'aucun
	-- onglet du script n'existe, puis cède la place au premier vrai onglet.
	if not self.Selected or (self.SelectedInternal and not internal) then
		self:SelectTab(tab)
		self.SelectedInternal = internal and true or false
	end

	return tab
end

-- Compat v1
function UILib:AddWindow(name, categoryName)
	return self:AddTab(name, categoryName or "Menu")
end

function UILib:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		t.Page.Visible = false
		t:_Refresh(self.Theme)
	end
	tab.Page.Visible = true
	tab:_Refresh(self.Theme)
	self.Selected = tab
end

--------------------------------------------------------------
-- Onglet
--------------------------------------------------------------

function Tab.new(hub, name, order)
	local self = setmetatable({}, Tab)
	self.Hub = hub
	self.Name = name
	self.Sections = {}
	self.ColumnCount = 2
	self._nextColumn = 1

	-- Bouton dans la sidebar
	local button = new("TextButton", {
		Name = name .. "Tab",
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = hub.Sidebar,
	})
	corner(button, 6)

	local marker = new("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BorderSizePixel = 0,
		Parent = button,
	})
	corner(marker, 2)

	local label = new("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 13,
		Parent = button,
	})

	self.Button = button
	self.Marker = marker
	self.Label = label

	-- Page
	local page = new("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = hub.Content,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		Parent = page,
	})
	self.Page = page

	-- Colonnes
	local columnsHolder = new("Frame", {
		Name = "Columns",
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = page,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = columnsHolder,
	})

	self.Columns = {}
	for i = 1, self.ColumnCount do
		local col = new("Frame", {
			Name = "Column" .. i,
			Size = UDim2.new(1 / self.ColumnCount, -5, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Parent = columnsHolder,
		})
		new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = col,
		})
		self.Columns[i] = col
	end

	hub:OnTheme(function(theme)
		page.ScrollBarImageColor3 = theme.Stroke
		self:_Refresh(theme)
	end)

	button.MouseButton1Click:Connect(function()
		hub:SelectTab(self)
	end)

	return self
end

function Tab:_Refresh(theme)
	local active = self.Page.Visible
	self.Button.BackgroundColor3 = active and theme.Element or theme.Sidebar
	self.Button.BackgroundTransparency = active and 0 or 1
	self.Label.TextColor3 = active and theme.Accent or theme.SubText
	self.Marker.BackgroundColor3 = theme.Accent
	self.Marker.Visible = active
end

function Tab:AddSection(name, opts)
	opts = opts or {}
	local columnIndex = opts.Column
	if not columnIndex then
		columnIndex = self._nextColumn
		self._nextColumn = (self._nextColumn % self.ColumnCount) + 1
	end
	columnIndex = math.clamp(columnIndex, 1, self.ColumnCount)

	local section = Section.new(self, name, self.Columns[columnIndex], opts)
	table.insert(self.Sections, section)
	return section
end

-- Compat v1 : les éléments ajoutés directement sur l'onglet vont dans une
-- section par défaut, pour que l'ancien code continue de marcher.
local function defaultSection(tab)
	if not tab._default then
		tab._default = tab:AddSection(tab.Name)
	end
	return tab._default
end

for _, method in ipairs({ "AddButton", "AddToggle", "AddSlider", "AddLabel", "AddTextbox", "AddDropdown", "AddNote" }) do
	Tab[method] = function(self, ...)
		local sec = defaultSection(self)
		return sec[method](sec, ...)
	end
end

--------------------------------------------------------------
-- Section (carte)
--------------------------------------------------------------

function Section.new(tab, name, parentColumn, opts)
	local self = setmetatable({}, Section)
	local hub = tab.Hub
	self.Hub = hub
	self.Tab = tab
	self.Name = name

	local card = new("Frame", {
		Name = name .. "Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = opts.Order or (#tab.Sections + 1),
		Parent = parentColumn,
	})
	corner(card, 8)
	local cardStroke = stroke(card)
	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = card,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = card,
	})
	self.Card = card

	-- En-tête : titre + interrupteur maître optionnel
	local header = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = card,
	})
	local headerLabel = new("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT_BOLD,
		TextSize = 13,
		Parent = header,
	})

	hub:OnTheme(function(theme)
		card.BackgroundColor3 = theme.Card
		cardStroke.Color = theme.Stroke
		headerLabel.TextColor3 = theme.Text
	end)

	if opts.Toggle then
		local flag = opts.Flag or (tab.Name .. "/" .. name .. "/__section")
		local state = opts.Default or false
		local callback = opts.Callback or function() end

		local switch = new("TextButton", {
			Size = UDim2.fromOffset(38, 20),
			Position = UDim2.new(1, -38, 0.5, -10),
			Text = "",
			AutoButtonColor = false,
			Parent = header,
		})
		corner(switch, 10)
		local knob = new("Frame", {
			Size = UDim2.fromOffset(14, 14),
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Parent = switch,
		})
		corner(knob, 7)

		local function refresh(animate)
			local theme = hub.Theme
			local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
			local targetColor = state and theme.Accent or theme.ElementHover
			if animate then
				TweenService:Create(switch, TweenInfo.new(0.15), { BackgroundColor3 = targetColor }):Play()
				TweenService:Create(knob, TweenInfo.new(0.15), { Position = targetPos }):Play()
			else
				switch.BackgroundColor3 = targetColor
				knob.Position = targetPos
			end
		end

		hub:OnTheme(function()
			refresh(false)
		end)

		switch.MouseButton1Click:Connect(function()
			state = not state
			refresh(true)
			callback(state)
		end)

		hub:_Register(flag, function()
			return state
		end, function(v)
			state = v and true or false
			refresh(false)
			callback(state)
		end)

		self.Switch = {
			Set = function(_, v)
				state = v and true or false
				refresh(true)
				callback(state)
			end,
			Get = function()
				return state
			end,
		}
	end

	self._order = 1
	return self
end

function Section:_nextOrder()
	self._order = self._order + 1
	return self._order
end

function Section:_flagFor(text, explicit)
	return explicit or (self.Tab.Name .. "/" .. self.Name .. "/" .. tostring(text))
end

--------------------------------------------------------------
-- Éléments
--
-- Chaque Add* renvoie une table exposant :
--   :Update<Type>(...)  mêmes paramètres que le Add* correspondant ; tout
--                       argument nil laisse la valeur en place
--   :Remove()           retire l'élément de la section
--   .Instance           l'objet Roblox sous-jacent, si besoin d'un réglage fin
-- Les éléments à valeur (toggle, slider, textbox, dropdown) ont en plus
-- :Set(v) et :Get().
--------------------------------------------------------------

-- Options acceptées par tous les éléments, à la création comme à la mise à jour.
local function applyCommonOpts(instance, opts)
	if opts.Visible ~= nil then
		instance.Visible = opts.Visible
	end
	if opts.Order ~= nil then
		instance.LayoutOrder = opts.Order
	end
end

function Section:AddButton(text, callback, opts)
	opts = opts or {}
	local hub = self.Hub
	callback = callback or function() end

	local button = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		Text = text,
		Font = FONT,
		TextSize = 13,
		AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	corner(button, 6)

	hub:OnTheme(function(theme)
		button.BackgroundColor3 = theme.Element
		button.TextColor3 = theme.Text
	end)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = hub.Theme.ElementHover }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = hub.Theme.Element }):Play()
	end)
	button.MouseButton1Click:Connect(function()
		callback()
	end)

	applyCommonOpts(button, opts)

	local api = { Instance = button }

	function api:UpdateButton(newText, newCallback, newOpts)
		if newText ~= nil then
			button.Text = newText
		end
		if newCallback ~= nil then
			callback = newCallback
		end
		applyCommonOpts(button, newOpts or {})
		return api
	end

	function api:Remove()
		button:Destroy()
	end

	return api
end

function Section:AddToggle(text, default, callback, opts)
	opts = opts or {}
	local hub = self.Hub
	local state = default and true or false
	callback = callback or function() end
	local flag = self:_flagFor(text, opts.Flag)

	local holder = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	corner(holder, 6)

	local label = new("TextLabel", {
		Size = UDim2.new(1, -52, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 13,
		Parent = holder,
	})

	local switch = new("Frame", {
		Size = UDim2.fromOffset(34, 18),
		Position = UDim2.new(1, -44, 0.5, -9),
		BorderSizePixel = 0,
		Parent = holder,
	})
	corner(switch, 9)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = switch,
	})
	corner(knob, 6)

	local function refresh(animate)
		local theme = hub.Theme
		local targetPos = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
		local targetColor = state and theme.Accent or theme.ElementHover
		if animate then
			TweenService:Create(switch, TweenInfo.new(0.15), { BackgroundColor3 = targetColor }):Play()
			TweenService:Create(knob, TweenInfo.new(0.15), { Position = targetPos }):Play()
		else
			switch.BackgroundColor3 = targetColor
			knob.Position = targetPos
		end
	end

	hub:OnTheme(function(theme)
		holder.BackgroundColor3 = theme.Element
		label.TextColor3 = theme.Text
		refresh(false)
	end)

	holder.MouseButton1Click:Connect(function()
		state = not state
		refresh(true)
		callback(state)
	end)

	local function getState()
		return state
	end

	local function applyState(v, animate)
		state = v and true or false
		refresh(animate)
		callback(state)
	end

	local function register()
		hub:_Register(flag, getState, function(v)
			applyState(v, false)
		end)
	end
	register()

	applyCommonOpts(holder, opts)

	local api = { Instance = holder }

	function api:Set(v)
		applyState(v, true)
	end

	function api:Get()
		return state
	end

	function api:UpdateToggle(newText, newDefault, newCallback, newOpts)
		newOpts = newOpts or {}
		if newText ~= nil then
			label.Text = newText
		end
		if newCallback ~= nil then
			callback = newCallback
		end
		-- Le flag reste celui d'origine tant qu'on n'en demande pas un autre :
		-- le renommage d'un élément ne doit pas invalider les configs déjà
		-- enregistrées sous l'ancienne clé.
		if newOpts.Flag ~= nil and newOpts.Flag ~= flag then
			hub:_Unregister(flag)
			flag = newOpts.Flag
			register()
		end
		if newDefault ~= nil then
			applyState(newDefault, true)
		end
		applyCommonOpts(holder, newOpts)
		return api
	end

	function api:Remove()
		hub:_Unregister(flag)
		holder:Destroy()
	end

	return api
end

function Section:AddSlider(text, min, max, default, callback, opts)
	opts = opts or {}
	local hub = self.Hub
	local value = math.clamp(default or min, min, max)
	callback = callback or function() end
	local flag = self:_flagFor(text, opts.Flag)

	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	corner(holder, 6)

	local label = new("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Text = text .. ": " .. tostring(value),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 12,
		Parent = holder,
	})

	local track = new("Frame", {
		Size = UDim2.new(1, -20, 0, 5),
		Position = UDim2.new(0, 10, 1, -14),
		BorderSizePixel = 0,
		Parent = holder,
	})
	corner(track, 3)

	local fill = new("Frame", {
		Size = UDim2.fromScale((value - min) / (max - min), 1),
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 3)

	hub:OnTheme(function(theme)
		holder.BackgroundColor3 = theme.Element
		label.TextColor3 = theme.Text
		track.BackgroundColor3 = theme.ElementHover
		fill.BackgroundColor3 = theme.Accent
	end)

	-- UpdateSlider peut amener min == max ; on évite la division par zéro.
	local function span()
		return math.max(max - min, 1)
	end

	local function apply(v, fire)
		value = math.clamp(math.floor(v + 0.5), min, max)
		fill.Size = UDim2.fromScale((value - min) / span(), 1)
		label.Text = text .. ": " .. tostring(value)
		if fire then
			callback(value)
		end
	end

	local dragging = false
	local function setFromX(x)
		local relative = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		apply(min + span() * relative, true)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	table.insert(hub.Connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end))
	table.insert(hub.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local function getValue()
		return value
	end

	local function register()
		hub:_Register(flag, getValue, function(v)
			apply(tonumber(v) or min, true)
		end)
	end
	register()

	applyCommonOpts(holder, opts)

	local api = { Instance = holder }

	function api:Set(v)
		apply(v, true)
	end

	function api:Get()
		return value
	end

	function api:UpdateSlider(newText, newMin, newMax, newDefault, newCallback, newOpts)
		newOpts = newOpts or {}
		if newText ~= nil then
			text = newText
		end
		if newMin ~= nil then
			min = newMin
		end
		if newMax ~= nil then
			max = newMax
		end
		if newCallback ~= nil then
			callback = newCallback
		end
		if newOpts.Flag ~= nil and newOpts.Flag ~= flag then
			hub:_Unregister(flag)
			flag = newOpts.Flag
			register()
		end
		-- Redessine dans tous les cas : le libellé et la plage ont pu changer,
		-- et la valeur courante peut désormais être hors bornes.
		apply(newDefault ~= nil and newDefault or value, newDefault ~= nil)
		applyCommonOpts(holder, newOpts)
		return api
	end

	function api:Remove()
		hub:_Unregister(flag)
		holder:Destroy()
	end

	return api
end

function Section:AddTextbox(placeholder, callback, opts)
	opts = opts or {}
	local hub = self.Hub
	callback = callback or function() end
	local flag = self:_flagFor(placeholder, opts.Flag)

	local box = new("TextBox", {
		Size = UDim2.new(1, 0, 0, 30),
		Text = opts.Default or "",
		PlaceholderText = placeholder,
		ClearTextOnFocus = false,
		Font = FONT,
		TextSize = 13,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	corner(box, 6)

	hub:OnTheme(function(theme)
		box.BackgroundColor3 = theme.Element
		box.TextColor3 = theme.Text
		box.PlaceholderColor3 = theme.SubText
	end)

	box.FocusLost:Connect(function(enterPressed)
		callback(box.Text, enterPressed)
	end)

	local function getText()
		return box.Text
	end

	local saved = opts.Save and true or false
	local function register()
		hub:_Register(flag, getText, function(v)
			box.Text = tostring(v)
		end)
	end
	if saved then
		register()
	end

	applyCommonOpts(box, opts)

	local api = { Instance = box }

	function api:Set(v)
		box.Text = tostring(v)
	end

	function api:Get()
		return box.Text
	end

	function api:UpdateTextbox(newPlaceholder, newCallback, newOpts)
		newOpts = newOpts or {}
		if newPlaceholder ~= nil then
			box.PlaceholderText = newPlaceholder
		end
		if newCallback ~= nil then
			callback = newCallback
		end
		if newOpts.Default ~= nil then
			box.Text = tostring(newOpts.Default)
		end
		if newOpts.Flag ~= nil and newOpts.Flag ~= flag then
			hub:_Unregister(flag)
			flag = newOpts.Flag
			if saved then
				register()
			end
		end
		if newOpts.Save ~= nil and (newOpts.Save and true or false) ~= saved then
			saved = newOpts.Save and true or false
			if saved then
				register()
			else
				hub:_Unregister(flag)
			end
		end
		applyCommonOpts(box, newOpts)
		return api
	end

	function api:Remove()
		hub:_Unregister(flag)
		box:Destroy()
	end

	return api
end

function Section:AddDropdown(text, options, default, callback, opts)
	opts = opts or {}
	local hub = self.Hub
	callback = callback or function() end
	local flag = self:_flagFor(text, opts.Flag)
	local selected = default
	local expanded = false

	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	local header = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 0,
		Parent = holder,
	})
	corner(header, 6)

	local headerLabel = new("TextLabel", {
		Size = UDim2.new(1, -34, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Text = text .. ": " .. tostring(selected or "—"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = FONT,
		TextSize = 13,
		Parent = header,
	})

	local arrow = new("TextLabel", {
		Size = UDim2.fromOffset(20, 30),
		Position = UDim2.new(1, -26, 0, 0),
		BackgroundTransparency = 1,
		Text = "▾",
		Font = FONT,
		TextSize = 12,
		Parent = header,
	})

	local list = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		LayoutOrder = 1,
		Parent = holder,
	})
	corner(list, 6)
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = list,
	})

	hub:OnTheme(function(theme)
		header.BackgroundColor3 = theme.Element
		headerLabel.TextColor3 = theme.Text
		arrow.TextColor3 = theme.SubText
		list.BackgroundColor3 = theme.Element
	end)

	local api = {}

	local function select(option, fire)
		selected = option
		headerLabel.Text = text .. ": " .. tostring(option or "—")
		if fire then
			callback(option)
		end
	end

	function api:SetOptions(newOptions)
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, option in ipairs(newOptions) do
			local optBtn = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
				Text = tostring(option),
				Font = FONT,
				TextSize = 12,
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				LayoutOrder = i,
				Parent = list,
			})
			corner(optBtn, 4)
			hub:OnTheme(function(theme)
				optBtn.TextColor3 = theme.Text
			end)
			optBtn.MouseEnter:Connect(function()
				optBtn.BackgroundTransparency = 0
				optBtn.BackgroundColor3 = hub.Theme.ElementHover
			end)
			optBtn.MouseLeave:Connect(function()
				optBtn.BackgroundTransparency = 1
			end)
			optBtn.MouseButton1Click:Connect(function()
				select(option, true)
				expanded = false
				list.Visible = false
				arrow.Text = "▾"
			end)
		end
		-- La sélection courante peut avoir disparu de la nouvelle liste.
		local stillThere = false
		for _, option in ipairs(newOptions) do
			if option == selected then
				stillThere = true
				break
			end
		end
		if not stillThere then
			select(newOptions[1], false)
		end
	end

	function api:Set(value)
		select(value, true)
	end

	function api:Get()
		return selected
	end

	header.MouseButton1Click:Connect(function()
		expanded = not expanded
		list.Visible = expanded
		arrow.Text = expanded and "▴" or "▾"
	end)

	api:SetOptions(options or {})
	if default then
		select(default, false)
	end

	local saved = opts.Save and true or false
	local function register()
		hub:_Register(flag, function()
			return selected
		end, function(v)
			select(v, true)
		end)
	end
	if saved then
		register()
	end

	applyCommonOpts(holder, opts)
	api.Instance = holder

	function api:UpdateDropdown(newText, newOptions, newDefault, newCallback, newOpts)
		newOpts = newOpts or {}
		if newText ~= nil then
			text = newText
		end
		if newCallback ~= nil then
			callback = newCallback
		end
		if newOptions ~= nil then
			api:SetOptions(newOptions)
		end
		if newOpts.Flag ~= nil and newOpts.Flag ~= flag then
			hub:_Unregister(flag)
			flag = newOpts.Flag
			if saved then
				register()
			end
		end
		if newOpts.Save ~= nil and (newOpts.Save and true or false) ~= saved then
			saved = newOpts.Save and true or false
			if saved then
				register()
			else
				hub:_Unregister(flag)
			end
		end
		if newDefault ~= nil then
			select(newDefault, true)
		else
			-- Réécrit l'en-tête : le libellé a pu changer sans que la valeur bouge.
			select(selected, false)
		end
		applyCommonOpts(holder, newOpts)
		return api
	end

	function api:Remove()
		hub:_Unregister(flag)
		holder:Destroy()
	end

	return api
end

function Section:AddLabel(text, opts)
	opts = opts or {}
	local hub = self.Hub
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 12,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	hub:OnTheme(function(theme)
		label.TextColor3 = theme.SubText
	end)

	applyCommonOpts(label, opts)

	local api = { Instance = label }

	function api:Set(v)
		label.Text = tostring(v)
	end

	function api:Get()
		return label.Text
	end

	function api:UpdateLabel(newText, newOpts)
		if newText ~= nil then
			label.Text = tostring(newText)
		end
		applyCommonOpts(label, newOpts or {})
		return api
	end

	function api:Remove()
		label:Destroy()
	end

	return api
end

function Section:AddNote(text, opts)
	opts = opts or {}
	local hub = self.Hub
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = text,
		TextWrapped = true,
		Font = FONT,
		TextSize = 11,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	hub:OnTheme(function(theme)
		label.TextColor3 = theme.SubText
	end)

	applyCommonOpts(label, opts)

	local api = { Instance = label }

	function api:Set(v)
		label.Text = tostring(v)
	end

	function api:Get()
		return label.Text
	end

	function api:UpdateNote(newText, newOpts)
		if newText ~= nil then
			label.Text = tostring(newText)
		end
		applyCommonOpts(label, newOpts or {})
		return api
	end

	function api:Remove()
		label:Destroy()
	end

	return api
end

-- Rangée de pastilles de couleur pour changer de thème.
function Section:AddThemePicker()
	local hub = self.Hub

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Card,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = row,
	})

	local strokes = {}
	for _, name in ipairs(THEME_ORDER) do
		local swatch = new("TextButton", {
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = THEMES[name].Accent,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		corner(swatch, 15)
		strokes[name] = stroke(swatch, nil, 0)
		swatch.MouseButton1Click:Connect(function()
			hub:SetTheme(name)
		end)
	end

	hub:OnTheme(function(theme)
		for name, s in pairs(strokes) do
			s.Thickness = (name == hub.ThemeName) and 2 or 0
			s.Color = theme.Text
		end
	end)

	return row
end

--------------------------------------------------------------
-- Onglet « UI Settings » généré automatiquement
--------------------------------------------------------------

function UILib:_BuildSettingsTab()
	local tab = self:AddTab("UI Settings", "Settings", true)

	local cfgSection = tab:AddSection("Configurations", { Column = 1 })
	self._configDropdown = cfgSection:AddDropdown("Config", self:ListConfigs(), nil, function() end)

	cfgSection:AddButton("Charger la config", function()
		local name = self._configDropdown:Get()
		if name then
			self:LoadConfig(name)
		end
	end)

	cfgSection:AddButton("Supprimer la config", function()
		local name = self._configDropdown:Get()
		if name then
			self:DeleteConfig(name)
		end
	end)

	local nameBox = cfgSection:AddTextbox("Nom de la nouvelle config...", function() end)
	cfgSection:AddButton("Sauvegarder", function()
		local name = nameBox:Get()
		if name and name ~= "" then
			self:SaveConfig(name)
			nameBox:Set("")
		end
	end)

	local store = self:_Store()
	cfgSection:AddToggle("Charger au démarrage", store.AutoLoad or false, function(on)
		self:SetAutoLoad(on)
	end, { Flag = "__autoload" })

	if not Storage.IsPersistent() then
		cfgSection:AddNote("Stockage fichier indisponible ici : les configs ne survivront pas au redémarrage. Sur un exécuteur (writefile), elles sont enregistrées sur le disque.")
	end

	local themeSection = tab:AddSection("Apparence", { Column = 2 })
	themeSection:AddLabel("Thème de l'interface")
	themeSection:AddThemePicker()
	themeSection:AddNote("Le thème choisi est enregistré avec chaque configuration.")

	local scriptSection = tab:AddSection("Script", { Column = 2 })
	scriptSection:AddButton("Décharger le script", function()
		self:Unload()
	end)
	scriptSection:AddNote("Ferme l'interface et coupe tout ce que la librairie a branché. Il faudra relancer le script pour la rouvrir.")

	self._settingsTab = tab
end

function UILib:_RefreshConfigList()
	if self._configDropdown then
		self._configDropdown:SetOptions(self:ListConfigs())
	end
end

--------------------------------------------------------------
-- Déchargement
--------------------------------------------------------------

-- Permet à chaque module de nettoyer ses propres effets (boucles en cours,
-- valeurs modifiées sur le personnage...) avant que l'interface disparaisse.
function UILib:OnUnload(fn)
	table.insert(self.UnloadCallbacks, fn)
	return fn
end

-- Retire l'interface et coupe tout ce que la librairie a branché.
-- Appelable plusieurs fois sans risque.
function UILib:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true

	-- Le nettoyage des modules passe en premier : ils peuvent encore avoir
	-- besoin de l'interface. Une erreur dans l'un ne doit pas bloquer les autres.
	for _, fn in ipairs(self.UnloadCallbacks) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[UILib] erreur pendant le déchargement : " .. tostring(err))
		end
	end
	self.UnloadCallbacks = {}

	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}

	self.Flags = {}
	self.Tabs = {}
	self.Categories = {}
	self.Selected = nil

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

-- Alias : Destroy existait avant Unload.
function UILib:Destroy()
	self:Unload()
end

-- Déchargement accessible depuis une section ou un onglet, pour les modules
-- qui ne gardent qu'une référence locale et pas le hub entier.
function Section:Unload()
	return self.Hub:Unload()
end

function Tab:Unload()
	return self.Hub:Unload()
end

return UILib
