-- LocalScript d'exemple (StarterPlayerScripts).
-- Montre la structure Hub > Onglet (catégorie) > Section (carte en colonnes),
-- et comment plusieurs "modules" ajoutent chacun leurs onglets au même hub.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UILib = require(ReplicatedStorage:WaitForChild("UILib"))

local Hub = UILib.new({
	Title = "Mon Hub",
	-- Subtitle t'appartient : c'est le nom de ton jeu et TA version de script,
	-- pas celle de la librairie (lisible dans UILib.Version). Sans valeur ici,
	-- la version de UILib s'affiche à la place.
	Subtitle = "Mon Jeu v1.0.0 · UILib v" .. UILib.Version,
	Theme = "Green", -- "Dark" | "Light" | "Blue" | "Green" | "Yellow"
	ConfigFile = "MonHub", -- fichier où sont stockées les configs
})

local function humanoid()
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

--==============================================================
-- Onglet Main (catégorie "Game")
--==============================================================

local main = Hub:AddTab("Main", "Game")

-- Colonne 1 : une section avec son propre interrupteur maître dans l'en-tête
local autoFarm = main:AddSection("Auto Farm", {
	Column = 1,
	Toggle = true,
	Default = false,
	Callback = function(on)
		print("Auto Farm:", on)
	end,
})
autoFarm:AddButton("Select Everything", function()
	print("tout sélectionné")
end)
autoFarm:AddButton("Select Nothing", function()
	print("rien sélectionné")
end)
autoFarm:AddToggle("Auto Cook Food", false, function(on)
	print("Auto Cook Food:", on)
end)
autoFarm:AddToggle("Auto Take Orders", false, function(on)
	print("Auto Take Orders:", on)
end)
autoFarm:AddToggle("Auto Collect Tips", false, function(on)
	print("Auto Collect Tips:", on)
end)
autoFarm:AddNote("Note: certaines actions peuvent être lentes selon le jeu.")

-- Colonne 2
local restaurant = main:AddSection("Restaurant", {
	Column = 2,
	Toggle = true,
	Default = true,
	Callback = function(on)
		print("Restaurant:", on)
	end,
})
restaurant:AddButton("Close Restaurant", function() end)
restaurant:AddButton("Open Restaurant", function() end)
restaurant:AddButton("Kick All Customers", function() end)

local nameBox = restaurant:AddTextbox("New restaurant name...", function(text)
	print("nouveau nom:", text)
end)
restaurant:AddButton("Change Restaurant Name", function()
	print("renommé en:", nameBox:Get())
end)

local rewards = main:AddSection("Rewards", { Column = 2, Toggle = true })
rewards:AddToggle("Auto Claim Daily Reward", false, function() end)
rewards:AddToggle("Auto Collect Objectives", false, function() end)

--==============================================================
-- Onglet Local Player (catégorie "Game")
--==============================================================

local localPlayer = Hub:AddTab("Local Player", "Game")

local movement = localPlayer:AddSection("Déplacement", { Column = 1 })
movement:AddSlider("WalkSpeed", 16, 200, 16, function(value)
	local h = humanoid()
	if h then
		h.WalkSpeed = value
	end
end)
movement:AddSlider("JumpPower", 50, 300, 50, function(value)
	local h = humanoid()
	if h then
		h.UseJumpPower = true
		h.JumpPower = value
	end
end)

local misc = localPlayer:AddSection("Divers", { Column = 2 })
misc:AddToggle("Noclip", false, function(on)
	print("Noclip:", on)
end)
misc:AddButton("Reset personnage", function()
	local h = humanoid()
	if h then
		h.Health = 0
	end
end)

--==============================================================
-- Un autre "module" peut ajouter son onglet au même hub
--==============================================================

local visuals = Hub:AddTab("Visuals", "Game")
local esp = visuals:AddSection("ESP", { Column = 1, Toggle = true })
esp:AddToggle("Joueurs", false, function() end)
esp:AddToggle("Objets", false, function() end)
esp:AddDropdown("Couleur", { "Rouge", "Vert", "Bleu" }, "Rouge", function(choice)
	print("couleur ESP:", choice)
end, { Save = true })

-- Multi = true : les options se cochent, la valeur devient une table.
local cibles = esp:AddDropdown("Cibles",
	{ "Joueurs", "Véhicules", "Caisses", "Bâtiments" },
	{ "Joueurs" },
	function(choix)
		print("cibles ESP:", table.concat(choix, ", "))
	end,
	{ Multi = true, Save = true })

esp:AddButton("Afficher les cibles cochées", function()
	local choix = cibles:Get()
	if #choix == 0 then
		print("aucune cible")
	else
		print(table.concat(choix, ", "))
	end
end)

-- Dictionnaire : les clés s'affichent, la valeur arrive en second argument.
local tp = visuals:AddSection("Téléportation", { Column = 2 })
tp:AddDropdown("Destination", {
	Spawn = Vector3.new(0, 5, 0),
	Boss = Vector3.new(100, 5, 200),
	Base = Vector3.new(-40, 12, 75),
}, "Spawn", function(nom, position)
	local char = Players.LocalPlayer.Character
	if char then
		char:PivotTo(CFrame.new(position))
	end
	print("téléporté vers", nom)
end, { Save = true })

--==============================================================
-- Modifier un élément après sa création
--
-- Chaque Add* renvoie une poignée avec un Update<Type> qui reprend les mêmes
-- paramètres. Tout argument laissé à nil garde sa valeur actuelle.
--==============================================================

local demo = Hub:AddTab("Demo", "Game")
local live = demo:AddSection("Mise à jour en direct", { Column = 1 })

local compteur = 0
local etiquette = live:AddLabel("Cliqué 0 fois")
local bouton

bouton = live:AddButton("Clique-moi", function()
	compteur = compteur + 1
	etiquette:UpdateLabel("Cliqué " .. compteur .. " fois")

	if compteur == 3 then
		-- On change le texte ET le comportement du bouton d'un coup.
		bouton:UpdateButton("Remettre à zéro", function()
			compteur = 0
			etiquette:UpdateLabel("Cliqué 0 fois")
			bouton:UpdateButton("Clique-moi")
		end)
	end
end)

local vitesse = live:AddSlider("Vitesse", 0, 100, 50, function(v)
	print("vitesse:", v)
end)

live:AddButton("Élargir la plage du slider", function()
	-- On ne touche qu'aux bornes : libellé, valeur et callback sont conservés.
	vitesse:UpdateSlider(nil, 0, 500)
end)

--==============================================================
-- Déchargement
--
-- OnUnload permet à chaque module d'arrêter ses boucles et de remettre en
-- état ce qu'il a modifié. L'onglet UI Settings contient déjà un bouton
-- "Décharger le script" ; Hub:Unload() fait la même chose depuis le code.
--==============================================================

Hub:OnUnload(function()
	local h = humanoid()
	if h then
		h.WalkSpeed = 16
	end
	print("script déchargé")
end)

--==============================================================
-- À appeler en DERNIER : recharge la config précédente si "Charger au
-- démarrage" est activé dans l'onglet UI Settings.
--==============================================================

Hub:AutoLoad()
