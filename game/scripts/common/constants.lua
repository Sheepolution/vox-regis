-- CONSTANTS --
G = {}
COMPLAINT_LIST = list({ "taxes", "food", "disease", "crime" })
COMPLAINT_LIST_TITLE = list({ "Taxes", "Food", "Disease", "Crime" })
COMPLAINT_LIST_DESCRIPTION = {
    taxes = "the heavy taxes imposed on our people!",
    food = "the famine that plagues our land!",
    disease = "the sickness that spreads through our kingdom!",
    crime = "the bandits that terrorize our streets!"
}

FACTION_NAMES = {
    red = "Leo Ruber",
    green = "Rana Viridis",
    blue = "Elephas Caeruleus",
    yellow = "Cuniculus Aureus"
}

FACTION_NAMES_LIST = list({ FACTION_NAMES.red, FACTION_NAMES.green, FACTION_NAMES.blue, FACTION_NAMES.yellow })

PLEB_START_COUNT = 20

NEW_PLEB_INTERVAL = { .4, 1.5 }

PLEB_HEALTH = 3
PLEB_SPEED = 25
PLEB_WAR_SPEEDUP = 2
PLEB_ATTACK_INTERVAL = { .3, .5 }

PLEB_JOIN_FACTION_CHANCE = 70

FACTION_SIZE_DEFEAT = 30

GAME_DURATION_VICTORY = 60 * 5

SPEECH_DELAY = 10

SEEN_TUTORIAL = false -- Not a constant lol
