# MiniTabTarget - bot reference

Version 1.4.3. Interface versions: 120100, 120007, 50504, 40402, 38002,
38000, 30405, 30300, 20506, 11509 (retail plus the classic client lines).
Saved variables: MiniTabTargetDB (account-wide).

## What it does

Automatically swaps what your tab-target keys do based on where you are:

- In battlegrounds and arenas: keys bind to Target Nearest Enemy Player and
  Target Previous Enemy Player (players only, ignores pets and NPCs).
- Everywhere else: keys bind to Target Nearest Enemy and Target Previous
  Enemy.

Bindings are re-applied on every zone change and on login/reload.

## Which keys it uses

- Defaults: TAB for target, SHIFT-TAB for previous target.
- Auto-detection: as long as you have not overridden the saved variables,
  the addon reads your actual keybindings for the target-enemy actions and
  uses those keys instead of assuming TAB.
- Manual override (no UI for this; run in chat):
  - /run MiniTabTargetDB.TargetKey = "SOMEKEY"
  - /run MiniTabTargetDB.TargetPreviousKey = "SHIFT-SOMEKEY"
  Once either value differs from the defaults, auto-detection is skipped and
  the stored keys are used as-is.

## Settings panel

The panel (Options -> AddOns -> MiniTabTarget) is informational only: it
describes how the addon works and has no controls.

## Slash commands

/mtt, /minitt, /minitabtarget - all open the info panel.

## Version-gated / conditional behaviour

- Binding changes are skipped while in combat lockdown; they apply on the
  next zone change or world load out of combat.
- "PvP mode" means instance type "pvp" (battleground) or "arena". World PvP,
  war mode, and duels count as PvE for this addon; tab still targets any
  enemy there.

## Troubleshooting

- "Tab still targets pets in a battleground": make sure you actually zoned
  in (bindings apply on zone change), and that you were not in combat when
  entering; they will re-apply after combat on the next zone event. Also
  verify the addon is using the right key: if you rebound tab-targeting to
  another key, the addon should auto-detect it, but a stale manual override
  in MiniTabTargetDB will win. Reset by setting the values back to "TAB" and
  "SHIFT-TAB" or deleting the saved variables.
- "It changed my keybindings": that is its purpose; it rebinds the two
  target-enemy keys per zone type. Remove the addon and rebind your keys in
  the Blizzard keybindings menu to undo.
