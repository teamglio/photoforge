	module FredFilter

	def apply(script,file,filename)
		
		begin
			system "bash lib/fredscripts/#{script} #{file.path} public/temp/fred/#{filename}"
			open('public/temp/fred/' + filename).read
		rescue

		end 	

	end
end