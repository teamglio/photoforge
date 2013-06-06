require 'mini_magick'

module Cocofilter

  def toaster(image)
  	image = MiniMagick::Image.read(image)
    image.modulate '150,80,100'
    image.gamma 1.1
    image.contrast
    image.contrast
    image.contrast
    image.contrast
    open(image.path).read
	end

	def lomo(image)
    image = MiniMagick::Image.read(image)
    image.channel 'R'
    image.level '22%'
    image.channel 'G'
    image.level '22%'
    open(image.path).read
	end	
	
	def kelvin(image)	
		image = MiniMagick::Image.read(image)
		cols, rows = image[:dimensions]
 
        image.combine_options do |command|
          command.auto_gamma
          command.modulate '120,50,100'
        end
 
        new_image = image.clone
        new_image.combine_options do |command|
          command.fill 'rgba(255,153,0,0.5)'
          command.draw "rectangle 0,0 #{cols},#{rows}"
        end
 
        image = image.composite new_image do |command|
          command.compose 'multiply'
        end
        open(image.path).read
    end

	def colortone(image, color = '#222b6d', level = 100, type = 0)
		image = MiniMagick::Image.read(image)
			
        
        color_image = image.clone
        color_image.combine_options do |command|
          command.fill color
          command.colorize '63%'
        end
 
        image = image.composite color_image do |command|
          command.compose 'blend'
          command.define "compose:args=#{level},#{100-level}"
        end
 
        open(image.path).read
    end    

	def gotham(image)
		image = MiniMagick::Image.read(image)
		
        image.modulate '120,10,100'
        image.fill '#222b6d'
        image.colorize 20
        image.gamma 0.5
        image.contrast
 
        open(image.path).read
    end

    #?
	def strip(image)
		img = MiniMagick::Image.read(image)
		
        image.strip 
 
        open(image.path).read
    end

    #?
    def quality(image, percentage=50)
    	img = MiniMagick::Image.read(image)

        img.quality(percentage)
 		
 		open(image.path).read
    end     

	#fix
    def vignette(image, path_to_file)
      img = MiniMagick::Image.read(image)  

  		cols, rows = img[:dimensions]

  		vignette_img = MiniMagick::Image.open(path_to_file)
  		vignette_img.resize "#{cols}x#{rows}"

  		img = img.composite(vignette_img) do |cmd|
  			cmd.gravity 'center'
  			cmd.compose 'multiply'
  		end

  		open(image.path).read

    end       

    #fix ?
	def pad_it_up(image,width=700, height=700, background='#FF0000', gravity='Center')

    img = MiniMagick::Image.read(image)

    cols, rows = img[:dimensions]
 
        if width > cols || height > rows
          img.combine_options do |cmd|
            if background == :transparent
              cmd.background "rgba(255, 255, 255, 0.0)"
            else
              cmd.background background
            end
            cmd.gravity gravity
            if width > cols && height > rows
              cmd.extent "#{width}x#{height}"
            elsif width > cols
              cmd.extent "#{width}x#{rows}"
            else
              cmd.extent "#{cols}x#{height}"
            end
          end
        end		

        open(image.path).read

    end 

end	