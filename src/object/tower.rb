class Tower < Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :level, :name, :cost, :sell_price, :upgrage_price, :damage, :type, :range, :cooldown, :status
    
    def initialize(type, x, y)
        super(Obstacle_type::Tower, x, y)

        @type = type;
        @status = Tower_status::Building
        setting = SETTING["tower"][@type.to_s]
        @level = 1
        @image = Gosu::Image.new(setting["level#{@level}"]["image"])
        @range = setting["level#{@level}"]["range"]
    end

end