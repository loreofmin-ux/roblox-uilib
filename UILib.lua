-- UILib : librairie de UI flottante/déplaçable pour Roblox.
-- Version : voir UILib.Version ci-dessous. À incrémenter à chaque modification
-- (majeur = rupture d'API, mineur = ajout, correctif = correction).
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
local RunService = game:GetService("RunService")
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
		-- Pastille du sélecteur : pour Dark et Light on montre le fond plutôt
		-- que l'accent, l'aperçu est plus parlant que la couleur d'accentuation.
		Swatch = Color3.fromRGB(18, 18, 22),
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
		Swatch = Color3.fromRGB(252, 252, 254),
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
	-- Base neutre : le mouvement de couleur vient du dégradé superposé, pas de
	-- la palette elle-même.
	RGB = {
		Background = Color3.fromRGB(12, 12, 16),
		Sidebar = Color3.fromRGB(16, 16, 21),
		Card = Color3.fromRGB(22, 22, 28),
		Element = Color3.fromRGB(33, 33, 41),
		ElementHover = Color3.fromRGB(46, 46, 57),
		Stroke = Color3.fromRGB(38, 38, 48),
		Accent = Color3.fromRGB(190, 110, 245),
		AccentText = Color3.fromRGB(255, 255, 255),
		Text = Color3.fromRGB(236, 236, 243),
		SubText = Color3.fromRGB(140, 140, 156),
		Swatch = Color3.fromRGB(255, 255, 255),
		Rainbow = true,
	},
}

local THEME_ORDER = { "Dark", "Light", "Blue", "Green", "Yellow", "RGB" }

-- Dégradé du thème RGB, réutilisé par le panneau, le rond et la pastille.
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 64, 64)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 200, 64)),
	ColorSequenceKeypoint.new(0.34, Color3.fromRGB(80, 230, 120)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(64, 220, 230)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(90, 130, 255)),
	ColorSequenceKeypoint.new(0.84, Color3.fromRGB(210, 90, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 64, 64)),
})

-- Durée d'un cycle complet du dégradé, en secondes.
local RGB_PERIOD = 9

--==============================================================
-- Traductions
--
-- Seuls les textes produits par la librairie sont concernés : les libellés
-- fournis par le script appelant restent tels qu'il les a écrits.
--==============================================================

local LOCALES = {
	fr = {
		SettingsCategory = "Réglages",
		SettingsTab = "Interface",
		Configurations = "Configurations",
		ConfigDropdown = "Config",
		LoadConfig = "Charger la config",
		DeleteConfig = "Supprimer la config",
		NewConfigName = "Nom de la nouvelle config...",
		Save = "Sauvegarder",
		AutoLoad = "Charger au démarrage",
		StorageNote = "Stockage fichier indisponible ici : les configs ne survivront pas au redémarrage. Sur un exécuteur (writefile), elles sont enregistrées sur le disque.",
		Appearance = "Apparence",
		ThemeLabel = "Thème de l'interface",
		Transparency = "Transparence",
		Language = "Langue",
		AppearanceNote = "Le thème, la transparence et la langue sont enregistrés avec chaque configuration.",
		Script = "Script",
		Unload = "Décharger le script",
		UnloadNote = "Ferme l'interface et coupe tout ce que la librairie a branché. Il faudra relancer le script pour la rouvrir.",
		ReopenHint = "Clique ici pour rouvrir",
	},
	en = {
		SettingsCategory = "Settings",
		SettingsTab = "Interface",
		Configurations = "Configurations",
		ConfigDropdown = "Config",
		LoadConfig = "Load config",
		DeleteConfig = "Delete config",
		NewConfigName = "New config name...",
		Save = "Save",
		AutoLoad = "Load on startup",
		StorageNote = "File storage is unavailable here, so configs will not survive a restart. On an executor (writefile) they are saved to disk.",
		Appearance = "Appearance",
		ThemeLabel = "Interface theme",
		Transparency = "Transparency",
		Language = "Language",
		AppearanceNote = "Theme, transparency and language are saved with each configuration.",
		Script = "Script",
		Unload = "Unload script",
		UnloadNote = "Closes the interface and disconnects everything the library hooked up. You will need to run the script again to reopen it.",
		ReopenHint = "Click here to reopen",
	},
}

-- Libellé affiché -> code, pour le sélecteur de langue.
local LANGUAGE_CHOICES = { English = "en", ["Français"] = "fr" }

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

-- CanvasGroup permet d'estomper un conteneur et tout son contenu via une seule
-- propriété. Absent des clients anciens : on retombe alors sur un Frame, qui
-- n'est simplement pas estompable.
local CANVAS_GROUP_OK = pcall(function()
	Instance.new("CanvasGroup"):Destroy()
end)

local function surfaceClass()
	return CANVAS_GROUP_OK and "CanvasGroup" or "Frame"
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
--==============================================================
-- Icônes
--
-- Gotham ne contient pas les glyphes ☰ ✕ ▾ ✓ : Roblox les remplace alors par
-- des carrés vides. On dessine donc chaque icône avec des Frames, ce qui ne
-- dépend d'aucune police ni d'aucun asset distant.
--==============================================================

local function iconBar(parent, width, thickness, offsetX, offsetY, rotation)
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, offsetX or 0, 0.5, offsetY or 0),
		Size = UDim2.fromOffset(width, thickness),
		Rotation = rotation or 0,
		BorderSizePixel = 0,
		Parent = parent,
	})
	corner(bar, math.max(math.floor(thickness / 2), 1))
	return bar
end

local function iconHolder(parent)
	return new("Frame", {
		Name = "Icon",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = parent,
	})
end

-- Trois barres horizontales.
local function makeBurger(parent, width, thickness, gap)
	local holder = iconHolder(parent)
	local bars = {}
	for i = 1, 3 do
		bars[i] = iconBar(holder, width, thickness, 0, (i - 2) * gap)
	end
	return holder, bars
end

-- Deux barres croisées.
local function makeCross(parent, length, thickness)
	local holder = iconHolder(parent)
	return holder, {
		iconBar(holder, length, thickness, 0, 0, 45),
		iconBar(holder, length, thickness, 0, 0, -45),
	}
end

local function makeDash(parent, width, thickness)
	local holder = iconHolder(parent)
	return holder, { iconBar(holder, width, thickness) }
end

-- Chevron pointant vers le bas. Une barre de longueur L tournée de 45° avance
-- de 0,354*L sur chaque axe : les deux segments se rejoignent donc au centre.
local function makeChevron(parent, length, thickness)
	local holder = iconHolder(parent)
	local dx = math.floor(0.354 * length + 0.5)
	local dy = math.floor(0.177 * length + 0.5)
	return holder, {
		iconBar(holder, length, thickness, -dx, -dy, 45),
		iconBar(holder, length, thickness, dx, -dy, -45),
	}
end

-- Coche : un segment court qui descend, un long qui remonte.
local function makeCheck(parent, scale, thickness)
	local holder = iconHolder(parent)
	return holder, {
		iconBar(holder, math.floor(scale * 0.45), thickness, -math.floor(scale * 0.22), math.floor(scale * 0.14), 45),
		iconBar(holder, math.floor(scale * 0.75), thickness, math.floor(scale * 0.14), 0, -50),
	}
end

local function paintIcon(bars, color)
	for _, bar in ipairs(bars) do
		bar.BackgroundColor3 = color
	end
end

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
UILib.Version = "2.6.0"
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

--------------------------------------------------------------
-- Langue
--------------------------------------------------------------

function UILib:T(key)
	local pack = LOCALES[self.Language] or LOCALES.fr
	return pack[key] or (LOCALES.fr[key] or key)
end

-- Même principe que OnTheme : la fonction est enregistrée puis exécutée tout de
-- suite, et rejouée à chaque changement de langue.
function UILib:OnLanguage(fn)
	table.insert(self.LanguageListeners, fn)
	fn(self.Language)
end

function UILib:SetLanguage(code)
	if not LOCALES[code] or code == self.Language then
		return
	end
	self.Language = code
	for _, fn in ipairs(self.LanguageListeners) do
		fn(code)
	end
end

--------------------------------------------------------------
-- Transparence globale
--------------------------------------------------------------

-- Transparence effective d'une surface, à partir de sa valeur d'origine.
-- Une surface déjà invisible (base = 1) le reste.
function UILib:_Alpha(base)
	local amount = self.Transparency or 0
	return base + (1 - base) * amount
end

-- Plutôt que de marquer chaque élément à sa création, on parcourt l'arbre et on
-- mémorise la transparence d'origine de chaque objet la première fois qu'on le
-- voit. Les éléments ajoutés plus tard sont donc pris en compte tout seuls.
function UILib:_ApplyTransparency()
	if not self.ScreenGui then
		return
	end
	local bases = self._baseTransparency
	for _, obj in ipairs(self.ScreenGui:GetDescendants()) do
		if obj:IsA("GuiObject") then
			local base = bases[obj]
			if base == nil then
				base = obj.BackgroundTransparency
				bases[obj] = base
			end
			obj.BackgroundTransparency = self:_Alpha(base)
		elseif obj:IsA("UIStroke") then
			local base = bases[obj]
			if base == nil then
				base = obj.Transparency
				bases[obj] = base
			end
			obj.Transparency = self:_Alpha(base)
		end
	end
end

-- amount va de 0 (opaque) à 1 (invisible).
function UILib:SetTransparency(amount)
	self.Transparency = math.clamp(tonumber(amount) or 0, 0, 1)
	self:_ApplyTransparency()
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
	-- Les écouteurs de thème réécrivent des couleurs, jamais la transparence :
	-- on la réapplique après coup pour qu'elle ne soit pas perdue.
	self:_ApplyTransparency()
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
	self.Transparency = 0
	self.Language = LOCALES[options.Language] and options.Language or "fr"
	self.LanguageListeners = {}
	-- Clés faibles : les éléments éphémères (ondes du rappel visuel) ne doivent
	-- pas rester référencés ici après leur destruction.
	self._baseTransparency = setmetatable({}, { __mode = "k" })
	self.Animations = options.Animations ~= false
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

	local _, hubBars = makeBurger(hubIcon, 20, 3, 6)
	self:OnTheme(function(theme)
		paintIcon(hubBars, theme.AccentText)
	end)

	----------------------------------------------------------
	-- Panneau
	----------------------------------------------------------
	-- Taille du panneau, bornée à l'écran : sur une petite résolution, un
	-- panneau plus grand que la fenêtre serait pire que des cartes serrées.
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local PANEL_W = math.min(options.Width or 940, math.max(viewport.X - 60, 480))
	local PANEL_H = math.min(options.Height or 580, math.max(viewport.Y - 60, 320))
	local panel = new(surfaceClass(), {
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

	----------------------------------------------------------
	-- Thème RGB : voile dégradé animé
	--
	-- Recalculer toutes les couleurs à chaque image coûterait cher (des
	-- centaines d'écouteurs de thème). On superpose donc un voile dégradé :
	-- deux instances à faire évoluer, et rien à recalculer ailleurs.
	----------------------------------------------------------
	local rgbLayer = new("Frame", {
		Name = "RGBLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 0,
		Visible = false,
		Parent = panel,
	})
	corner(rgbLayer, 10)
	local rgbGradient = new("UIGradient", {
		Color = RAINBOW,
		Rotation = 45, -- la diagonale
		Parent = rgbLayer,
	})

	local hubGradient = new("UIGradient", {
		Color = RAINBOW,
		Rotation = 45,
		Enabled = false,
		Parent = hubIcon,
	})

	local rgbConn
	local function setRainbowActive(active)
		rgbLayer.Visible = active
		hubGradient.Enabled = active

		if active and not rgbConn then
			rgbConn = RunService.RenderStepped:Connect(function()
				local phase = (os.clock() % RGB_PERIOD) / RGB_PERIOD
				local offset = Vector2.new(phase * 2 - 1, 0)
				rgbGradient.Offset = offset
				hubGradient.Offset = offset
			end)
			table.insert(self.Connections, rgbConn)
		elseif not active and rgbConn then
			-- Rien à animer hors du thème RGB : on libère la boucle par image.
			rgbConn:Disconnect()
			rgbConn = nil
		end
	end

	self:OnTheme(function(theme)
		setRainbowActive(theme.Rainbow == true and self.Animations)
	end)

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
		Text = "",
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(burger, 6)
	local _, burgerBars = makeBurger(burger, 13, 2, 4)

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
		-- Subtitle appartient au script appelant (nom du jeu, sa propre version).
		-- Sans valeur, on affiche celle de la librairie plutôt que rien.
		Text = options.Subtitle or ("UILib v" .. UILib.Version),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 11,
		Parent = topBar,
	})

	local closeBtn = new("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -38, 0, 9),
		Text = "",
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(closeBtn, 6)
	local _, closeBars = makeCross(closeBtn, 12, 2)

	local minBtn = new("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -70, 0, 9),
		Text = "",
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(minBtn, 6)
	local _, minBars = makeDash(minBtn, 11, 2)

	self:OnTheme(function(theme)
		titleLabel.TextColor3 = theme.Text
		subtitleLabel.TextColor3 = theme.SubText
		for _, b in ipairs({ burger, closeBtn, minBtn }) do
			b.BackgroundColor3 = theme.Element
		end
		paintIcon(burgerBars, theme.Text)
		paintIcon(closeBars, theme.Text)
		paintIcon(minBars, theme.Text)
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
	-- Déclarés ici car utilisés plus bas dans les gestionnaires de clic, alors
	-- qu'ils ne sont définis qu'à la section suivante : sans cette déclaration
	-- anticipée, les fermetures captureraient un global nil.
	local hideHint

	local canFade = panel:IsA("CanvasGroup")
	local panelOpen = false

	-- Entrée en cascade : le cadre arrive, puis les cartes de l'onglet affiché
	-- s'égrènent. On estompe les cartes plutôt que de les faire glisser : leur
	-- position est imposée par le UIListLayout de la colonne.
	local CARD_STAGGER = 0.055
	local function cascadeCards()
		local tab = self.Selected
		if not tab then
			return
		end
		for index, section in ipairs(tab.Sections) do
			local card = section.Card
			if card and card:IsA("CanvasGroup") then
				card.GroupTransparency = 1
				task.delay(CARD_STAGGER * index, function()
					if not card.Parent then
						return
					end
					if not panelOpen then
						-- Panneau refermé entre-temps : on rétablit sans animer,
						-- pour ne jamais laisser une carte invisible.
						card.GroupTransparency = 0
						return
					end
					TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						GroupTransparency = 0,
					}):Play()
				end)
			end
		end
	end

	local function setPanelOpen(open)
		panelOpen = open

		if not (self.Animations and canFade) then
			-- Remise à zéro explicite : sans fondu, un panneau resté à
			-- GroupTransparency = 1 s'afficherait invisible.
			if canFade then
				panel.GroupTransparency = 0
			end
			panel.Visible = open
			return
		end

		if open then
			panel.GroupTransparency = 1
			panel.Visible = true
			TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				GroupTransparency = 0,
			}):Play()
			cascadeCards()
		else
			local tween = TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
				GroupTransparency = 1,
			})
			-- On ne masque qu'à la fin, et seulement si le panneau n'a pas été
			-- rouvert entre-temps.
			tween.Completed:Connect(function()
				if not panelOpen then
					panel.Visible = false
				end
			end)
			tween:Play()
		end
	end
	self.SetPanelOpen = setPanelOpen

	local isDragged = makeDraggable(hubIcon, hubIcon, self.Connections)
	hubIcon.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not isDragged() then
				setPanelOpen(not panelOpen)
				-- Le message a rempli son office dès que l'utilisateur clique.
				hideHint()
			end
		end
	end)
	makeDraggable(topBar, panel, self.Connections)

	----------------------------------------------------------
	-- Rappel visuel après fermeture
	--
	-- Une fois le panneau fermé par la croix, rien n'indique que c'est le rond
	-- flottant qui le rouvre. On le signale par des ondes et une bulle d'aide.
	----------------------------------------------------------
	-- Largeur automatique : la bulle s'ajuste au texte, qui change avec la langue.
	local hint = new("Frame", {
		Name = "HubHint",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 10, 0.5, 0),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		Parent = hubIcon,
	})
	corner(hint, 6)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = hint,
	})

	local hintLabel = new("TextLabel", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		Parent = hint,
	})

	-- Le rond est déplaçable : posé près du bord droit, une bulle ancrée à sa
	-- droite sortirait de l'écran. On la bascule donc du côté où il y a la place.
	local function positionHint()
		local available = screenGui.AbsoluteSize.X
		if available <= 0 then
			local camera = workspace.CurrentCamera
			available = camera and camera.ViewportSize.X or 1280
		end

		local hubCenterX = hubIcon.AbsolutePosition.X + hubIcon.AbsoluteSize.X / 2
		if hubCenterX > available / 2 then
			hint.AnchorPoint = Vector2.new(1, 0.5)
			hint.Position = UDim2.new(0, -10, 0.5, 0)
		else
			hint.AnchorPoint = Vector2.new(0, 0.5)
			hint.Position = UDim2.new(1, 10, 0.5, 0)
		end
	end
	self:OnLanguage(function()
		hintLabel.Text = self:T("ReopenHint")
	end)

	self:OnTheme(function(theme)
		hint.BackgroundColor3 = theme.Card
		hintLabel.TextColor3 = theme.Text
	end)

	local function ripple()
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = hubIcon,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
		local ringStroke = new("UIStroke", {
			Color = self.Theme.Accent,
			Thickness = 2,
			Parent = ring,
		})

		TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1.9, 1.9),
		}):Play()
		TweenService:Create(ringStroke, TweenInfo.new(0.7), { Transparency = 1 }):Play()

		task.delay(0.75, function()
			ring:Destroy()
		end)
	end

	local hintToken = 0
	local function callAttention()
		if not self.Animations then
			return
		end

		hintToken = hintToken + 1
		local token = hintToken

		-- Recalculé à chaque affichage : le rond a pu être déplacé entre-temps.
		positionHint()
		hint.Visible = true
		hint.BackgroundTransparency = 1
		hintLabel.TextTransparency = 1
		TweenService:Create(hint, TweenInfo.new(0.2), { BackgroundTransparency = self:_Alpha(0) }):Play()
		TweenService:Create(hintLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()

		task.spawn(function()
			for i = 1, 3 do
				-- Un jeton par appel : si le panneau est rouvert entre-temps,
				-- l'ancienne séquence s'arrête au lieu de continuer à clignoter.
				if token ~= hintToken then
					return
				end
				ripple()
				task.wait(0.75)
			end
			if token ~= hintToken then
				return
			end
			TweenService:Create(hint, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(hintLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.wait(0.32)
			if token == hintToken then
				hint.Visible = false
			end
		end)
	end

	function hideHint()
		hintToken = hintToken + 1
		hint.Visible = false
	end

	closeBtn.MouseButton1Click:Connect(function()
		setPanelOpen(false)
		callAttention()
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

-- Change le texte affiché d'une catégorie sans toucher à sa clé interne.
function UILib:SetCategoryTitle(key, title)
	local cat = self.Categories[key]
	if cat then
		cat.Label.Text = title
	end
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
	local previous = self.Selected
	if previous == tab then
		return
	end

	for _, t in ipairs(self.Tabs) do
		t.Page.Visible = false
		t:_Refresh(self.Theme)
	end
	tab.Page.Visible = true
	tab:_Refresh(self.Theme)
	self.Selected = tab

	-- La nouvelle page arrive du côté d'où l'on vient : descendre dans la
	-- sidebar la fait glisser depuis la droite, remonter depuis la gauche.
	if self.Animations and previous then
		-- Le premier des deux rencontré dans la sidebar indique le sens.
		local goingDown = true
		for _, t in ipairs(self.Tabs) do
			if t == tab then
				goingDown = false
				break
			end
			if t == previous then
				goingDown = true
				break
			end
		end

		tab.Page.Position = UDim2.fromScale(goingDown and 0.05 or -0.05, 0)
		TweenService:Create(
			tab.Page,
			TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0, 0) }
		):Play()

		-- Le repère d'onglet se déplie depuis son centre.
		tab.Marker.Size = UDim2.fromOffset(3, 0)
		TweenService:Create(
			tab.Marker,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(3, 16) }
		):Play()
	end
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

	-- Ancré au centre pour que l'animation le déplie de part et d'autre.
	local marker = new("Frame", {
		Size = UDim2.fromOffset(3, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
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
	-- Passe par _Alpha : sinon l'onglet actif redeviendrait opaque alors que le
	-- reste de l'interface est réglé en transparent.
	self.Button.BackgroundTransparency = active and self.Hub:_Alpha(0) or 1
	self.Label.TextColor3 = active and theme.Accent or theme.SubText
	self.Marker.BackgroundColor3 = theme.Accent
	self.Marker.Visible = active
	if active then
		-- SelectTab rejoue l'animation ; ici on garantit juste la taille finale
		-- quand _Refresh est appelé hors changement d'onglet (thème, etc.).
		self.Marker.Size = UDim2.fromOffset(3, 16)
	end
end

-- Texte affiché de l'onglet dans la sidebar.
function Tab:SetTitle(title)
	self.Label.Text = title
	return self
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

	-- CanvasGroup : l'animation d'entrée estompe chaque carte via une seule
	-- propriété, sans avoir à parcourir tous ses enfants.
	local card = new(surfaceClass(), {
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

	-- Titre de la carte, modifiable après coup (utilisé au changement de langue).
	function self:SetTitle(title)
		headerLabel.Text = title
		return self
	end

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

-- Accepte une liste { "A", "B" } ou un dictionnaire { A = 1, B = 2 }.
-- Renvoie les libellés dans l'ordre d'affichage, et la table de correspondance
-- libellé -> valeur (nil pour une liste, où le libellé est la valeur).
-- Les clés d'un dictionnaire sont triées : pairs ne garantit aucun ordre, donc
-- sans tri la liste changerait d'ordre d'une exécution à l'autre.
local function normalizeOptions(source)
	local keys = {}
	if type(source) ~= "table" then
		return keys, nil
	end

	local count = 0
	for _ in pairs(source) do
		count = count + 1
	end

	if count == #source then
		-- Liste : on conserve l'ordre d'écriture.
		for i, v in ipairs(source) do
			keys[i] = v
		end
		return keys, nil
	end

	local map = {}
	for k, v in pairs(source) do
		table.insert(keys, k)
		map[k] = v
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return keys, map
end

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

	-- opts.Format permet d'afficher autre chose que le nombre brut, par exemple
	-- un pourcentage quand le slider sert d'index sur quelques positions.
	local format = opts.Format

	local function apply(v, fire)
		value = math.clamp(math.floor(v + 0.5), min, max)
		fill.Size = UDim2.fromScale((value - min) / span(), 1)
		label.Text = text .. ": " .. (format and tostring(format(value)) or tostring(value))
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
		if newOpts.Format ~= nil then
			format = newOpts.Format
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

	-- Un champ resté actif capte le clavier : la touche Maj s'écrit dedans au
	-- lieu de déclencher le shift lock. On relâche donc le focus après un délai
	-- sans frappe, remis à zéro à chaque caractère saisi.
	local UNFOCUS_AFTER = opts.UnfocusAfter or 10
	local focusToken = 0

	local function scheduleUnfocus()
		focusToken = focusToken + 1
		local token = focusToken
		task.delay(UNFOCUS_AFTER, function()
			if token == focusToken and box.Parent and box:IsFocused() then
				box:ReleaseFocus()
			end
		end)
	end

	box.Focused:Connect(scheduleUnfocus)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if box:IsFocused() then
			scheduleUnfocus()
		end
	end)

	box.FocusLost:Connect(function(enterPressed)
		-- Invalide le compte à rebours en cours.
		focusToken = focusToken + 1
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
	-- Multi = true : les options se cochent au lieu de se remplacer. La valeur
	-- devient alors une liste, et la liste ne se referme plus à chaque clic.
	local multi = opts.Multi and true or false
	local selected = multi and {} or default
	local rawOptions = options or {}
	local optionKeys = {}
	local optionMap = nil
	local optionViews = {}
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
		Text = text .. ": —",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = FONT,
		TextSize = 13,
		Parent = header,
	})

	local arrow = new("Frame", {
		Size = UDim2.fromOffset(20, 30),
		Position = UDim2.new(1, -26, 0, 0),
		BackgroundTransparency = 1,
		Parent = header,
	})
	local arrowIcon, arrowBars = makeChevron(arrow, 8, 2)

	-- Pas d'AutomaticSize ici : la hauteur est animée à l'ouverture, et
	-- AbsoluteContentSize du layout donne la hauteur naturelle à viser.
	local LIST_PADDING = 8
	local list = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 1,
		Parent = holder,
	})
	corner(list, 6)
	local listLayout = new("UIListLayout", {
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

	local listTween
	local function setListOpen(open)
		if listTween then
			listTween:Cancel()
			listTween = nil
		end

		local target = open and (listLayout.AbsoluteContentSize.Y + LIST_PADDING) or 0

		if not hub.Animations then
			list.Visible = open
			list.Size = UDim2.new(1, 0, 0, target)
			return
		end

		if open then
			list.Visible = true
		end

		listTween = TweenService:Create(list, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, target),
		})
		if not open then
			-- On ne masque qu'une fois repliée, sans quoi la liste disparaîtrait
			-- avant la fin de l'animation.
			listTween.Completed:Connect(function()
				if not expanded then
					list.Visible = false
				end
			end)
		end
		listTween:Play()
	end

	hub:OnTheme(function(theme)
		header.BackgroundColor3 = theme.Element
		headerLabel.TextColor3 = theme.Text
		paintIcon(arrowBars, theme.SubText)
		list.BackgroundColor3 = theme.Element
	end)

	local api = {}

	local function isSelected(option)
		if multi then
			for _, v in ipairs(selected) do
				if v == option then
					return true
				end
			end
			return false
		end
		return selected == option
	end

	-- En multi, on renvoie une copie : le code appelant ne doit pas pouvoir
	-- modifier la sélection interne par accident.
	local function getValue()
		if multi then
			local out = {}
			for i, v in ipairs(selected) do
				out[i] = v
			end
			return out
		end
		return selected
	end

	-- Valeur associée à un libellé. Pour une liste, le libellé est la valeur.
	local function valueFor(key)
		if key == nil then
			return nil
		end
		if optionMap then
			return optionMap[key]
		end
		return key
	end

	local function getMapped()
		if multi then
			local out = {}
			for i, key in ipairs(selected) do
				out[i] = valueFor(key)
			end
			return out
		end
		return valueFor(selected)
	end

	-- Le callback reçoit toujours le libellé en premier — identique au
	-- comportement d'une liste — et la valeur du dictionnaire en second.
	local function fireCallback()
		callback(getValue(), getMapped())
	end

	local function refreshHeader()
		if multi then
			if #selected == 0 then
				headerLabel.Text = text .. ": —"
			else
				local parts = {}
				for i, v in ipairs(selected) do
					parts[i] = tostring(v)
				end
				headerLabel.Text = text .. ": " .. table.concat(parts, ", ")
			end
		else
			headerLabel.Text = text .. ": " .. tostring(selected or "—")
		end
	end

	local function refreshChecks()
		for _, view in ipairs(optionViews) do
			if view.Check then
				local on = isSelected(view.Option)
				view.Check.BackgroundColor3 = on and hub.Theme.Accent or hub.Theme.ElementHover
				view.Mark.Visible = on
			end
		end
	end

	local function refreshOptionStyles()
		local theme = hub.Theme
		for _, view in ipairs(optionViews) do
			if view.Label then
				view.Label.TextColor3 = theme.Text
			else
				view.Button.TextColor3 = theme.Text
			end
			if view.MarkBars then
				paintIcon(view.MarkBars, theme.AccentText)
			end
		end
	end

	-- Un seul écouteur de thème pour toutes les options : SetOptions peut être
	-- rappelé souvent, et en enregistrer un par ligne les accumulerait sans fin.
	hub:OnTheme(function()
		refreshOptionStyles()
		refreshChecks()
	end)

	local function select(value, fire)
		if multi then
			local out = {}
			if type(value) == "table" then
				for _, v in ipairs(value) do
					table.insert(out, v)
				end
			elseif value ~= nil then
				table.insert(out, value)
			end
			selected = out
		else
			selected = value
		end
		refreshHeader()
		refreshChecks()
		if fire then
			fireCallback()
		end
	end

	local function toggleOption(option)
		local index
		for i, v in ipairs(selected) do
			if v == option then
				index = i
				break
			end
		end
		if index then
			table.remove(selected, index)
		else
			table.insert(selected, option)
		end
		refreshHeader()
		refreshChecks()
		fireCallback()
	end

	function api:SetOptions(newOptions)
		rawOptions = newOptions or {}
		optionKeys, optionMap = normalizeOptions(rawOptions)
		optionViews = {}

		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for i, option in ipairs(optionKeys) do
			local optBtn = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
				Text = multi and "" or tostring(option),
				Font = FONT,
				TextSize = 12,
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				LayoutOrder = i,
				Parent = list,
			})
			corner(optBtn, 4)

			local view = { Option = option, Button = optBtn }

			if multi then
				-- Case à cocher à gauche, libellé aligné à sa droite.
				local box = new("Frame", {
					Size = UDim2.fromOffset(14, 14),
					Position = UDim2.new(0, 6, 0.5, -7),
					BorderSizePixel = 0,
					Parent = optBtn,
				})
				corner(box, 4)

				local mark, markBars = makeCheck(box, 14, 2)
				mark.Visible = false

				local optLabel = new("TextLabel", {
					Size = UDim2.new(1, -30, 1, 0),
					Position = UDim2.fromOffset(26, 0),
					BackgroundTransparency = 1,
					Text = tostring(option),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Font = FONT,
					TextSize = 12,
					Parent = optBtn,
				})

				view.Check = box
				view.Mark = mark
				view.MarkBars = markBars
				view.Label = optLabel
			end

			optBtn.MouseEnter:Connect(function()
				optBtn.BackgroundTransparency = hub:_Alpha(0)
				optBtn.BackgroundColor3 = hub.Theme.ElementHover
			end)
			optBtn.MouseLeave:Connect(function()
				optBtn.BackgroundTransparency = 1
			end)
			optBtn.MouseButton1Click:Connect(function()
				if multi then
					-- La liste reste ouverte : on coche souvent plusieurs options
					-- d'affilée.
					toggleOption(option)
				else
					select(option, true)
					expanded = false
					setListOpen(false)
					TweenService:Create(arrowIcon, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 0,
					}):Play()
				end
			end)

			table.insert(optionViews, view)
		end

		refreshOptionStyles()

		-- La liste a changé de contenu : si elle est déployée, sa hauteur doit
		-- être recalculée sur les nouvelles options.
		if expanded then
			setListOpen(true)
		end

		if multi then
			-- On retire les sélections absentes de la nouvelle liste, sans rien
			-- cocher d'office.
			local kept = {}
			for _, v in ipairs(selected) do
				for _, option in ipairs(optionKeys) do
					if option == v then
						table.insert(kept, v)
						break
					end
				end
			end
			selected = kept
			refreshHeader()
			refreshChecks()
		else
			-- La sélection courante peut avoir disparu de la nouvelle liste.
			local stillThere = false
			for _, option in ipairs(optionKeys) do
				if option == selected then
					stillThere = true
					break
				end
			end
			if not stillThere then
				select(optionKeys[1], false)
			end
		end
	end

	function api:Set(value)
		select(value, true)
	end

	function api:Get()
		return getValue()
	end

	-- Valeur du dictionnaire correspondant à la sélection. Sur une liste
	-- classique, renvoie la même chose que Get().
	function api:GetValue()
		return getMapped()
	end

	-- Pratique en multi : savoir si une option précise est cochée.
	function api:IsSelected(option)
		return isSelected(option)
	end

	header.MouseButton1Click:Connect(function()
		expanded = not expanded
		setListOpen(expanded)
		-- Le chevron pointe vers le bas ; on le retourne quand la liste s'ouvre.
		TweenService:Create(arrowIcon, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = expanded and 180 or 0,
		}):Play()
	end)

	api:SetOptions(options or {})
	if default then
		select(default, false)
	end

	local saved = opts.Save and true or false
	local function register()
		hub:_Register(flag, getValue, function(v)
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
		-- Basculer entre choix unique et multiple change la forme de la valeur,
		-- donc on repart d'une sélection vide et on reconstruit les lignes.
		if newOpts.Multi ~= nil and (newOpts.Multi and true or false) ~= multi then
			multi = newOpts.Multi and true or false
			selected = multi and {} or nil
			api:SetOptions(newOptions or rawOptions)
		elseif newOptions ~= nil then
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
			select(getValue(), false)
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
			BackgroundColor3 = THEMES[name].Swatch or THEMES[name].Accent,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		corner(swatch, 15)
		-- La pastille RGB montre le dégradé lui-même, pas une couleur unie.
		if THEMES[name].Rainbow then
			new("UIGradient", { Color = RAINBOW, Rotation = 45, Parent = swatch })
		end
		-- Contour permanent : sans lui, la pastille noire disparaîtrait sur un
		-- thème sombre et la blanche sur un thème clair.
		strokes[name] = stroke(swatch, nil, 1)
		swatch.MouseButton1Click:Connect(function()
			hub:SetTheme(name)
		end)
	end

	hub:OnTheme(function(theme)
		for name, s in pairs(strokes) do
			local active = name == hub.ThemeName
			s.Thickness = active and 2 or 1
			s.Color = active and theme.Text or theme.SubText
		end
	end)

	return row
end

--------------------------------------------------------------
-- Onglet « UI Settings » généré automatiquement
--------------------------------------------------------------

function UILib:_BuildSettingsTab()
	local tab = self:AddTab(self:T("SettingsTab"), "Settings", true)

	local cfgSection = tab:AddSection(self:T("Configurations"), { Column = 1 })
	self._configDropdown = cfgSection:AddDropdown(self:T("ConfigDropdown"), self:ListConfigs(), nil, function() end)

	local loadBtn = cfgSection:AddButton(self:T("LoadConfig"), function()
		local name = self._configDropdown:Get()
		if name then
			self:LoadConfig(name)
		end
	end)

	local deleteBtn = cfgSection:AddButton(self:T("DeleteConfig"), function()
		local name = self._configDropdown:Get()
		if name then
			self:DeleteConfig(name)
		end
	end)

	local nameBox = cfgSection:AddTextbox(self:T("NewConfigName"), function() end)
	local saveBtn = cfgSection:AddButton(self:T("Save"), function()
		local name = nameBox:Get()
		if name and name ~= "" then
			self:SaveConfig(name)
			nameBox:Set("")
		end
	end)

	local store = self:_Store()
	local autoLoadToggle = cfgSection:AddToggle(self:T("AutoLoad"), store.AutoLoad or false, function(on)
		self:SetAutoLoad(on)
	end, { Flag = "__autoload" })

	local storageNote
	if not Storage.IsPersistent() then
		storageNote = cfgSection:AddNote(self:T("StorageNote"))
	end

	local themeSection = tab:AddSection(self:T("Appearance"), { Column = 2 })
	local themeLabel = themeSection:AddLabel(self:T("ThemeLabel"))
	themeSection:AddThemePicker()

	-- Slider d'index : des crans francs de 5 % plutôt qu'un réglage continu,
	-- pour qu'on retombe toujours sur le même rendu.
	local STEPS = {}
	for percent = 0, 60, 5 do
		table.insert(STEPS, percent / 100)
	end
	local function formatTransparency(index)
		return math.floor((STEPS[index] or 0) * 100 + 0.5) .. " %"
	end
	local transparencySlider = themeSection:AddSlider(self:T("Transparency"), 1, #STEPS, 1, function(index)
		self:SetTransparency(STEPS[index] or 0)
	end, {
		Flag = "__transparency",
		Format = formatTransparency,
	})

	-- Dictionnaire : le libellé s'affiche, le code de langue part au callback.
	local languageDropdown = themeSection:AddDropdown(self:T("Language"), LANGUAGE_CHOICES, nil, function(_, code)
		self:SetLanguage(code)
	end, { Flag = "__language", Save = true })
	for label, code in pairs(LANGUAGE_CHOICES) do
		if code == self.Language then
			languageDropdown:Set(label)
		end
	end

	local appearanceNote = themeSection:AddNote(self:T("AppearanceNote"))

	local scriptSection = tab:AddSection(self:T("Script"), { Column = 2 })
	scriptSection:AddLabel("UILib v" .. UILib.Version)
	local unloadBtn = scriptSection:AddButton(self:T("Unload"), function()
		self:Unload()
	end)
	local unloadNote = scriptSection:AddNote(self:T("UnloadNote"))

	-- Un seul point de retraduction : tout ce que la librairie affiche est
	-- réécrit ici quand la langue change.
	self:OnLanguage(function()
		self:SetCategoryTitle("Settings", self:T("SettingsCategory"))
		tab:SetTitle(self:T("SettingsTab"))

		cfgSection:SetTitle(self:T("Configurations"))
		self._configDropdown:UpdateDropdown(self:T("ConfigDropdown"))
		loadBtn:UpdateButton(self:T("LoadConfig"))
		deleteBtn:UpdateButton(self:T("DeleteConfig"))
		nameBox:UpdateTextbox(self:T("NewConfigName"))
		saveBtn:UpdateButton(self:T("Save"))
		autoLoadToggle:UpdateToggle(self:T("AutoLoad"))
		if storageNote then
			storageNote:UpdateNote(self:T("StorageNote"))
		end

		themeSection:SetTitle(self:T("Appearance"))
		themeLabel:UpdateLabel(self:T("ThemeLabel"))
		transparencySlider:UpdateSlider(self:T("Transparency"))
		appearanceNote:UpdateNote(self:T("AppearanceNote"))

		-- La sélection affichée doit suivre la langue courante, sinon un appel
		-- direct à SetLanguage laisse le menu sur l'ancien libellé.
		local currentLabel
		for label, code in pairs(LANGUAGE_CHOICES) do
			if code == self.Language then
				currentLabel = label
				break
			end
		end
		languageDropdown:UpdateDropdown(self:T("Language"), nil, currentLabel)

		scriptSection:SetTitle(self:T("Script"))
		unloadBtn:UpdateButton(self:T("Unload"))
		unloadNote:UpdateNote(self:T("UnloadNote"))
	end)

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
