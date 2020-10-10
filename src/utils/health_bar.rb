def draw_health_bar(current_health, max_health, x, y, width, height, z = ZOrder::BACKGROUND)
    percent = calc_health_percentage(current_health, max_health)
    ratio = (current_health * 1.0)/max_health
    if percent >= 65
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color::BLUE, z)
    elsif percent >= 45
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color::YELLOW, z)
    elsif percent >= 25
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color::RED, z)
    else
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color.new(139,0,0), z)
    end
end
  
def calc_health_percentage(current_health, max_health)
    ((current_health * 1.0 )/max_health)*100
end

  