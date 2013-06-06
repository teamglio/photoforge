class FilterProvider
	include DataMapper::Resource

	property :id, Serial
	property :name, Text

	has n, :filters
end