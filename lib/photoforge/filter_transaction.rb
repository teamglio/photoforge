class FilterTransaction
	include DataMapper::Resource

	property :id, Serial
	property :date, DateTime
	property :amount, Integer

	belongs_to :user
	belongs_to :filter

end