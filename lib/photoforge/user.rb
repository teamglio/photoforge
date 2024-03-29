class User
	include DataMapper::Resource

	property :id, Serial
	property :mxit_user_id, Text
	property :mxit_nickname, Text
	property :date_joined, DateTime
	property :credits, Integer
	property :reviewer, Boolean

	has n, :images
	has n, :credit_transactions
	has n, :filter_transactions
	has n, :likes

	def increase_credits(amount, credit_transaction_type)
		CreditTransaction.create(:date => Time.now, :amount => amount, :user => self, :credit_transaction_type => CreditTransactionType.first(:description => credit_transaction_type))
		self.credits += amount
		self.save
	end

	def decrease_credits(amount, credit_transaction_type)
		CreditTransaction.create(:date => Time.now, :amount => -amount, :user => self, :credit_transaction_type => CreditTransactionType.first(:description => credit_transaction_type))
		self.credits -= amount
		self.save
	end

end