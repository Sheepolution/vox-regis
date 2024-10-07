CONFIG = {}

-- Game
CONFIG.title = "Vox Regis"

-- Size
CONFIG.windowScale = .5
CONFIG.gameScale = 4
CONFIG.gameScaleFake = 4
CONFIG.baseWidth = 1920
CONFIG.baseHeight = 1920

CONFIG.gameWidth = CONFIG.baseWidth / CONFIG.gameScale
CONFIG.gameHeight = CONFIG.baseHeight / CONFIG.gameScale

-- Window
CONFIG.window = {}
CONFIG.window.width = CONFIG.baseWidth * CONFIG.windowScale
CONFIG.window.height = CONFIG.baseHeight * CONFIG.windowScale
CONFIG.window.vsync = 0
CONFIG.window.resizable = true
CONFIG.window.minwidth = 480
CONFIG.window.minheight = 480
CONFIG.window.fullscreen = false
CONFIG.window.icon = "icon.png"

-- Audio
CONFIG.defaultSFXVolume = .6
CONFIG.defaultMusicVolume = 1

-- Speed
CONFIG.minFPS = 1 / 60

-- Graphics
CONFIG.defaultGraphicsFilter = "nearest"
CONFIG.defaultAnimationSpeed = 12

-- Text
CONFIG.defaultFont = "m5x7_custom"
CONFIG.defaultFontSize = 16

-- Input
CONFIG.gamepadSupport = false

-- Scene
CONFIG.useSpatialHash = false
CONFIG.defaultSpatialHashSize = 256

-- Map
CONFIG.levelPreloadRange = 100
CONFIG.levelActivateRange = 50

-- Libs
CONFIG.useLurker = true

function love.conf(t)
	io.stdout:setvbuf("no")
	t.identity = CONFIG.title:lower():gsub(" ", "_"):gsub(":", "")
	t.version = "11.5"
	t.window = nil
	t.modules.physics = false
	t.modules.touch = false
	t.modules.video = true
end
