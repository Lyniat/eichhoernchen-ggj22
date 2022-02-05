# frozen_string_literal: true

class Squirrel
  attr_reader :x, :y

  def initialize(args, cam, 🌳, x, y, size)
    @sprites = args.outputs.sprites
    @lines = args.outputs.lines
    @args = args
    @camera = cam
    @🌳 = 🌳
    @input = args.inputs
    @x = x
    @y = y
    @size = size
    @speed_x = 0
    @speed_y = 0
    @moving_left_hand = false
    @moving_left_backward = false
    @moving_right_hand = false
    @moving_right_backward = false
    @left_arm_length = 0
    @right_arm_length = 0
    @hand_left_pos_x = 0
    @hand_left_pos_y = 0
    @hand_right_pos_x = 0
    @hand_right_pos_y = 0
  end

  def play_sound_hit
    @args.outputs.sounds << "#{Resources::SND_HIT}#{Random.rand(3)}.wav"
  end

  def play_sound_no
    @args.outputs.sounds << "#{Resources::SND_NO}#{Random.rand(3)}.wav"
  end

  def offset
    [Constants::WIDTH / 2 - @camera.x, Constants::HEIGHT / 2 - @camera.y]
  end

  def width
    38 * @size
  end

  def height
    40 * @size
  end

  def draw
    offset_x, offset_y = offset
    @x_pos = @x + offset_x
    @y_pos = @y + offset_y
    draw_hand_left(-15)
    draw_hand_right(65)
    @sprites << [@x_pos, @y_pos, 38 * @size, 40 * @size, Resources::SPR_SQUIRREL]
  end

  def get_rot(rot)
    [Math.sin(rot * Constants::DEG_RAD) * Constants::RAD,
     Math.cos(rot * Constants::DEG_RAD) * Constants::RAD]
  end

  def draw_hand_left(x)
    ang_x, ang_y = get_rot(@rot_left)
    @hand_left_pos_x = @x_pos + x + ang_x * @left_arm_length
    @hand_left_pos_y = @y_pos + 80 + ang_y * @left_arm_length
    @sprites << [@hand_left_pos_x, @hand_left_pos_y, 9 * @size * 2, 6 * @size * 2, Resources::SPR_HAND, -@rot_left]
  end

  def draw_hand_right(x)
    ang_x, ang_y = get_rot(@rot_right)
    @hand_right_pos_x = @x_pos + x + ang_x * @right_arm_length
    @hand_right_pos_y = @y_pos + 80 + ang_y * @right_arm_length
    @sprites << [@hand_right_pos_x, @hand_right_pos_y, 9 * @size * 2, 6 * @size * 2, Resources::SPR_HAND, -@rot_right]
  end

  # unnecessary
  def test_move
    speed = 4
    direction_x = if @input.keyboard.key_held.left
                    -1
                  else
                    (@input.keyboard.key_held.right ? 1 : 0)
                  end
    direction_y = if @input.keyboard.key_held.down
                    -1
                  else
                    (@input.keyboard.key_held.up ? 1 : 0)
                  end
    @x += direction_x * speed
    @y += direction_y * speed
  end

  def update_physics
    @speed_y -= Constants::GRAVITY / 60
    if @speed_y > Constants::MAX_SPEED / 2
      @speed_y = Constants::MAX_SPEED / 2
    elsif @speed_y < -Constants::MAX_SPEED
      @speed_y = -Constants::MAX_SPEED
    end

    @y += @speed_y
    @x += @speed_x

    @speed_x /= 1.035

    @speed_x = 0 if @speed_x < 1 && @speed_x > -1

    if @y.negative?
      @y = 0
      @speed_y = 0
    end
  end

  def hand_move
    speed = 4
    @rot_left ||= 0
    unless @moving_left_hand
      @rot_left += (if @input.keyboard.key_held.a
                      -1
                    else
                      (@input.keyboard.key_held.d ? 1 : 0)
                    end) * speed
      @rot_left += 360 if @rot_left.negative?
      @rot_left -= 360 if @rot_left > 360
    end

    unless @moving_right_hand
      @rot_right ||= 0
      @rot_right += (if @input.keyboard.key_held.left
                       -1
                     else
                       (@input.keyboard.key_held.right ? 1 : 0)
                     end) * speed
      @rot_right += 360 if @rot_right.negative?
      @rot_right -= 360 if @rot_right > 360
    end
    arm_move
  end

  def arm_move
    if @moving_left_hand
      if !@moving_left_backward
        @left_arm_length += Constants::ARM_SPEED
        if @left_arm_length > Constants::MAX_ARM_LENGTH
          @left_arm_length = Constants::MAX_ARM_LENGTH
          @moving_left_backward = true
          play_sound_no
        end
      else
        @left_arm_length -= Constants::ARM_SPEED
        if @left_arm_length.negative?
          @left_arm_length = 0
          @moving_left_backward = false
          @moving_left_hand = false
        end
      end
    else
      @moving_left_hand = @input.keyboard.key_down.w
    end

    if @moving_right_hand
      if !@moving_right_backward
        @right_arm_length += Constants::ARM_SPEED
        if @right_arm_length > Constants::MAX_ARM_LENGTH
          @right_arm_length = Constants::MAX_ARM_LENGTH
          @moving_right_backward = true
          play_sound_no
        end
      else
        @right_arm_length -= Constants::ARM_SPEED
        if @right_arm_length.negative?
          @right_arm_length = 0
          @moving_right_backward = false
          @moving_right_hand = false
        end
      end
    else
      @moving_right_hand = @input.keyboard.key_down.up
    end
  end

  def found_hole_left
    if !@moving_left_backward && @moving_left_hand
      play_sound_hit
      @moving_left_backward = true
      dir_x, dir_y = get_rot(@rot_left)

      @speed_y /= 3 if @speed_y.negative?

      @speed_x += dir_x * 1
      @speed_y += dir_y * 0.4
    end
  end

  def found_hole_right
    if !@moving_right_backward && @moving_right_hand
      play_sound_hit
      @moving_right_backward = true
      dir_x, dir_y = get_rot(@rot_right)

      @speed_y /= 3 if @speed_y.negative?

      @speed_x += dir_x * 1
      @speed_y += dir_y * 0.4
    end
  end

  def get_hand_left
    [@hand_left_pos_x, @hand_left_pos_y]
  end

  def get_hand_right
    [@hand_right_pos_x, @hand_right_pos_y]
  end
end
