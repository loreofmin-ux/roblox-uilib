# UILib

Petite librairie d'interface flottante pour Roblox : une icône déplaçable qui ouvre
un panneau, dans lequel n'importe quel script peut greffer ses propres onglets et
sections — comme un hub modulaire.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `UILib.lua` | La librairie (ModuleScript) |
| `Example_LoaderScript.client.lua` | Exemple d'utilisation (LocalScript) |

## Installation

1. Place `UILib.lua` dans `ReplicatedStorage` en tant que **ModuleScript**.
2. Place `Example_LoaderScript.client.lua` dans `StarterPlayer > StarterPlayerScripts`
   en tant que **LocalScript**.

## Utilisation

```lua
local UILib = require(game.ReplicatedStorage.UILib)

local Hub = UILib.new({
    Title = "Mon Hub",
    Subtitle = "Mon Jeu | v1.0.0",
    Theme = "Green",       -- Dark | Light | Blue | Green | Yellow
    ConfigFile = "MonHub", -- fichier de sauvegarde des configs
})

local main = Hub:AddTab("Main", "Game")

local farm = main:AddSection("Auto Farm", {
    Column = 1,
    Toggle = true,
    Callback = function(on) print("Auto Farm:", on) end,
})

farm:AddButton("Select Everything", function() end)
farm:AddToggle("Auto Cook Food", false, function(on) end)
farm:AddSlider("WalkSpeed", 16, 200, 16, function(v) end)
farm:AddNote("Note: dépend du jeu.")

Hub:AutoLoad() -- à appeler en dernier
```

## Structure

`Hub` → `Onglet` (rangé par catégorie dans la sidebar) → `Section` (carte).
Les sections se répartissent sur deux colonnes plutôt qu'une longue liste à scroller.

## Éléments disponibles

- `AddButton(texte, callback)`
- `AddToggle(texte, défaut, callback)`
- `AddSlider(texte, min, max, défaut, callback)`
- `AddTextbox(placeholder, callback)`
- `AddDropdown(texte, options, défaut, callback)`
- `AddLabel(texte)` / `AddNote(texte)`
- `AddThemePicker()`

## Thèmes

Cinq thèmes intégrés : `Dark`, `Light`, `Blue`, `Green`, `Yellow`.
Changeables via `Hub:SetTheme(nom)` ou depuis l'onglet **UI Settings**.

## Configurations

Un onglet **UI Settings** est généré automatiquement : il permet d'enregistrer,
recharger et supprimer des configurations, et de les rappeler au démarrage.

Les toggles, sliders et dropdowns sont enregistrés automatiquement. API :
`Hub:SaveConfig(nom)`, `Hub:LoadConfig(nom)`, `Hub:DeleteConfig(nom)`,
`Hub:ListConfigs()`.

La persistance passe par `writefile`/`readfile` quand ces fonctions existent.
Dans Roblox Studio elles ne sont pas disponibles : les configurations restent
alors en mémoire pour la session, et l'interface le signale.
