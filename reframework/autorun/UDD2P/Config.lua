local config = {}

-- Vanilla bug fixes
config.ARCHER_DAMAGE_FIX = true -- Fix archer dealing less damage than intended to some bosses
config.THIEF_FIX = true -- Fix thief dash attack missing if used repeatedly
config.GOBLIN_TORCH_FIX = true -- Fix goblin torches hitting several times 
config.MINOTAUR_FIX = true -- Prevents minotaur one shot during charge
config.CHIMERA_STAGGER_FIX = true -- Prevents ridiculous stagger mult during chimera lunge attacks
config.LEVIN_SOUND_FIX = true -- Fix some levin sounds not playing
config.SCALY_INVADERS_FIX = true -- Prevents scaly invaders from breaking when Fyoran or Jonas die (by making them unkillable)
config.NIGHT_EVENT_FIX = true -- Allows Vernworth's night event to happen after you're level 15
config.OGRE_SLIDE_FIX = true -- Prevents idle ogres from sliding and properly plays their crouch animation
config.FIGHTER_IFRAMES_FIX = true -- Fighter will no longer be affected by debilitations during deflect iframes
config.PURPLE_HOBGOBLIN_FIX = true -- Purple hobgoblin shells will no longer deal party wiping damage
config.ETERNAL_WOKESTONE_FIX = true -- You can no longer dupe eternal wakestones by forging them

-- Modded bug fixes
config.NPC_HIT_FIX = false -- Global fix for player owned shells hurting friendly NPCs in combat. Off by default because it's performance intensive
config.SPHINX_AND_MEDUSA_FIX = true -- Fix Medusa's AI when spawned outside of her arena and Sphinx's mechanics when fought outside of her quest

-- Small gameplay tweaks
config.NPC_FREAK_TWEAK = true -- NPCs won't freak out when you draw your weapons near them
config.REMOVE_DAMAGE_SCALING = true -- Remove damage scaling with body size
config.SLIDING_ANGLE = 48 -- Angle needed to start sliding. Vanilla is 38
config.PAWNS_SURVIVE_BRINE = true -- Pawns will survive being thrown into the brine just like the player
config.BRINE_HEALS_PLAGUE = false -- Pawns will be healed of dragonsplague when thrown in the brine. Has no effect if PAWNS_SURVIVE_BRINE is false
config.BATTAHLI_GUARDS_TWEAK = true -- Battahli guards will actually kick you out if you don't have a residence permit
config.FALL_DAMAGE_SETTING = 1 -- 0 is vanilla, 1 is lenient, 2 is super lenient

-- Quality of life tweaks
config.TUTORIAL_RUN = true -- You can run during the tutorial
config.FASTER_DIALOGUE_SKIP = true -- Pressing the "next" button actually skips dialogue
config.NO_DISTANCE_PAWN_RESTRICTIONS = true -- No longer need to be close to pawns to trade items with them
config.NO_STAMINA_COST = true -- Remove dashing stamina cost out of combat

-- Misc or cosmetic tweaks
config.NIGHTREIGN = true -- Add rain to some nights
config.MAGIC_WEAKSPOTS = true -- Weakspot sounds for magic attacks
config.STRAY_PAWNS = true -- Stray pawns will no longer approach you
config.HIDE_WYRMFIRE = true -- Hide ugly wyrmfire effect on maxed gear
config.NO_UNSHEATHE = true -- Skips unsheathe animation and does the attack/skill directly

return config