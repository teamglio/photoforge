class Like
	include DataMapper::Resource

	property :id, Serial
	property :date, DateTime
	
	belongs_to :user
	belongs_to :image

end