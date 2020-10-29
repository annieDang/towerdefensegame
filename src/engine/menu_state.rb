module Engine
  # This game state is the main menu screen
  class MenuState < GameState
    ButtonX = Game::ScreenWidth / 2 - 75
    ButtonY = Game::ScreenHeight / 2
    ButtonGap = 60
    
    # Constructor
    def initialize
      @game_font = Game::fonts["game"]
      
      @button_labels = ["New Game", "Credits", "Quit"]
      @buttons =[]

      @button_labels.size.times do |i|
        button = Button.new(ButtonX, ButtonY + i * ButtonGap, 250, 50, @button_labels[i], @button_labels[i], 40)
        button
        @buttons << button
      end

    end
    
    # Updates the main menu screen elements
    def update
    end
    
    # Draws the main menu screen elements
    def draw
      game_name = "MAD POKEMONS"
      height = @game_font.height
      width = @game_font.text_width(game_name, scale_x = 1)
      x = Game::ScreenWidth / 2
      y = Game::ScreenHeight / 3
      @game_font.draw(game_name, x - width/2 ,y - height/2, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      
      @buttons.each {|button|  button.draw }
    end
    
    # Gets called automatically when the user presses down a button
    def button_down(id)
      case id
        when Gosu::MsLeft
          button_handler
        end
    end

    # handle button event
    def button_handler
        @buttons.each do |button|
            next if button.hidden?
            next if !button.isHovered?
            case button.id
            when "New Game"
              Game.game_state = PlayState
            when "Credits"
              Game.game_state = CreditsState
            when "Quit"
              Game.quit
            end
        end
    end
  end

end