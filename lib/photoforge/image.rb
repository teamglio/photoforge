class Image
	include DataMapper::Resource

	property :id, Serial
	property :published, Boolean, :default  => false
	property :publish_date, DateTime, :default  => Time.now
	property :clean_judgements, Integer, :default  => 0
	property :dirty_judgements, Integer, :default  => 0
	property :moderated, Boolean, :default  => false
	property :accepted, Boolean, :default  => false
	property :last_activity_date, DateTime, :default  => Time.now
	property :hashtags, Text

	mount_uploader :image, Storage

	belongs_to :user
	has n, :likes

	def activity!
		self.update(:last_activity_date => Time.now)
	end

end