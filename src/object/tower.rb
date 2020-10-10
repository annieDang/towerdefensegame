class Tower < Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :level, :health, :target, :name, :price, :sell_price, :damage, :type, :range, :cooldown, :status, :tower_type, :des, :last_attack_time
    @@towers = []
    def initialize(type, x, y)
        super(Obstacle_type::Tower, x, y)

        @type = type;
        @status = Tower_status::Building
        @level = 1
        
        load_setting

        @circle = Gosu::Image.new("media/range.png")
        @target = nil

        @last_attack_time = Gosu.milliseconds
        @last_bullet = Gosu.milliseconds

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
        @tower_type = setting["level#{@level}"]["tower_type"]
        @health = setting["level#{@level}"]["health"]
        @full_health = setting["level#{@level}"]["health"]
        @des = setting["level#{@level}"]["des"]
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

    def self.clear_towers
        @@towers = []
    end

    def self.remove_tower x, y
        @@towers.reject! {|tower| tower.x == x  and tower.y == y }
    end

    def self.remove_tower tower
        @@towers.reject! {|t| tower.x == t.x  and tower.y == t.y }
    end

    def draw
        start_x = @x * TILE_OFFSET + SIDE_WIDTH
        start_y = @y * TILE_OFFSET
        
        # healthbar
        $window.draw_rect(start_x, start_y ,TILE_OFFSET,5, Gosu::Color::BLACK, ZOrder::UI)
        draw_health_bar(@health, @full_health, start_x, start_y, TILE_OFFSET, 5, ZOrder::UI)
       
        # indicator
        $window.draw_rect(start_x, start_y, TILE_OFFSET, TILE_OFFSET, Gosu::Color.new(139,69,19), ZOrder::TOWER)
       
        # building image
        @image.draw(start_x, start_y, ZOrder::TOWER, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
        
        # attacking
        if !@target.nil? and (Gosu.milliseconds -  @last_bullet) > 50
            draw_bullet()
            @last_bullet = Gosu.milliseconds
        end
    end

    def draw_indicator
        start_x = @x * TILE_OFFSET + SIDE_WIDTH + TILE_OFFSET/2
        start_y = @y * TILE_OFFSET + TILE_OFFSET/2
        draw_circle(start_x, start_y , @range/2, ZOrder::TOWER)
    end

    # Check collision against another sprite
    def collision?(other)
        start_x = @x * TILE_OFFSET + SIDE_WIDTH + TILE_OFFSET/2
        start_y = @y * TILE_OFFSET + TILE_OFFSET/2
        dis = Gosu::distance(start_x, start_y, other.x, other.y)
        puts "dis :#{dis} , #{other.x}, #{other.y} : #{@x} #{@y}"
        Gosu::distance(start_x, start_y, other.x, other.y) < @range/2
    end

    def draw_bullet
        start_x = @x * TILE_OFFSET + SIDE_WIDTH + TILE_OFFSET/2
        start_y = @y * TILE_OFFSET + TILE_OFFSET/2
        thickness = 2
        color =  Gosu::Color::RED
        $window.draw_quad(start_x - thickness/2, start_y, color, start_x + thickness/2, start_y, color, @target.x - thickness/2, @target.y, color, @target.x + thickness/2, @target.y, color, ZOrder::TOWER)
    end

    def is_shooting?(creep)
        collision?(creep) and !creep.die? and !creep.exploded?
    end
    
    def attack (creeps)
        @target = nil
        return if (Gosu.milliseconds -  @last_attack_time) < 100
        tower_x = @x * TILE_OFFSET + SIDE_WIDTH + TILE_OFFSET/2
        tower_y = @y * TILE_OFFSET + TILE_OFFSET/2

        creeps_in_tower_range = Array.new
        creeps.each do |creep|
            if is_shooting?(creep)
                if tower_type == Tower_type::Effect
                    # slow pokemon down
                    creep.speed = creep.speed - @damage  < 1? 1 : creep.speed - @damage
                else
                    creeps_in_tower_range << creep
                end
            else
                # give pokemon back its normal speed
                creep.speed = SETTING["zombies"][creep.type.to_s]["speed"]
            end
        end
            
        if creeps_in_tower_range.length > 0
            nearest_creep = creeps_in_tower_range[0]
            if (creeps_in_tower_range.length > 1)
                for creep in 1..(creeps_in_tower_range.length - 1)
                    min_dis = Gosu::distance(tower_x, tower_y, nearest_creep.x, nearest_creep.y)
                    creep_dis = Gosu::distance(tower_x, tower_y, creeps_in_tower_range[creep].x, creeps_in_tower_range[creep].y)
                    nearest_creep = creeps_in_tower_range[creep] if min_dis > creep_dis
                end
            end
            nearest_creep.health -= @damage
            nearest_creep.kill! if(nearest_creep.health <= 0)
            @target = nearest_creep
            @last_attack_time = Gosu.milliseconds
        end
    end

end