require 'app/squirrel.rb'

class State
  MENU = 0
  HOW_TO = 1
  PLAYING = 2
end

class Condition
  DEFAULT = 0
  WIN = 1
  GAME_OVER = 2
end

class Resources
  SPR_SHEET = 'sprites/sheet.png'
  SPR_MENU = 'sprites/titel_2.png'
  SPR_SQUIRREL_FRONT = 'sprites/squirrel_front.png'
  SPR_GROUND = 'sprites/ground.png'
  SPR_SQUIRREL = 'sprites/squirrel.png'
  SPR_HAND = 'sprites/hand.png'
  SPR_CROWN_LEFT = 'sprites/crown_left.png'
  SPR_CROWN_MID = 'sprites/crown_mid.png'
  SPR_CROWN_RIGHT = 'sprites/crown_right.png'
  SPR_CLOUD = 'sprites/cloud.png'
  SPR_GAME_OVER = 'sprites/game_over.png'
  SPR_WIN = 'sprites/win.png'
  FONT = 'fonts/shpinscher.ttf'
  SND_HIT = 'sounds/hit_'
  SND_NO = 'sounds/no_'
  SND_WIN = 'sounds/win.wav'
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
  EASY_MODE = true # TODO: Remove this for publishing
end

class Tiles
  BARK_LEFT = 0
  BARK = 1
  BARK_HOLE = 2
  BARK_RIGHT = 3
end

def get_bark(x,y)
  is_sin = (Math.sin(y/3) * Constants::TREE_WIDTH/4 + Constants::TREE_WIDTH/2).round == x
  is_mod = y % 2 == 1
  is_rnd = Constants::EASY_MODE ? Random.rand(5) == 1 : Random.rand(y+1) == 1
  (is_sin && is_mod) || is_rnd ? Tiles::BARK_HOLE : Tiles::BARK
end

def create_clouds
  ☁️ = []
  min_y = (Constants::TREE_HEIGHT / 2).to_i
  max_y = Constants::TREE_HEIGHT

  (min_y...max_y).each do |i|
    if i% 2 == 0
      r = Random.rand(Constants::TREE_WIDTH*1.5) - Constants::TREE_WIDTH/6
      a = Random.rand(255)
      c = {x: r, y: i, a: a}
      ☁️ << c
    end
  end
  ☁️
end

def mid_offset
  Constants::WIDTH / 2 - (Constants::TREE_WIDTH * Constants::TILE_SIZE) / 2
end

def cloud_min_x
  (mid_offset - Constants::TREE_WIDTH).to_i
end

def cloud_max_x
  (mid_offset + Constants::TREE_WIDTH).to_i
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
  @☁️ = nil

  @game_state ||= State::MENU
  @condition_state ||= Condition::DEFAULT
  @played_sound = false
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
  @☁️ ||= create_clouds

  @game_state ||= State::MENU
  @condition_state ||= Condition::DEFAULT
  @played_sound ||= false

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

  credits = ['A GGJ22 game (remake) by:','Kerstin','Laurin','Lea','Marcel']

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
  if @condition_state == Condition::DEFAULT
    cam_follow_player
  end
  limit

  # draw tree crown
  (-1..Constants::TREE_WIDTH).each do |x|
    y = Constants::TREE_HEIGHT
    crown_x = x * Constants::TILE_SIZE + mid_offset + cam_offset_x
    crown_y = y * Constants::TILE_SIZE + cam_offset_y
    sprite = Resources::SPR_CROWN_MID
    if x == -1
      sprite = Resources::SPR_CROWN_LEFT
    elsif x == Constants::TREE_WIDTH
      sprite = Resources::SPR_CROWN_RIGHT
    end
    @sprites << [crown_x,
                 crown_y,
                 Constants::TILE_SIZE,
                 Constants::TILE_SIZE,
                 sprite]
  end

  # draw tree ( and btw. check for holes :D )
  (0...Constants::TREE_WIDTH).each do |x|
    (0...Constants::TREE_HEIGHT).each do |y|
      tree_x = x * Constants::TILE_SIZE + mid_offset + cam_offset_x
      tree_y = y * Constants::TILE_SIZE + cam_offset_y
      @sprites << {
        x: tree_x,
        y: tree_y,
        w: Constants::TILE_SIZE,
        h: Constants::TILE_SIZE,
        path:  Resources::SPR_SHEET,
        source_x: @🌳[x][y] * Constants::TILE_SIZE,
        source_y: 0,
        source_w: Constants::TILE_SIZE,
        source_h: Constants::TILE_SIZE
      }

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

  draw_clouds

  if @🐿.y > (Constants::TREE_HEIGHT-1) * Constants::TILE_SIZE
    @condition_state = Condition::WIN
  end

  case @condition_state
  when Condition::WIN
    # if !@played_sound
    #  @played_sound = true
    #  @args.outputs.sounds << Resources::SND_WIN
    # end
    crown_x = (Constants::TREE_WIDTH * Constants::TILE_SIZE)/2 + mid_offset + cam_offset_x - Constants::TILE_SIZE*2
    crown_y = Constants::TREE_HEIGHT * Constants::TILE_SIZE + cam_offset_y
    @sprites << [crown_x,
                 crown_y,
                 Constants::TILE_SIZE * 4,
                 Constants::TILE_SIZE * 4,
                 Resources::SPR_WIN]
  end
end

def draw_clouds
  @☁️.each do |c|
    cloud_x = c.x * Constants::TILE_SIZE + mid_offset + cam_offset_x
    cloud_y = c.y * Constants::TILE_SIZE + cam_offset_y
    @sprites << [cloud_x,
                 cloud_y,
                 Constants::TILE_SIZE * 4,
                 Constants::TILE_SIZE * 4,
                 Resources::SPR_CLOUD]
  end
end
