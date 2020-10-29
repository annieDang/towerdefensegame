class Button
    @@buttons = []
    @@draw_fun = nil
    attr_accessor :x, :y, :width, :height, :label, :font_size, :id, :hidden, :left_align, :color, :mouse_over_color
    def initialize(x, y, width, height, label, id, font_size = 15)
        @x = x
        @y = y
        @width = width
        @height = height
        @label = label
        @id = id
        @font_size = font_size

        @hidden = false
        @@buttons << self
    end

    def set_left_align
        @left_align = true
    end

    def set_hidden hidden
        @hidden = hidden
    end
    def hidden?
        @hidden
    end

    def self.buttons
        @@buttons
    end

    def isHovered?
        Engine::Game.area_clicked(@x, @y, @x + @width, @y + @height)
    end

    def draw
        return if hidden?
        button_font = Gosu::Font.new(@font_size)
        color = @color
        color = (@mouse_over_color || Gosu::Color::BLUE) if isHovered?
        $window.draw_rect(@x, @y, @width, @height, color || Gosu::Color.new(107,106,76))
        
        width = button_font.text_width(@label, scale_x = 1)
        height = button_font.height

        if @left_align
            button_font.draw(@label, @x + 20, @y + (@height - height)/2, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        else
            button_font.draw(@label, @x + (@width - width)/2, @y + (@height - height)/2, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        end 
    end
end