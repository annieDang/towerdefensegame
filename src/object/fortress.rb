class Fortress < Obstacle
    attr_accessor :name, :x, :y, :image, :money, :wave, :height, :width, :level, :health, :number_of_creeps, :number_of_infected_land
    def initialize(name, x, y, type, width, height)
        super(Obstacle_type::HQ, x, y)
        @name = name
        @width = width
        @height = height
        @level = 1
        load_setting 
    end

    def draw 
        start_x = @x * TILE_OFFSET + SIDE_WIDTH
        start_y = @y * TILE_OFFSET
        # indicator 
        $window.draw_rect(start_x, start_y, TILE_OFFSET, TILE_OFFSET, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        $window.draw_rect(start_x + TILE_OFFSET, start_y, TILE_OFFSET, TILE_OFFSET, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        $window.draw_rect(start_x, start_y + TILE_OFFSET, TILE_OFFSET, TILE_OFFSET, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        $window.draw_rect(start_x + TILE_OFFSET, start_y + TILE_OFFSET, TILE_OFFSET, TILE_OFFSET, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        # health bar
        $window.draw_rect(start_x,start_y,TILE_OFFSET * @width,5, Gosu::Color::BLACK, ZOrder::TOWER)
        draw_health_bar(@health, @full_health, start_x, start_y, TILE_OFFSET * @width,5)
        # building img
        @image.draw(start_x, start_y, ZOrder::TOWER, (TILE_OFFSET * @width * 1.0) /@image.width,  (TILE_OFFSET * @height * 1.0) /@image.height)
    end

    def load_setting
        setting = SETTING["level"][@level.to_s]
        @health = setting["health"]
        @full_health = setting["health"]
        @money = setting["money"]
        @wave = SETTING["wave"][setting["wave"]]
        @number_of_creeps = setting["number_of_creeps"]
        @number_of_infected_land = setting["number_of_infected_land"]
    end

    def next_level
        @level += 1
        load_setting
    end
end
