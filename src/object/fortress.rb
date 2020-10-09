class Fortress < Obstacle
    attr_accessor :name, :x, :y, :image, :money, :wave, :height, :width, :level, :health, :number_of_creeps, :number_of_infected_land
    def initialize(name, x, y, type, width, height)
        super(Obstacle_type::HQ, x, y)
        @name = name
        @width = width
        @height = height
        @level = 1
        load_setting 
        @coin_img = Gosu::Image.new("./media/coin.png")
    end

    def draw 
        start_x = @x * TILE_OFFSET + SIDE_WIDTH
        start_y = @y * TILE_OFFSET
        $window.draw_rect(start_x,start_y,TILE_OFFSET * @width,5, Gosu::Color::BLACK, ZOrder::BACKGROUND)
        draw_health_bar(@health, @full_health, start_x, start_y, TILE_OFFSET * @width,5)

        @image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * @width * 1.0) /@image.width,  (TILE_OFFSET * @height * 1.0) /@image.height)
        @coin_img.draw((start_x + TILE_OFFSET + TILE_OFFSET/2), start_y + TILE_OFFSET + TILE_OFFSET/2, ZOrder::BACKGROUND, 5.0/@image.width,  5.0/@image.height)
        @info_font = Gosu::Font.new(15)
        @info_font.draw(
            "#{@money} X ", 
            (SIDE_WIDTH + @x * TILE_OFFSET + TILE_OFFSET/2),
            @y * TILE_OFFSET + TILE_OFFSET + TILE_OFFSET/2,  
            ZOrder::PLAYER, 
            1.0,
            1.0,
            Gosu::Color::WHITE)
            draw_health_bar(@health, @full_health, start_x, start_y, TILE_OFFSET * @width,5)
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
