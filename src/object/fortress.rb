class Fortress < Obstacle
    attr_accessor :x, :y, :image, :money, :wave, :height, :width, :level, :health, :number_of_creeps, :number_of_infected_land
    def initialize(x, y, width, height)
        super(Obstacle_type::HQ, x, y)
        @width = width
        @height = height
        @level = 1
        load_setting 
    end

    def draw 
        start_x, start_y = map_location(@x, @y)
        tile_size = Engine::PlayState::TileSize
        # indicator 
        $window.draw_rect(start_x, start_y, tile_size, tile_size, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        $window.draw_rect(start_x + tile_size, start_y, tile_size, tile_size, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        $window.draw_rect(start_x, start_y + tile_size, tile_size, tile_size, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        $window.draw_rect(start_x + tile_size, start_y + tile_size, tile_size, tile_size, Gosu::Color.new(139,69,19), ZOrder::TOWER)
        # health bar
        $window.draw_rect(start_x,start_y,tile_size * @width,5, Gosu::Color::BLACK, ZOrder::TOWER)
        draw_health_bar(@health, @full_health, start_x, start_y, tile_size * @width,5, ZOrder::TOWER)
        # building img
        @image.draw(start_x, start_y, ZOrder::TOWER, (tile_size * @width * 1.0) /@image.width,  (tile_size * @height * 1.0) /@image.height)
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
