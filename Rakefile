require_relative 'app.rb'
require 'stathat'
require 'firebase'

desc "Populates database with default data"
task :generate_default_data do
	puts "Generating default data..."
	
	CreditTransactionType.create(:description => "credits")
	CreditTransactionType.create(:description => "filter")
	CreditTransactionType.create(:description => "testing")

	FilterProvider.create(:name => 'cocofilter')
	FilterProvider.create(:name => 'instafilter')
	FilterProvider.create(:name => 'memecaptain')
	FilterProvider.create(:name => 'fred')

	Filter.create(:name => "text", :description => "Add basic top and bottom text to your image.", :example_url => 'examples/text.jpg', :cost => 0, :filter_provider => FilterProvider.first(:name => 'memecaptain'))
	Filter.create(:name => "supertext", :description => "Add top, middle and bottom text to your image and choose what colour the text must be.", :example_url => 'examples/supertext.jpg', :cost => 15, :filter_provider => FilterProvider.first(:name => 'memecaptain'))	
	Filter.create(:name => "toaster", :description => "Toast it!", :example_url => 'examples/toaster.jpg', :cost => 0, :filter_provider => FilterProvider.first(:name => 'cocofilter'))
	Filter.create(:name => "lomo", :description => "Lomocotive!", :example_url => 'examples/lomo.jpg', :cost => 0, :filter_provider => FilterProvider.first(:name => 'cocofilter'))
	Filter.create(:name => "kelvin", :description => "Lord Kelvin maketh it yellowish.", :example_url => 'examples/kelvin.jpg', :cost => 0, :filter_provider => FilterProvider.first(:name => 'cocofilter'))
	Filter.create(:name => "gotham", :description => "Oppa Gotham-style!", :example_url => 'examples/gotham.jpg', :cost => 0, :filter_provider => FilterProvider.first(:name => 'cocofilter'))
	Filter.create(:name => "picasso", :description => "Turn your photo into an oil painting!", :example_url => 'examples/picasso.jpg', :cost => 15, :filter_provider => FilterProvider.first(:name => 'instafilter'))
	Filter.create(:name => "bevel-border", :description => "Add a bevel border to your photo!", :example_url => 'examples/bevel-border.jpg', :cost => 25, :filter_provider => FilterProvider.first(:name => 'fred'))
	Filter.create(:name => "pattern-border", :description => "Add a pattern border to your photo!", :example_url => 'examples/pattern-border.jpg', :cost => 25, :filter_provider => FilterProvider.first(:name => 'fred'))				
	Filter.create(:name => "vignette", :description => "Look like a real hipster with this vignette filter!", :example_url => 'examples/vignette.jpg', :cost => 25, :filter_provider => FilterProvider.first(:name => 'fred'))
	Filter.create(:name => "vintage", :description => "Make your photos look classy with Vintage.", :example_url => 'examples/vintage.jpg', :cost => 25, :filter_provider => FilterProvider.first(:name => 'fred'))
	Filter.create(:name => "colour-border", :description => "Add a coloured border to your photo!", :example_url => 'examples/colour-border.jpg', :cost => 15, :filter_provider => FilterProvider.first(:name => 'instafilter'))

	puts "Done generating default data"
end

desc "Send stats to StatHat"
task :send_stats do
	puts "Sending stats..."
	StatHat::API.ez_post_value("photoforge - users", "emile@silvis.co.za", User.all.count)
	StatHat::API.ez_post_value("photoforge - images", "emile@silvis.co.za", Image.all.count)
	StatHat::API.ez_post_value("photoforge - images-to-user ratio", "emile@silvis.co.za", (Image.all.count / User.all.count.to_f))
	sum = 0
	CreditTransaction.all(:credit_transaction_type => CreditTransactionType.get(1)).all.each do |transaction|
	 	sum += transaction.amount
	end
	StatHat::API.ez_post_value("photoforge - credits bought", "emile@silvis.co.za", sum)
	puts "Done."
end

desc "Export user Mxit IDs to CSV"
task :user_mxit_ids_csv do
	puts "Exporting..."
	File.open('public/users.csv', 'w') {|file| file.write(User.all.to_csv(:only => :mxit_user_id))}
	puts "Done"
end