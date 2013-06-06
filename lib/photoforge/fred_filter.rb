	module FredFilter

	def apply(script,file,filename)
		system "bash lib/fredscripts/#{script} #{file.path} public/temp/fred/#{filename}" 
		open('public/temp/fred/' + filename).read 
	end
end