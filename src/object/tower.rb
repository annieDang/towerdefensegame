class Tower < Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :level, :name, :price, :sell_price, :damage, :type, :range, :cooldown, :status
    @@towers = []
    def initialize(type, x, y)
        super(Obstacle_type::Tower, x, y)

        @type = type;
        @status = Tower_status::Building
        @level = 1
        
        load_setting

        @circle = Gosu::Image.new("media/range.png")
        
        # put tower in shared list
        @@towers << self
    end

    def load_setting
        setting = SETTING["tower"][@type.to_s]
        @image = Gosu::Image.new(setting["level#{@level}"]["image"])
        @range = setting["level#{@level}"]["range"].to_f
        @damage = setting["level#{@level}"]["damage"]
        @price = setting["level#{@level}"]["price"]
        @sell_price = @price/2
    end

    def get_upgrade_price
        return -1 if ((@level + 1) >3)
        setting = SETTING["tower"][@type.to_s]
        return setting["level#{@level + 1}"]["upgrade_price"]
    end

    def upgrade
        @level += 1
        load_setting
    end

    def self.towers
        @@towers
    end

    def draw
        start_x = @x * TILE_OFFSET + SIDE_WIDTH
        start_y = @y * TILE_OFFSET
        @image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
        @circle.draw(start_x + TILE_OFFSET/2- @range/2, start_y + TILE_OFFSET/2 - @range/2, ZOrder::UI,  @range/@circle.width,  @range/@circle.width)
        @status = Tower_status::Built 
    end

    # Check collision against another sprite
    def collision?(other)
        start_x = @x * TILE_OFFSET + SIDE_WIDTH + TILE_OFFSET/2
        start_y = @y * TILE_OFFSET + TILE_OFFSET/2
        # puts "@range : #{@range} start_x: #{start_x}, start_y: #{start_y}, other (#{other.x},#{other.y})"
        Gosu::distance(start_x, start_y, other.x, other.y) < @range/2
    end

end