require 'meme_captain'

module MemeCaptainFilter
	def text(filename, image,top_text, bottom_text)
		open(image, 'rb') do |file|
			meme_captain = MemeCaptain.meme(file, [
			    MemeCaptain::TextPos.new(top_text, 0.1, 0.05, 0.8, 0.3),
			    MemeCaptain::TextPos.new(bottom_text, 0.1, 0.7, 0.8, 0.3)
			    ])
			meme_captain.write('public/temp/memecaptain/' + filename)
		end
		open('public/temp/memecaptain/' + filename).read
	end

	def supertext(filename, image,top_text, middle_text, bottom_text, text_colour)
		open(image, 'rb') do |file|
			meme_captain = MemeCaptain.meme(file, [
			    MemeCaptain::TextPos.new(top_text, 0.1, 0.05, 0.8, 0.2, :fill => text_colour),
			    MemeCaptain::TextPos.new(middle_text, 0.1, 0.4, 0.8, 0.2, :fill => text_colour),
			    MemeCaptain::TextPos.new(bottom_text, 0.1, 0.7, 0.8, 0.2, :fill => text_colour)
			    ])
			meme_captain.write('public/temp/memecaptain/' + filename)
		end
		open('public/temp/memecaptain/' + filename).read
	end	
end