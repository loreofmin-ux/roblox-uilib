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
    Language = "fr",       -- "fr" | "en" (défaut "fr")
    ConfigFile = "MonHub", -- fichier de sauvegarde des configs
    Width = 940,           -- optionnel (défaut 940)
    Height = 580,          -- optionnel (défaut 580)
    Animations = true,     -- optionnel, false pour tout désactiver
})
```

`Subtitle` t'appartient : c'est le nom de ton jeu et **ta** version de script.
La librairie n'y touche pas. Si tu l'omets, la version de UILib s'affiche à la
place. Pour montrer les deux :

```lua
Subtitle = "Mon Jeu v1.0.0 · UILib v" .. UILib.Version
```

La version de la librairie est lisible dans `UILib.Version`, et affichée dans
l'onglet **Réglages → Interface**.

## Langue

Les textes produits par la librairie sont traduits en français et en anglais.
Les libellés que tu écris toi-même ne sont jamais touchés.

```lua
Hub:SetLanguage("en")   -- bascule à chaud, tout se retraduit
Hub:T("Save")           -- accès direct à une chaîne traduite

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

### Dropdown avec dictionnaire

`AddDropdown` accepte une liste ou un dictionnaire. Avec un dictionnaire, les
**clés servent de libellés** et la **valeur associée est passée en second
argument** du callback :

```lua
local destinations = {
    Spawn = Vector3.new(0, 5, 0),
    Boss  = Vector3.new(100, 5, 200),
}

section:AddDropdown("Destination", destinations, "Spawn", function(cle, valeur)
    -- cle = "Boss", valeur = Vector3.new(100, 5, 200)
    character:PivotTo(CFrame.new(valeur))
end, { Save = true })
```

| Appel | Renvoie |
| --- | --- |
| `:Get()` | la **clé** (`"Boss"`) |
| `:GetValue()` | la **valeur** (`Vector3`) |
| `:Set("Boss")` | se règle par la clé |

Le premier argument du callback est toujours le libellé, exactement comme avec
une liste : le code écrit pour une liste continue donc de fonctionner tel quel.
Sur une liste, `GetValue()` renvoie la même chose que `Get()`.

Deux points à connaître :

- **Les clés d'un dictionnaire sont triées par ordre alphabétique.** En Lua,
  `pairs` ne garantit aucun ordre : sans tri, la liste changerait d'ordre d'une
  exécution à l'autre. Si tu as besoin d'un ordre précis, utilise une liste.
- **C'est la clé qui est enregistrée dans les configurations**, pas la valeur.
  Une valeur comme un `Vector3` ou une fonction ne serait pas sérialisable.

Dictionnaire et `Multi` se combinent : le callback reçoit alors une table de
clés et une table de valeurs.

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
Changeables via `Hub:SetTheme(nom)` ou depuis l'onglet **Réglages → Interface**.

## Transparence

Un curseur à crans de 5 % (de 0 à 60 %) règle la transparence globale.

```lua
Hub:SetTransparency(0.3)   -- 0 = opaque, 1 = invisible
```

Seuls les **fonds** s'estompent : le texte reste opaque, sinon l'interface
devient illisible dans les crans élevés.

## Icônes

Les icônes (menu, croix, chevron, coche) sont **dessinées avec des `Frame`**,
pas écrites avec des caractères Unicode : la police Gotham de Roblox ne contient
pas `☰ ✕ ▾ ✓` et les remplacerait par des carrés vides.

## Animations

- **Ouverture du panneau** : fondu de 0,18 s. Repose sur un `CanvasGroup`, qui
  estompe le panneau et tout son contenu d'un bloc. Sur un client trop ancien
  pour cette classe, le panneau apparaît sans fondu.
- **Changement d'onglet** : la page glisse depuis la droite en descendant dans
  la sidebar, depuis la gauche en remontant (0,16 s). Le repère d'onglet se
  déplie.
- **Dropdowns** : la liste se déplie en hauteur, le chevron pivote.
- **Fermeture par la croix** : le rond flottant émet des ondes et affiche une
  bulle d'aide, pour signaler que c'est lui qui rouvre le panneau.

`Animations = false` à la création désactive l'ensemble.

## Historique des versions

| Version | Changement |
| --- | --- |
| 2.4.0 | Fondu à l'ouverture, dropdowns animés, transparence par pas de 5 % |
| 2.3.0 | Icônes dessinées, transparence globale, animations, langue FR/EN |
| 2.2.0 | Dropdowns acceptant les dictionnaires |
| 2.1.0 | Dropdowns à choix multiple |
| 2.0.1 | Panneau agrandi à 940×580 |
| 2.0.0 | Méthodes `Update*`, `Unload` — `AddButton`/`AddNote` renvoient une table |
| 1.0.1 | Correction du glisser qui décrochait |
| 1.0.0 | Version initiale |

## Configurations

Un onglet **UI Settings** est généré automatiquement : il permet d'enregistrer,
recharger et supprimer des configurations, et de les rappeler au démarrage.

Les toggles, sliders et dropdowns sont enregistrés automatiquement. API :
`Hub:SaveConfig(nom)`, `Hub:LoadConfig(nom)`, `Hub:DeleteConfig(nom)`,
`Hub:ListConfigs()`.

La persistance passe par `writefile`/`readfile` quand ces fonctions existent.
Dans Roblox Studio elles ne sont pas disponibles : les configurations restent
alors en mémoire pour la session, et l'interface le signale.
