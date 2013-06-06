class MxitAPI

	def self.get_app_token(scope)
		response = RestClient.post 'https://auth.mxit.com/token', {:grant_type => 'client_credentials', :scope => URI.encode(scope)}, {:content_type => 'application/x-www-form-urlencoded', :authorization => 'Basic ' + Base64.encode64(ENV['MXIT_KEY'] + ':' + ENV['MXIT_SECRET']).to_s.gsub!("\n","")}
		JSON.load(response)['access_token']
	end

	def self.request_access(scope, redirect_url)
		'https://auth.mxit.com/authorize?response_type=code&client_id=' + ENV['MXIT_KEY'] + '&redirect_uri=' + URI.encode(redirect_url) + '&scope=' + URI.encode(scope) + '&state=your_state'
	end

	def self.get_user_token(code, scope, redirect_url)
		response = RestClient.post 'https://auth.mxit.com/token', {:grant_type => 'authorization_code', :code => URI.encode(code), :redirect_uri => URI.encode(redirect_url)}, {:content_type => 'application/x-www-form-urlencoded', :authorization => 'Basic ' + Base64.encode64(ENV['MXIT_KEY'] + ':' + ENV['MXIT_SECRET']).to_s.gsub!("\n","")}
		JSON.load(response)['access_token']
	end

	def self.get_user_profile(mxit_user_id)
		response = RestClient.get 'http://api.mxit.com/user/profile/' + mxit_user_id, :accept => 'application/json', :authorization => 'Bearer ' + get_app_token('profile/public') do |response, request, result|
			case response.code
			when 200
				JSON.load(response)
			else
				nil
			end
		end
	end

	def self.upload_gallery_image(mxit_user_id, folder, filename, file, code, redirect_url)
		response = RestClient.post 'http://api.mxit.com/user/media/file/' + URI.encode(folder) + '?fileName=' + filename, file, {:authorization => 'Bearer ' + get_user_token(code, 'content/write', redirect_url)}
	end

end