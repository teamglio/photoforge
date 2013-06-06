require 'carrierwave'
require 'carrierwave/datamapper'

class Storage < CarrierWave::Uploader::Base
	storage :fog
end