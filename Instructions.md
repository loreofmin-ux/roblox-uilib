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
    Width = 940,           -- optionnel (défaut 940)
    Height = 580,          -- optionnel (défaut 580)
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

Le panneau fait 940×580 par défaut, et sa taille est bornée à celle de l'écran :
sur une petite résolution il se réduit automatiquement au lieu de déborder.
`Width` et `Height` permettent de l'ajuster.

## Éléments disponibles

- `AddButton(texte, callback, opts)`
- `AddToggle(texte, défaut, callback, opts)`
- `AddSlider(texte, min, max, défaut, callback, opts)`
- `AddTextbox(placeholder, callback, opts)`
- `AddDropdown(texte, options, défaut, callback, opts)`
- `AddLabel(texte, opts)` / `AddNote(texte, opts)`
- `AddThemePicker()`

`opts` accepte `Visible`, `Order`, `Flag` (clé de sauvegarde) et `Save`.
`AddDropdown` accepte en plus `Multi`.

### Dropdown à choix multiple

Avec `Multi = true`, les options se cochent au lieu de se remplacer, et la liste
reste ouverte pour en cocher plusieurs d'affilée.

```lua
local cibles = section:AddDropdown("Cibles",
    { "Joueurs", "Véhicules", "Caisses" },
    { "Joueurs" },              -- valeur par défaut : une liste
    function(choix)
        -- choix est une table : { "Joueurs", "Caisses" }
        print(table.concat(choix, ", "))
    end,
    { Multi = true, Save = true })

cibles:Get()                    -- { "Joueurs", "Caisses" }
cibles:Set({ "Véhicules" })     -- remplace toute la sélection
cibles:IsSelected("Caisses")    -- true / false
```

En mode `Multi`, la valeur est **toujours une table**, y compris quand rien n'est
coché (table vide). `Get()` renvoie une copie : la modifier ne touche pas à la
sélection interne. Si `SetOptions` retire une option qui était cochée, elle
disparaît simplement de la sélection, sans qu'une autre soit cochée à sa place.

## Modifier un élément après coup

Chaque `Add*` renvoie une poignée dotée d'un `Update<Type>` reprenant les mêmes
paramètres. **Tout argument laissé à `nil` conserve sa valeur actuelle**, ce qui
permet de ne changer qu'une seule chose à la fois.

```lua
local bouton = section:AddButton("Démarrer", demarrer)

bouton:UpdateButton("Arrêter")             -- texte seul, callback conservé
bouton:UpdateButton(nil, arreter)          -- callback seul, texte conservé
bouton:UpdateButton("Arrêter", arreter)    -- les deux
```

| Méthode | Signature |
| --- | --- |
| `UpdateButton` | `(texte, callback, opts)` |
| `UpdateToggle` | `(texte, valeur, callback, opts)` |
| `UpdateSlider` | `(texte, min, max, valeur, callback, opts)` |
| `UpdateTextbox` | `(placeholder, callback, opts)` |
| `UpdateDropdown` | `(texte, options, valeur, callback, opts)` — `opts.Multi` bascule entre choix unique et multiple |
| `UpdateLabel` | `(texte, opts)` |
| `UpdateNote` | `(texte, opts)` |

Chaque poignée expose aussi `:Remove()` pour retirer l'élément, et `.Instance`
pour accéder à l'objet Roblox brut. Les éléments à valeur (toggle, slider,
textbox, dropdown) gardent `:Set(v)` et `:Get()`.

Renommer un élément ne change pas sa clé de sauvegarde : les configurations déjà
enregistrées restent valides. Pour re-cléer volontairement, passe `opts.Flag`.

## Décharger la librairie

```lua
Hub:OnUnload(function()
    -- arrêter les boucles, remettre en état ce que le module a modifié
end)

Hub:Unload()      -- ferme l'UI et coupe toutes les connexions
section:Unload()  -- même effet depuis une section
tab:Unload()      -- ou depuis un onglet
```

`Unload()` exécute d'abord les callbacks `OnUnload`, puis déconnecte tout ce que
la librairie a branché et détruit le `ScreenGui`. L'appel est idempotent.
`Destroy()` reste disponible comme alias. Un bouton **Décharger le script** est
également présent dans l'onglet **UI Settings**.

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
