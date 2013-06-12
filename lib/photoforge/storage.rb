require 'carrierwave'
require 'carrierwave/datamapper'
require 'carrierwave-processing'

class Storage < CarrierWave::Uploader::Base
	include CarrierWave::RMagick
 	include CarrierWave::Processing::RMagick
 	process :quality => 50

	storage :fog
end