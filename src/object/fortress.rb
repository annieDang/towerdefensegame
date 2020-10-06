class Fortress 
    attr_accessor :name, :x, :y, :money, :wave, :height, :width, :level, :health
    def initialize(name, x, y, width, height)
        @name = name
        @x = x
        @y = y
        @width = width
        @height = height
        @level = 1
        setting = SETTING["level"][@level.to_s]
        @health = setting["health"]
        @money = setting["money"]
        @wave = SETTING["wave"][setting["wave"]]
    end
end