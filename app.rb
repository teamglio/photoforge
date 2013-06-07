require 'sinatra'
require_relative 'lib/photoforge.rb'

enable :sessions

configure do
	CarrierWave.configure do |config|
	  config.fog_credentials = {
	    :provider               => 'AWS',                       
	    :aws_access_key_id      => ENV['AWS_KEY'],                     
	    :aws_secret_access_key  => ENV['AWS_SECRET']
	  }
	  config.fog_directory  = 'photoforge'
	  config.fog_public     = false                                   
	end

	AWS.config(
	  :access_key_id => ENV['AWS_KEY'],
	  :secret_access_key => ENV['AWS_SECRET']
	)		

	DataMapper.setup(:default, ENV['DATABASE_URL'])
	DataMapper.finalize
	DataMapper.auto_upgrade!

end

before do
	@mixup_ad = RestClient.get 'http://serve.mixup.hapnic.com/10742327'
end
	
get '/' do
	save_user unless get_user
	erb :home
end

#step 1: select image
get '/images/upload' do
	unless get_user.images.count > 30
		erb :upload
	else
		erb "Woops, your Forge is too full and can't take any more photos. Please <a href='/images'>remove some photos</a> first :)"
	end
end

#step2: upload image
post '/images' do
	filename = get_filename
	FileUtils.move(params['file'][:tempfile],'public/temp/unfiltered/' + filename, :force => true)
	session[:unfiltered_image] = filename
	erb :filters
end

#step3: apply filter
get '/images/filter/:filter' do
	filter = Filter.first(:name => params[:filter])

	if get_user.credits >= filter.cost

		filename = session[:unfiltered_image] 

		unfiltered_image = open('public/temp/unfiltered/' + filename, 'r')

		open('public/temp/filtered/' + filename, 'wb') do |file|

			case filter.name
			when 'toaster'
				file.write(filter.toaster(unfiltered_image))
			when 'lomo'
				file.write(filter.lomo(unfiltered_image))
			when 'kelvin'
				file.write(filter.kelvin(unfiltered_image))
			when 'gotham'
				file.write(filter.gotham(unfiltered_image))
			when 'text'
				if session[:text_top_text] && session[:text_bottom_text]
					file.write(filter.text(filename, unfiltered_image, session[:text_top_text], session[:text_bottom_text]))
					session[:text_top_text], session[:text_bottom_text] = nil
				else
					redirect to '/images/filter/text/top-text'
				end
			when 'supertext'
				if session[:supertext_top_text] && session[:supertext_middle_text] && session[:supertext_bottom_text] && session[:supertext_text_colour]
					file.write(filter.supertext(filename, unfiltered_image, session[:supertext_top_text], session[:supertext_middle_text], session[:supertext_bottom_text], session[:supertext_text_colour]))
					session[:supertext_top_text], session[:supertext_middle_text], session[:supertext_bottom_text], session[:supertext_text_colour] = nil					
				else
					redirect to '/images/filter/supertext/top-text'
				end
			when 'picasso'
				file.write(filter.oil(unfiltered_image))						
			when 'pattern-border'
				file.write(filter.apply('bordereffects',unfiltered_image,filename))
			when 'bevel-border'
				file.write(filter.apply('bevelborder',unfiltered_image,filename))
			when 'vignette'
				file.write(filter.apply('vignette3',unfiltered_image,filename))
			when 'vintage'
				file.write(filter.apply('vintage1',unfiltered_image,filename))
			when 'colour-border'
				if session[:colour_border_colour]
					file.write(filter.padding(unfiltered_image, '#' + session[:colour_border_colour]))
					session[:colour_border_colour] = nil
				else
					redirect to '/images/filter/colour-border/colour'
				end																					
			end
		end

		filtered_image = open('public/temp/filtered/' + filename, 'r')

		image = Image.create(:user_id => get_user.id,:image => filtered_image)

		get_user.decrease_credits(filter.cost,'filter')
		filter.record_usage(get_user)

		clean_up(filename)

		redirect to "/images/#{image.id}" 
	else
		erb "Oops, you're all out of credits! <a href ='/credits'>Get some more</a>!"
	end
end

get '/images/filter/text/top-text' do
	erb :text_top_text
end

post '/images/filter/text/top-text' do
	session[:text_top_text] = params[:text_top_text]
	redirect to '/images/filter/text/bottom-text'
end

get '/images/filter/text/bottom-text' do
	erb :text_bottom_text
end

post '/images/filter/text/bottom-text' do
	session[:text_bottom_text] = params[:text_bottom_text]
	redirect to '/images/filter/text'
end

get '/images/filter/supertext/top-text' do
	erb :supertext_top_text
end

post '/images/filter/supertext/top-text' do
	session[:supertext_top_text] = params[:supertext_top_text]
	redirect to '/images/filter/supertext/middle-text'
end

get '/images/filter/supertext/middle-text' do
	erb :supertext_middle_text
end

post '/images/filter/supertext/middle-text' do
	session[:supertext_middle_text] = params[:supertext_middle_text]
	redirect to '/images/filter/supertext/bottom-text'
end

get '/images/filter/supertext/bottom-text' do
	erb :supertext_bottom_text
end

post '/images/filter/supertext/bottom-text' do
	session[:supertext_bottom_text] = params[:supertext_bottom_text]
	erb :supertext_text_colour
end

get '/images/filter/supertext/text-colour' do
	session[:supertext_text_colour] = params[:colour]
	redirect to '/images/filter/supertext'
end

get '/images/filter/colour-border/colour' do
	erb :colour_border_colour
end

get '/images/filter/colour-border/colour-chosen' do
	session[:colour_border_colour] = params[:colour]
	redirect to '/images/filter/colour-border'
end

get '/images/:image_id' do
	@image = Image.first(:id => params[:image_id].to_i)
	erb :image
end

get '/images' do
	@images = get_user.images.all(:order => [ :id.desc ])
	erb :images
end

get '/allimages' do
	protected!
	@images = Image.all
	erb :images
end

get '/images/save/confirm/:image_id' do
	redirect to MxitAPI.request_access('content/write', "http://#{request.host}:#{request.port}/images/save/#{params[:image_id].to_s}")
end

get '/images/save/:image_id' do
	filename = get_filename
	FileUtils.move(open(Image.get(params[:image_id].to_i).image.url), 'public/temp/to_save/' + filename, :force => true)
	file = open('public/temp/to_save/' + filename)
	MxitAPI.upload_gallery_image(get_user.mxit_user_id,'PhotoForge', filename, file , params[:code],"http://#{request.host}:#{request.port}/images/save/#{params[:image_id].to_s}")
	clean_up(filename)
	erb "<div><p>Your image has been saved to your Mxit Gallery! <a href='/images'>Ok</a></p></div>"
end

get '/images/delete/confirm/:image_id' do
	erb "<div><p>Are you sure you want to delete this image? <a href='<%= url '/images/delete/' + params[:image_id] %>'>Yes</a> | <a href='<%= url '/images' %>'>No</a></p></div>"
end

get '/images/delete/:image_id' do
	Image.get(params[:image_id].to_i).destroy
	redirect to '/images'
end

get '/credits' do
	erb :credits
end

get '/credits-bought' do

	case params[:mxit_transaction_res]
	when '0'
		get_user.increase_credits(params[:amount].to_i,'credits')
		erb "Thanks, you've been recharged with #{params[:amount]} credits!"
	when '1'
		redirect to '/'
	else
		erb "Oops, something went wrong. <a href='/credits'>Try again</a>"	 
	end
end

get '/fred/:year/:month' do
	@start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
	@end_date = Date.new(params[:year].to_i, params[:month].to_i + 1, -1)
	@filters = Filter.all(:filter_provider => FilterProvider.first(:name => 'fred'))
	erb :fred

end

get '/help' do
	erb :help
end

get '/feedback' do
	erb :feedback
end

post '/feedback' do
	user = get_user
	ses = AWS::SimpleEmailService.new
	ses.send_email(
	  :subject => 'PhotoForge feedback',
	  :from => 'mxitappfeedback@glio.co.za',
	  :to => 'mxitappfeedback@glio.co.za',
	  :body_text => params['feedback'] + ' - ' + user.mxit_user_id
	  )
	erb "Thanks! <a href='/'>Back</a>" 
end

helpers do
	def get_user
		mxit_user = MxitUser.new(request.env)
		User.first(:mxit_user_id => mxit_user.user_id)
	end
	def save_user
		mxit_user = MxitUser.new(request.env)
		User.create(:mxit_user_id => mxit_user.user_id, :credits => 0)
	end
	def get_filename
		get_user.mxit_user_id + '-' + Time.now.day.to_s + Time.now.month.to_s + Time.now.day.to_s + Time.now.hour.to_s + Time.now.min.to_s + Time.now.sec.to_s + '.jpg'
	end
	def has_credits(filter)
		get_user.credits >= filter.cost
	end
	def clean_up(filename)
		FileUtils.remove("public/temp/unfiltered/#{filename}", :force => true)
		FileUtils.remove("public/temp/filtered/#{filename}", :force => true)
		FileUtils.remove("public/temp/fred/#{filename}", :force => true)
		FileUtils.remove("public/temp/memecaptain/#{filename}", :force => true)
		FileUtils.remove("public/temp/to_save/#{filename}", :force => true)
	end
	def get_moola_transaction_reference
		get_user.mxit_user_id + Time.now.day.to_s + Time.now.month.to_s + Time.now.day.to_s + Time.now.hour.to_s + Time.now.min.to_s + Time.now.sec.to_s
	end
	def protected!
	    unless authorized?
	      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
	      throw(:halt, [401, "Not authorized\n"])
	    end
  	end
  	def authorized?
	    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
	    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', ENV['USER_SECRET']]
  	end
end

get '/stats' do
	protected!
	@user_count = User.all.count
	@sum = 0
	CreditTransaction.all(:credit_transaction_type => CreditTransactionType.get(1)).all.each do |transaction|
	 	@sum += transaction.amount
	end
	@credits_bought = @sum
	erb "Users: #{@user_count} <br /> Credits bought: #{@credits_bought}"
end