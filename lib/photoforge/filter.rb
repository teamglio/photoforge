class Filter
	include DataMapper::Resource
	include Cocofilter
	include Instafilter 
	include MemeCaptainFilter
	include FredFilter  

	property :id, Serial
	property :name, Text
	property :description, Text
	property :cost, Integer
	property :example_url, Text
	property :active, Boolean

	belongs_to :filter_provider
	has n, :filter_transactions

	def record_usage(user)
		FilterTransaction.create(:filter => self, :user => user, :date => Time.now, :amount => self.cost)
	end
end