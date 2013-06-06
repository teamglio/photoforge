require 'rest-client'

module Instafilter
	API_SECRET = 'pdsmkqltyuwn1za8ucpu8oiobrhccu'
	BASE_URL = 'https://thefosk-instafilterio.p.mashape.com'

	def black_and_white(image)
		RestClient.post BASE_URL + '/blackandwhite', {image: image}, {x_mashape_authorization: API_SECRET}
	end

	def colored_edge(image)
		RestClient.post BASE_URL + '/colorededge', {image: image}, {x_mashape_authorization: API_SECRET}
	end

	def edge_detection(image)
		RestClient.post BASE_URL + '/edge', {image: image}, {x_mashape_authorization: API_SECRET}
	end

	def gamma(image)
		RestClient.post BASE_URL + '/gamma', {image: image, gamma: 2}, {x_mashape_authorization: API_SECRET}
	end

	def invert(image)
		RestClient.post BASE_URL + '/invert', {image: image}, {x_mashape_authorization: API_SECRET}
	end

	def mosaic(image)
		RestClient.post BASE_URL + '/mosaic', {image: image, size: 10}, {x_mashape_authorization: API_SECRET}
	end	

	def noise(image)
		RestClient.post BASE_URL + '/noise', {image: image, amount: 50, density: 1, distribution: 'uniform', monochrome: true}, {x_mashape_authorization: API_SECRET}
	end

	def oil(image)
		RestClient.post BASE_URL + '/oil', {image: image, amount: 6}, {x_mashape_authorization: API_SECRET}
	end

	def padding(image, color)
		RestClient.post BASE_URL + '/padding', {image: image, padding: 20, color: color}, {x_mashape_authorization: API_SECRET}
	end	
	
end