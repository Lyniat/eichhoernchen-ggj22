require 'app/squirrel.rb'

class State
  MENU = 0
  HOW_TO = 1
  PLAYING = 2
end

class Resources
  SPR_MENU = 'sprites/titel_2.png'
  SPR_SQUIRREL_FRONT = 'sprites/squirrel_front.png'
  SPR_GROUND = 'sprites/ground.png'
  SPR_SQUIRREL = 'sprites/squirrel.png'
  SPR_HAND = 'sprites/hand.png'
  FONT = 'fonts/shpinscher.ttf'
  SND_HIT = 'sounds/hit_'
  SND_NO = 'sounds/no_'
  MUSIC = 'sounds/music.ogg'
end

class Constants
  WIDTH = 1280
  HEIGHT = 720
  SQUIRREL_SIZE = 3
  TREE_WIDTH = 12
  TREE_HEIGHT = 60
  TILE_SIZE = 64
  DEG_RAD = (3.14159265359 * 2) / 360
  RAD = 30
  GRAVITY = 9.81
  MAX_SPEED = 20
  MAX_ARM_LENGTH = 7.5
  ARM_SPEED = 0.5
end

class Tiles
  BARK_LEFT = 0
  BARK = 1
  BARK_HOLE = 2
  BARK_RIGHT = 3
end

def get_bark_spr(id)
  "sprites/bark_#{id}.png"
end

def get_bark(x,y)
  is_sin = (Math.sin(y/3) * Constants::TREE_WIDTH/4 + Constants::TREE_WIDTH/2).round == x
  is_mod = y % 2 == 1
  is_rnd = Random.rand(y+1) == 1
  (is_sin && is_mod) || is_rnd ? Tiles::BARK_HOLE : Tiles::BARK
end

def create_tree
  width = Constants::TREE_WIDTH
  height = Constants::TREE_HEIGHT

  🌳 = []

  (0...width).each do |x|
    🌳[x] = []
    (0...height).each do |y|
      if x == 0
        🌳[x][y] = Tiles::BARK_LEFT
      elsif x == width - 1
        🌳[x][y] = Tiles::BARK_RIGHT
      else
        🌳[x][y] = get_bark(x,y)
      end
    end
  end

  🌳
end

def cam_offset_x
  Constants::WIDTH/2 - @camera.x
end

def cam_offset_y
  Constants::HEIGHT/2 - @camera.y
end

def reset
  @🌳 = nil
  @🐿 = nil

  @game_state ||= State::MENU
end

def tick args
  # start music
  if args.state.tick_count == 0
    music = {
      input: Resources::MUSIC,  # Filename
      x: 0.0, y: 0.0, z: 0.0,   # Relative position to the listener, x, y, z from -1.0 to 1.0
      gain: 0.2,                # Volume (0.0 to 1.0)
      pitch: 1.0,               # Pitch of the sound (1.0 = original pitch)
      paused: false,           # Set to true to pause the sound at the current playback position
      looping: true,           # Set to true to loop the sound/music until you stop it
    }
    args.audio[:main] = music
  end

  args.outputs.background_color = [68,173,212]

  @args = args
  @out = args.outputs
  @sprites = args.outputs.sprites
  @ticks = args.state.tick_count
  @labels = args.outputs.labels
  @input = args.inputs
  @camera ||= { x: Constants::WIDTH/2, y: Constants::HEIGHT/2}
  @🌳 ||= create_tree
  @🐿 ||= Squirrel.new(@args,@camera,@🌳,Constants::WIDTH/2,Constants::HEIGHT/2,Constants::SQUIRREL_SIZE)

  @game_state ||= State::MENU

  case @game_state
  when State::MENU
    scene_menu
  when State::HOW_TO
    scene_how_to
  when State::PLAYING
    scene_playing
    if @input.keyboard.key_down.backspace
      reset
    end
    if @input.keyboard.key_down.escape
      reset
      @game_state = State::MENU
    end
  end

end

def scene_how_to
  draw_grass

  how_to_one = ['Player One:','W','A','D']

  i = 0
  how_to_one.each do |c|
    @labels << [500, Constants::HEIGHT - 35 * i - 250, c, 20, 1, 50, 50, 50, 255, Resources::FONT ]
    i += 1
  end

  how_to_two = ['Player Two:','UP','LEFT','RIGHT']

  i = 0
  how_to_two.each do |c|
    @labels << [Constants::WIDTH - 500, Constants::HEIGHT - 35 * i - 250, c, 20, 1, 50, 50, 50, 255, Resources::FONT ]
    i += 1
  end

  if @input.keyboard.key_down.space
    @game_state = State::PLAYING
  end
end

def draw_grass
  ground_scale = 4
  (-4..8).each do |i|
    @sprites << [i * 64 * ground_scale + cam_offset_x, cam_offset_y, 64 * ground_scale, 64 * ground_scale, Resources::SPR_GROUND]
  end
end

def scene_menu
  squirrel_scale = 6
  text_scale = 6
  sin_scale = Math.sin(@ticks/10) * 15
  @sprites << [576, -60, 64 * squirrel_scale, 64 * squirrel_scale, Resources::SPR_SQUIRREL_FRONT]
  @sprites << [300, 120, 64 * text_scale + sin_scale, 64 * text_scale + sin_scale, Resources::SPR_MENU]

  draw_grass

  credits = ['A GGJ22 game by:','Kerstin','Laurin','Lea','Marcel']

  i = 0
  credits.each do |c|
    @labels << [Constants::WIDTH - 40, Constants::HEIGHT - 35 * i, c, 20, 2, 50, 50, 50, 255, Resources::FONT ]
    i += 1
  end

  @labels << [40, Constants::HEIGHT, 'PRESS SPACE TO START', 20, 0, 50, 50, 50, 255, Resources::FONT ]

  #input

  if @input.keyboard.key_down.space
    @game_state = State::HOW_TO
  end
end

def cam_follow_player
  offset = 50
  if @camera.x > @🐿.x + offset
    @camera.x = @🐿.x + offset
  elsif @camera.x < @🐿.x - offset
    @camera.x = @🐿.x - offset
  end

  if @camera.y > @🐿.y + offset
    @camera.y = @🐿.y + offset
  elsif @camera.y < @🐿.y
    @camera.y = @🐿.y
  end
end

def limit
  if @camera.y < Constants::HEIGHT/2
    @camera.y = Constants::HEIGHT/2
  end
end

def scene_playing

  # @🐿.test_move
  @🐿.hand_move
  @🐿.update_physics
  cam_follow_player
  limit

  mid_offset = Constants::WIDTH / 2 - (Constants::TREE_WIDTH * Constants::TILE_SIZE) / 2
  # draw tree ( and btw. check for holes :D )
  (0...Constants::TREE_WIDTH).each do |x|
    (0...Constants::TREE_HEIGHT).each do |y|
      tree_x = x * Constants::TILE_SIZE + mid_offset + cam_offset_x
      tree_y = y * Constants::TILE_SIZE + cam_offset_y
      @sprites << [tree_x,
                   tree_y,
                   Constants::TILE_SIZE,
                   Constants::TILE_SIZE,
                   get_bark_spr(@🌳[x][y])]

      if @🌳[x][y] == Tiles::BARK_HOLE
        # midpoint
        tree_x += Constants::TILE_SIZE/2
        tree_y += Constants::TILE_SIZE/2

        left_x, left_y = @🐿.get_hand_left
        # midpoint
        left_x += Constants::SQUIRREL_SIZE * 6
        left_y += Constants::SQUIRREL_SIZE * 6

        dist_l = Math.sqrt((tree_x-left_x)**2 + (tree_y-left_y)**2)

        right_x, right_y = @🐿.get_hand_right
        # midpoint
        right_x += Constants::SQUIRREL_SIZE * 6
        right_y += Constants::SQUIRREL_SIZE * 6
        dist_r = Math.sqrt((tree_x-right_x)**2 + (tree_y-right_y)**2)

        if dist_l < Constants::TILE_SIZE/2
          @🐿.found_hole_left
        end

        if dist_r < Constants::TILE_SIZE/2
          @🐿.found_hole_right
        end
      end
    end
  end

  @🐿.draw

  draw_grass

  # @camera.y += 0.3
end
