class Fortress < Obstacle
    attr_accessor :name, :x, :y, :image, :money, :wave, :height, :width, :level, :health, :number_of_creeps
    def initialize(name, x, y, type, width, height)
        super(Obstacle_type::HQ, x, y)
        @name = name
        @width = width
        @height = height
        load_setting 
    end

    def draw 
        start_x = @x * TILE_OFFSET + SIDE_WIDTH
        start_y = @y * TILE_OFFSET
        @image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * @width * 1.0) /@image.width,  (TILE_OFFSET * @height * 1.0) /@image.height)
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