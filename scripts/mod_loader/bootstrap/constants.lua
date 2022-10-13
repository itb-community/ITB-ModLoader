-- this file contains relevant constants that are repeated thoughout the codebase, so that if the game updates we do not have to find all copies
modApi.constants = {
  -- maximum number of pilots available in the hangar GUI
  MAX_PILOTS = 19,

  -- maximum number of squads on the squad selection screen
  MAX_SQUADS = 14,
  -- number of squads available in vanilla
  VANILLA_SQUADS = 14,

  -- maximum number of palettes before they are force locked
  DEFAULT_MAX_PALETTES = 14,
  -- number of palettes used in vanilla
  VANILLA_PALETTES = 14,

  -- weapon deck constants
  WEAPON_CONFIG_NONE = 0,
  WEAPON_CONFIG_SHOP_NORMAL = 1,
  WEAPON_CONFIG_SHOP_ADVANCED = 2,
  WEAPON_CONFIG_POD_NORMAL = 4,
  WEAPON_CONFIG_POD_ADVANCED = 8,
  WEAPON_CONFIG_ALL = 15,

  -- pilot deck constants
  PILOT_CONFIG_NONE = 0,
  PILOT_CONFIG_POD_NORMAL = 1,
  PILOT_CONFIG_POD_ADVANCED = 2,
  PILOT_CONFIG_RECRUIT = 4,

  -- game squad index constants
  -- squads 0-7 are the first 8 vanilla squads
  -- 8 and 9 are random and custom
  -- squad 10 is secret, 11-15 are Advanced
  SQUAD_INDEX_START = 0,
  SQUAD_INDEX_END = 15,
  SQUAD_INDEX_RANDOM = 8,
  SQUAD_INDEX_CUSTOM = 9,
  SQUAD_INDEX_SECRET = 10,
}
