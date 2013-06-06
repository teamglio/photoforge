class CreditTransactionType
	include DataMapper::Resource

	property :id, Serial
	property :description, Text

	has n, :credit_transactions
end