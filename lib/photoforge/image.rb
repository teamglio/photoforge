class Image
	include DataMapper::Resource

	property :id, Serial
	mount_uploader :image, Storage

	belongs_to :user

end