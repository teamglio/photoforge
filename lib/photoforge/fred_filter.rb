	module FredFilter

	def apply(script,file,filename)
		begin
			system "bash lib/fredscripts/#{script} #{file.path} public/temp/fred/#{filename}"
		rescue
			next
		end 
		open('public/temp/fred/' + filename).read 

	end
end