require 'singleton'

module Engine
  class Game < Gosu::Window
    include Singleton
    
    ScreenWidth = 1016
    ScreenHeight = 768
    FadingTime = 500

    # Constructor. Setups the video mode and creates a window (60 fps)
    def initialize      
      super(ScreenWidth, ScreenHeight, false)
      self.caption = "Mad Pokemon"
      $window = self

      @@images = Hash.new
      @@fonts = Hash.new      
      load_images
      load_fonts

      @@fading_off = false
      @@fading_on = false
      @@end_fade = 0
      @@start_fade = 0

      @@change_game_state = nil

      @@game_state = MenuState.new
    end

    # Returns a hash map with the images collection
    def Game.images
      @@images
    end

    # Returns a hash map with the fonts collection
    def Game.fonts
      @@fonts
    end

    # Returns the current game state
    def Game.game_state
      @@game_state
    end
    
    # Changes to another game state
    def Game.game_state=(st)
      @@change_game_state = st.new
      Game.fade_off(FadingTime)
    end

    # Starts a fade off transition
    def Game.fade_off(time)
      return if Game.fading?
      @@start_fade = Gosu::milliseconds
      @@end_fade = @@start_fade + time
      @@fading_off = true
    end

    # Returns whether there is a fade running or not
    def Game.fading?
      @@fading_off or @@fading_on
    end
    
    # Ends fade transitions
    def Game.end_fade!
      @@fading_off = false
      @@fading_on = false
    end

     # Starts a fade on transition
     def Game.fade_on(time)
      return if Game.fading?
      @@start_fade = Gosu::milliseconds
      @@end_fade = @@start_fade + time
      @@fading_on = true
    end
    
    # Returns whether there is a fade running or not
    def Game.fading?
      @@fading_off or @@fading_on
    end
    
    # Quits game
    def Game.quit
      self.instance.close
    end

    # Updates the game logic. Gets called automatically by Gosu each frame
    def update
      @@game_state.update unless Game.fading?      
      
      # update fading
      Game.end_fade! if Gosu::milliseconds >= @@end_fade and Game.fading?
      
      #update changing between game states
      if @@change_game_state and not Game.fading?
        @@game_state = @@change_game_state
        @@change_game_state = nil
        Game.fade_on(FadingTime)
      end
    end

    # Draws the game entities on the screen. Gets called automatically by Gosu each frame
    def draw
      @img_background = Game::images["background"]
      @img_background.draw(0, 0, ZOrder::BACKGROUND, (ScreenWidth * 1.0) /@img_background.width,  (ScreenHeight * 1.0) /@img_background.height)
      @@game_state.draw

      if Game.fading?
        delta = (Gosu::milliseconds - @@start_fade).to_f / (@@end_fade - @@start_fade)
        alpha = @@fading_off ? delta : 1 - delta
        @img_background.draw(0, 0, ZOrder::BACKGROUND, (ScreenWidth * 1.0) /@img_background.width,  (ScreenHeight * 1.0) /@img_background.height, Gosu::Color.new((alpha * 0xff).to_i, 0xff, 0xff, 0xff))
      end
    end

    # Gets called automatically by Gosu when a button is pressed
    def button_down(id)
      @@game_state.button_down(id)
    end

    # Loads all the images and stores them into the images hash map
    def load_images
      @@images["background"] = Gosu::Image.new(self, "media/ground.jpeg", true)
      @@images["circle"] = Gosu::Image.new(self, "media/ground.jpeg", true)
      @@images["creeps"] = Gosu::Image.load_tiles("./media/pokemons.png", 32, 32)
    end
    
    # Loads all fonts needed and stores them into the fonts hash map
    def load_fonts
      @@fonts["game"] = Gosu::Font.new(80)
      @@fonts["menu"] = Gosu::Font.new(40)
      @@fonts["notification"] = Gosu::Font.new(25)
      @@fonts["big"] = Gosu::Font.new(20)
      @@fonts["small"] = Gosu::Font.new(14)
      @@fonts["button"] = Gosu::Font.new(15)
    end

    def needs_cursor? 
      true 
    end

    # Detects if a 'mouse sensitive' area has been clicked on
    def Game.area_clicked(leftX, topY, rightX, bottomY)
      if (($window.mouse_x > leftX and $window.mouse_x < rightX) and ($window.mouse_y > topY and $window.mouse_y < bottomY))
        true
      else
        false
      end
    end

  end

end