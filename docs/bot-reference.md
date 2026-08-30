# MiniTabTarget - bot reference

Version 1.5.0. Interface versions: 120100, 50504, 40402, 38002, 38000,
30405, 30300, 20506, 11509 (retail plus the classic client lines).
Saved variables: MiniTabTargetDB (account-wide).

## What it does

Automatically swaps what your tab-target keys do based on where you are:

- In a battleground or arena bracket that is enabled in the settings panel:
  keys bind to Target Nearest Enemy Player and Target Previous Enemy
  Player (players only, ignores pets and NPCs).
- Everywhere else, and in a bracket that is turned off: keys bind to
  Target Nearest Enemy and Target Previous Enemy.

Bindings are re-applied on every zone change, on UPDATE_BATTLEFIELD_STATUS
(the match type can settle just after the zone change), and on
login/reload. A change made in the settings panel applies immediately out
of combat, and waits for combat to end otherwise, same as every other
binding change.

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

The panel (Options -> AddOns -> MiniTabTarget) has three checkboxes under
"Where it applies", one per PvP bracket, all on by default:

- Arena: rated arena and skirmish.
- Solo Shuffle: rated solo shuffle.
- Battleground: rated/unrated/epic battlegrounds, brawls, and Blitz.

Turning a bracket off makes tab behave there the way it does outside any
PvP instance; it does not stop the addon from touching your bindings.

## Saved variables

- TargetKey, TargetPreviousKey: the keys the addon rebinds. See "Which
  keys it uses" above.
- Arena, SoloShuffle, Battleground: one boolean per bracket, all true by
  default. See "Settings panel" above for what each one covers.
- RatedBattleground: retired. A saved variables table still carrying it is
  folded into Battleground once at load, on if either was on, and the key
  is then removed.

## Slash commands

/mtt, /minitt, /minitabtarget - all open the settings panel.

## Version-gated / conditional behaviour

- Binding changes made in combat lockdown wait for combat to end, then
  apply immediately; they no longer need a zone change or world load.
- "PvP mode" means instance type "pvp" (battleground) or "arena". World PvP,
  war mode, and duels count as PvE for this addon; tab still targets any
  enemy there.
- The bracket split comes from C_PvP, which the classic clients are
  missing or thin on, so solo shuffle falls under Arena there. Every
  battleground follows the one Battleground toggle on every client.

## Troubleshooting

- "Tab still targets pets in a battleground": first check that bracket's
  toggle is on in the settings panel. Also make sure you actually zoned
  in (bindings apply on zone change), and that you were not in combat when
  entering; they will re-apply as soon as combat ends. Also verify the
  addon is using the right key: if you rebound tab-targeting to another
  key, the addon should auto-detect it, but a stale manual override in
  MiniTabTargetDB will win. Reset by setting the values back to "TAB" and
  "SHIFT-TAB" or deleting the saved variables.
- "It changed my keybindings": that is its purpose; it rebinds the two
  target-enemy keys per zone type. Remove the addon and rebind your keys in
  the Blizzard keybindings menu to undo.
