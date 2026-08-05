-- LocalScript d'exemple (StarterPlayerScripts).
-- Montre la structure Hub > Onglet (catégorie) > Section (carte en colonnes),
-- et comment plusieurs "modules" ajoutent chacun leurs onglets au même hub.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UILib = require(ReplicatedStorage:WaitForChild("UILib"))

local Hub = UILib.new({
	Title = "Mon Hub",
	Subtitle = "Mon Jeu | v1.0.0",
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

--==============================================================
-- À appeler en DERNIER : recharge la config précédente si "Charger au
-- démarrage" est activé dans l'onglet UI Settings.
--==============================================================

Hub:AutoLoad()
