_G.utils = {}

-- Must load before any vim.pack.add() call to intercept registrations.
require("utils.pack_manager")

utils.func = require("utils.func")
setmetatable(utils, { __index = utils.func })

utils.toggles = require("utils.toggles")
utils.bufdelete = require("utils.bufdelete")
utils.fold = require("utils.fold")
utils.term = require("utils.terminal")
utils.dashboard = require("utils.dashboard")
utils.filter = require("utils.filter")

require("utils.viewsaver")
