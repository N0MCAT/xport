local love = require "love"

function love.conf(t)
    t.version = "11.5"
    t.title = "XPORT"
    t.console = true
    t.identity = "XPORT"
    t.appendidentity = true

    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 400
    t.window.minheight = 300

    t.window.vsync = 0
end
