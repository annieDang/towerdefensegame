# encoding: utf-8

module Engine
  StartX = Game::ScreenWidth / 2
  StartY = Game::ScreenHeight / 3

    # This game state is the Credits screen
    class CreditsState < GameState
      # Constructor
      def initialize
        @font_small = Game.fonts["big"]
        @font_credits = Game.fonts["menu"]
        @button = Button.new(StartX - 125, StartY * 2, 250, 40, "Back to menu", "Back to menu", 40)
        
      end
  
      # Draws the credits screen
      def draw
        @font_small.draw_rel("Made by", StartX, StartY, ZOrder::UI, 0.5, 0.5)
        @font_credits.draw_rel("Annie Dang", StartX, StartY + 30, ZOrder::UI, 0.5, 0.5)
        @font_small.draw_rel("A Student Of Swinburne University", StartX, StartY + 60,  ZOrder::UI, 0.5, 0.5, 1, 1, 0xfff4cc00)
        @font_small.draw_rel("Who always loves to make people laugh", StartX, StartY + 90, ZOrder::UI, 0.5, 0.5, 1, 1, 0xfff4cc00)
        
        @button.draw
      end
  
      def button_down(id)
        case id
          when Gosu::MsLeft
            Game.game_state = MenuState if @button.isHovered?
          end
      end
    end
  end