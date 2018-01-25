#!/usr/bin/ruby

# This program is written by Takeda from 21Jan2018 to 25Jan2018
# New

require "curses"

Element = Struct.new(:x, :y, :char)

class Base

	def initialize(center_x, center_y)
		@center_x = center_x
		@center_y = center_y
	end

	def move(center_x, center_y)
		@center_x = center_x
		@center_y = center_y
	end

	def inc_x
		@center_x += 1
	end
	
	def dec_x
		@center_x -= 1
	end

	def inc_y
		@center_y += 1
	end

	def dec_y
		@center_y -= 1
	end

	attr_reader :center_x
	attr_reader :center_y
end

class Bee < Base # Class to make behavior of bee

	@@seed = 0 # Make difference of behavior between each bee

	def initialize(center_x, center_y, r)
		super(center_x, center_y)
		@t = 0.25*Math::PI # 0.25PI means 45deg
		@r = r
		@x = center_x # This is for the case when get_elements() is called before go_next_pos()
		@y = center_y # This is for the case when get_elements() is called before go_next_pos()
		@is_clockwise = true
		@@seed += 1 # All instances of this class should have different seed.
		@random = Random.new(@@seed)
	end

	def go_next_pos
		if(@t > 2.25*Math::PI) then # 2.25PI means (360+45)deg
			@t = 0.25*Math::PI # 0.25 means 45deg
			if(@is_clockwise) then # Reverse rotational direction
				@is_clockwise = false
			else
				@is_clockwise = true
			end
		end

		delta_t = 0.01
		@t += delta_t * (2 ** @random.rand(1..5)) # Randomize rotation of step
		coef = 1.0/Math::sqrt(2)

		if(@is_clockwise) then
			@x = @center_x - @r*coef + @r*Math::cos(@t)
			@y = @center_y - @r*coef + @r*Math::sin(@t)
		else
			@x = @center_x + @r*coef + @r*Math::cos(@t+0.5*Math::PI) # 0.5PI means 90deg
			@y = @center_y + @r*coef - @r*Math::sin(@t+0.5*Math::PI) # 0.5PI means 90deg
		end
	end

	def go_towards(target)
		step = 0.1

		if(target.center_x - @center_x > step) then # Move bee's horizontal position to the target.
			@center_x += step
		elsif(target.center_x - @center_x < step)
			@center_x -= step
		end
		if(target.center_y - @center_y > step) then # Move bee's vertical position to the target.
			@center_y += step
		elsif(target.center_y - @center_y < step)
			@center_y -= step
		end
	end

	def get_elements
		return [Element.new(@x, @y, '8')]
	end
end

class Target < Base

	def initialize(center_x, center_y)
		super(center_x, center_y)
	end

	def get_elements

		#  _
		# O_O
		#O_O_O
		# O_O

		return [
			Element.new(@center_x  , @center_y-2, '_'), # L1
			Element.new(@center_x-1, @center_y-1, 'O'), # L2
			Element.new(@center_x  , @center_y-1, '_'), # L2
			Element.new(@center_x+1, @center_y-1, 'O'), # L2
			Element.new(@center_x-2, @center_y  , 'O'), # L3
			Element.new(@center_x-1, @center_y  , '_'), # L3
			Element.new(@center_x  , @center_y  , 'O'), # L3
			Element.new(@center_x+1, @center_y  , '_'), # L3
			Element.new(@center_x+2, @center_y  , 'O'), # L3
			Element.new(@center_x-1, @center_y+1, 'O'), # L4
			Element.new(@center_x  , @center_y+1, '_'), # L4
			Element.new(@center_x+1, @center_y+1, 'O')  # L4
		]
	end
end

begin # This block is for drawing with Curses class
	Curses.init_screen
	Curses.crmode
	Curses.noecho
	Curses.stdscr.nodelay = true # getch becomes non-blocking mode
	Curses.curs_set(0) # Make cursor invisible

	ch = 0 # Save key input
	m_curses_ch = Mutex.new
	bees = []
	bees << Bee.new(10, 10, 10)
	bees << Bee.new(40,  5,  3)
	bees << Bee.new(35, 30,  8)
	target = Target.new(40, 20)

	# Make thread to get key input
	keyinput_thread = Thread.new do
		loop do
			m_curses_ch.synchronize{
				ch = Curses.getch
			}
			sleep(0.1)
		end
	end

	catch(:quit){
		while(1) do
			elements = target.get_elements
			bees.each{ |b|
				b.go_towards(target)
				b.go_next_pos
				elements += b.get_elements
			}

			m_curses_ch.synchronize{
				Curses.erase
				elements.each{ |e|
					if(e.x >= 0 && e.x <= (Curses.cols-1) && e.y >= 0 && e.y <= (Curses.lines-1)) then # Draw when x,y are within range
						Curses.setpos(e.y, e.x)
						Curses.addstr(e.char)
					end
				}

				case ch
				when 'q' then
					throw :quit
				when 'k' then # go UP
					target.dec_y
				when 'j' then # go DOWN
					target.inc_y
				when 'l' then # go RIGHT
					target.inc_x
				when 'h' then # go LEFT
					target.dec_x
				end
				ch = 'a'

				# Show usage of this program
				Curses.setpos(0, 0)
				Curses.addstr("q       : Quit Program")
				Curses.setpos(1, 0)
				Curses.addstr("h,j,k,l : Move Nest")
				Curses.refresh
			} # End of m_curses_ch.synchronize
			sleep(0.02)
		end
	} # End of :quit
ensure # Catch exception of Curses class
	Curses.close_screen
end
					
	



















