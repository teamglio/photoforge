require 'sinatra'
require 'stathat'
require_relative 'lib/photoforge.rb'

enable :sessions

configure do
	Dotenv.load if settings.development?
	CarrierWave.configure do |config|
		config.fog_credentials = {
			:provider               => 'AWS',                       
			:aws_access_key_id      => ENV['AWS_KEY'],                     
			:aws_secret_access_key  => ENV['AWS_SECRET']
		}
		config.fog_directory = 'photoforge'
		config.fog_public = false                                   
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
	create_user unless get_user
	update_nickname
	erb :home
end

##New

#Step 1: select image
get '/images/upload' do
	unless get_user.images.count > 20
		StatHat::API.ez_post_value("photoforge - images uploaded", "emile@silvis.co.za", 1)
		erb :upload
	else
		erb "Woops, your Forge is too full (it can only take 20 photos). Please <a href='/images'>remove some photos</a> first :)"
	end
end

#Step2: upload image
post '/images' do
	filename = get_filename
	FileUtils.move(params['file'][:tempfile],'public/temp/unfiltered/' + filename, :force => true)
	session[:unfiltered_image] = filename
	erb :filters
end

#Step3: apply filter
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
				if session[:pattern_border_colour]
					file.write(filter.bordereffects(session[:pattern_border_colour],unfiltered_image,filename))
					session[:pattern_border_colour] = nil					
				else
					redirect to '/images/filter/pattern-border/colour'
				end			
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
			when 'grid-border'
				if session[:grid_border_colour]
					file.write(filter.bordergrid(session[:grid_border_colour],unfiltered_image,filename))
					session[:grid_border_colour] = nil					
				else
					redirect to '/images/filter/grid-border/colour'
				end																										
			end
		end

		filtered_image = open('public/temp/filtered/' + filename, 'r')

		image = Image.create(:user_id => get_user.id,:image => filtered_image)

		get_user.decrease_credits(filter.cost,'filter')
		filter.record_usage(get_user)

		clean_up(filename)


		redirect to "/images/hashtags/new?image_id=#{image.id}"
	else
		erb "Oops, you're all out of credits! <a href ='/credits'>Get some more</a>!"
	end
end

#Step4: Add hashtags
get '/images/hashtags/new' do
	erb :hashtags
end

post '/images/hashtags' do
	Image.first(:id => params[:image_id].to_i).update(:hashtags => params[:hashtags].gsub('#', ''))
	redirect to "/images/#{params[:image_id]}"
end
#---

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

get '/images/filter/pattern-border/colour' do
	erb :pattern_border_colour
end

get '/images/filter/pattern-border/colour-chosen' do
	session[:pattern_border_colour] = params[:colour]
	redirect to '/images/filter/pattern-border'
end

get '/images/filter/grid-border/colour' do
	erb :grid_border_colour
end

get '/images/filter/grid-border/colour-chosen' do
	session[:grid_border_colour] = params[:colour]
	redirect to '/images/filter/grid-border'
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
	@images = Image.all(:order => [ :id.desc ])
	erb :images
end

get '/images/publish/:image_id' do
	if get_user.credits >= 5	

		image = Image.first(:id => params[:image_id].to_i)	
		image.update(:published => true)
		image.update(:publish_date => Time.now)
		ses = AWS::SimpleEmailService.new
		ses.send_email(
		  :subject => 'PhotoForge Publish',
		  :from => 'mxit@glio.co.za',
		  :to => 'mxit@glio.co.za',
		  :body_text => 'Someone published a photo - http://photoforge.herokuapp.com/administration-queue'
		  )

		get_user.decrease_credits(5,'publish')

		erb "Your image will appear in the Stream once reviewed. <a href='/stream'>Ok</a>"
	else
		erb "Oops, you're all out of credits! <a href ='/credits'>Get some more</a>!"
	end
end

get '/images/like/:image_id' do
	if get_user.credits >= 1
		image = Image.get(params[:image_id].to_i)	
		unless Like.first(:user => get_user, :image => image)
			Like.create(:user => get_user, :image => image, :date => Time.now)
			image.activity!
			get_user.decrease_credits(1,'like')
			redirect to '/stream'
		else
			erb "You've already liked this photo :) <a href='/stream'>Back</a>"
		end
	else
		erb "Oops, you're all out of credits! <a href ='/credits'>Get some more</a>!"
	end
end

get '/administration-queue' do
	protected!
	@images = Image.all(:published => true, :moderated => false, :order => [ :publish_date.asc ])
	erb :administration_queue
end

get '/images/administer/:image_id' do
	image = Image.first(:id => params[:image_id].to_i)

	image.update(:moderated => true)

	if params[:result] == 'accept'
		image.update(:accepted => true)	
	elsif params[:result] == 'reject'	
		image.update(:accepted => false)			
	end

	image.activity!

	redirect to 'administration-queue'	
end

get '/moderation-queue' do
  	session[:last_moderated].nil? ? session[:last_moderated] = [] : session[:last_moderated]

  	last_moderated_images = []
  	session[:last_moderated].each do |last_moderated|
  		last_moderated_images.push(Image.get(last_moderated))
  	end

  	@image = Image.all(:published => true, :moderated => false).sample(1).first

  	unless last_moderated_images.include?(@image) || @image.nil?
		erb :moderation_queue
	else
		erb "Queue empty! :) Please <a href='/moderation-queue'>try again</a> in few minutes."
	end
end

get '/images/moderate/:image_id' do
	image = Image.first(:id => params[:image_id].to_i)

	if params[:result] == 'accept'
		image.update(:clean_judgements => image.clean_judgements + 1)

	elsif params[:result] == 'reject'
		image.update(:dirty_judgements => image.dirty_judgements + 1)
	end

	if image.clean_judgements + image.dirty_judgements == 3
		image.update(:moderated => true)
		if image.clean_judgements == 3
			image.update(:accepted => true)
		else
			image.update(:accepted => false)
		end
	end

	session[:last_moderated].push(image.id)

	image.activity!

	redirect to 'moderation-queue'	
end

get '/stream' do
	@images = Image.all(:order => [:last_activity_date.desc], :accepted => true).paginate(:page => params[:page], :per_page => 5)
	erb :stream
end

get '/searchbox' do
	erb :search
end

post '/search' do
	@query = params[:q].gsub('#','').split.first
	@images = Image.all(:order => [:last_activity_date.desc], :accepted => true, :hashtags => Regexp.new(@query)).paginate(:page => params[:page], :per_page => 5)
	erb :searchstream
end


get '/images/save/confirm/:image_id' do
	if get_user.credits >= 5
		redirect to MxitAPI.request_access('content/write', "http://#{request.host}:#{request.port}/images/save/#{params[:image_id].to_s}")
	else
		erb "Oops, you're all out of credits! <a href ='/credits'>Get some more</a>!"
	end		
end

get '/images/save/:image_id' do
	if get_user.credits >= 5
		unless params[:error]

			filename = get_filename

			File.open('public/temp/to_save/' + filename, 'wb') do |file|
				file.write(Image.get(params[:image_id].to_i).image.file.read)
			end

			file = open('public/temp/to_save/' + filename)

			MxitAPI.upload_gallery_image(get_user.mxit_user_id,'PhotoForge', filename, file , params[:code],"http://#{request.host}:#{request.port}/images/save/#{params[:image_id].to_s}")
			
			get_user.decrease_credits(5,'save')

			clean_up(filename)

			erb "<div><p>Your image has been saved to your Mxit Gallery! <a href='/images'>Ok</a></p></div>"
		else
			redirect to '/images'
		end
	else
		erb "Oops, you're all out of credits! <a href ='/credits'>Get some more</a>!"
	end
end

get '/images/delete/confirm/:image_id' do
	erb "<div><p>Are you sure you want to delete this image? <a href='<%= url '/images/delete/' + params[:image_id] %>'>Yes</a> | <a href='<%= url '/images' %>'>No</a></p></div>"
end

get '/images/delete/:image_id' do
	image = Image.get(params[:image_id].to_i)
	unless image.likes.size > 0
		image.destroy
	else
		image.likes.destroy
		image.destroy
	end
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
	def create_user
		mxit_user = MxitUser.new(request.env)
		User.create(:mxit_user_id => mxit_user.user_id, :mxit_nickname => mxit_user.nickname, :date_joined => Time.now,:credits => 0)
	end
	def update_nickname
		mxit_user = MxitUser.new(request.env)
		User.first(:mxit_user_id => mxit_user.user_id).update(:mxit_nickname => mxit_user.nickname)
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
	@image_count = Image.all.count
	@sum = 0
	CreditTransaction.all(:credit_transaction_type => CreditTransactionType.get(1)).all.each do |transaction|
	 	@sum += transaction.amount
	end
	@credits_bought = @sum
	erb "Users: #{@user_count} <br /> Images: #{@image_count} <br />Image-to-user ratio: #{@image_count / @user_count.to_f} <br /> Credits bought: #{@credits_bought} (R #{@credits_bought/100})"
end