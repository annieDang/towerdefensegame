require 'rubygems'
require 'gosu'
require 'json'

require_relative 'zorder'
require_relative 'setting'
require_relative 'util'
require_relative 'engine'
require_relative 'object'
require_relative 'game_map'
require_relative 'sprite/creep'

game = Engine::Game.instance
game.show
