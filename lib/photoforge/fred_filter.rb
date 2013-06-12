	module FredFilter

	def apply(script,file,filename)
		
		begin
			system "bash lib/fredscripts/#{script} #{file.path} public/temp/fred/#{filename}"
			open('public/temp/fred/' + filename).read
		rescue

		end 	

	end

	def bordereffects(colour,file,filename)
		begin
			system "bash lib/fredscripts/bordereffects -b #{colour.to_s} #{file.path} public/temp/fred/#{filename}"
			open('public/temp/fred/' + filename).read
		rescue

		end
	end

	def bordergrid(colour,file,filename)
		begin
			system "bash lib/fredscripts/bordergrid -c #{colour.to_s} #{file.path} public/temp/fred/#{filename}"
			open('public/temp/fred/' + filename).read
		rescue

		end
	end	

end