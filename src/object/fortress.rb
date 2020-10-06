class Fortress 
    attr_accessor :name, :x, :y, :money, :wave, :height, :width, :level, :health, :number_of_creeps
    def initialize(name, x, y, width, height)
        @name = name
        @x = x
        @y = y
        @width = width
        @height = height
        load_setting 
    end

    def load_setting
        @level = 1
        setting = SETTING["level"][@level.to_s]
        @health = setting["health"]
        @money = setting["money"]
        @wave = SETTING["wave"][setting["wave"]]
        @number_of_creeps = setting["number_of_creeps"]
    end
end