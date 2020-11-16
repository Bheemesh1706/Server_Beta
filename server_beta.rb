require 'socket'
require 'erb'
	

	if ( (ARGV[0].to_i.is_a? (Integer ) )&&  (ARGV[0].to_i >= 8000) )
        	server = TCPServer.new('localhost',ARGV[0])
		puts ""
		puts "localhost is running on port: #{ARGV[0]} \n\n"
	else
		server = TCPServer.new('localhost',3000)
		puts ""
		puts "localhost is running on default port: 3000 \n\n"

	end




# Class for parsing the request
class Server_Request


	def parse(request)
		method, path, version = request.lines[0].split
		request_val={ path: path,method: method,version: version,headers: prase_header(request)}

	end

	def normalize(header)
		header.gsub!(":","").downcase!.to_sym	
	end

	def prase_header(request)
		
		headers={}

		request.lines[1..-1].each do |line|
			next if line =="\r\n"

			header,value = line.split()
			header = normalize(header)

			headers[header]=value
		end
	
		headers

	end

end


#Class for preparing the response
class Server_Response
		
	SERVER_ROOT = Dir.pwd	

	attr_accessor :path

	def initialize
		@path
		@template
	end

	def prepare_response(request)
	 			

		if request.fetch(:path) == "/"
			@path = SERVER_ROOT
		else 
			@path = request.fetch(:path)
		end


		if Dir.exist?(@path)
			@template = Template.new(@path)
			@template.render_template(@template.get_template())

			respond_with(SERVER_ROOT+"/Server_Beta.html")
		else 
			
			respond_with(@path)
		end

	end

	def respond_with(path)

		if File.exist?(path) && Dir.exist?(path) == false 
			send_ok_response(File.binread(path))
			
		else
			send_file_not_found
		end
	end

	def send_ok_response(data)
		Response.new( code: 200, data: data , type: file_type(@path) )
	end

	def send_file_not_found
		Response.new(code: 404)
	end

	def file_type(path)
		if Dir.exist?(path) || File.extname(path) == ".html" #need to change this a regrex 
			return "text/html"
		else
			return "text/plain"
		end

	end


end

# Class to send the response to the server
#
class Response
        attr_reader :code

        def initialize(code:, data:"", type:"")
                @response = "HTTP/1.1 #{code}\r\n" + "Content-Length: #{data.size}\r\n"+ "Content-Type: #{type}\r\n" +"\r\n"+"#{data}\r\n"
		puts @response
		@code= code
        end

        def send(client)
                client.write(@response)
        end
end

class Template 
	
#	attr_reader :list
	
	attr_accessor :path , :list
	
	def initialize(path)
		@path=path
		@list=`ls -A #{@path}`.split()
	end

	def get_template()
		temp = %{ <html>
                        <head>
                                <h1> Directory: <%= @path %> </h1>
                        </head>
                        <body>
                                <hr>
                                        <ul>
						<%  @list.each do |val|  %>
								<li> <a href="<%= @path %>/<%= val %>"> <%= val %> </a>
                                                <% end %>
                                        </ul>

                                <hr>
                        </body>
                  </html>  }

		  temp
	end

	def render_template(template)

		render = ERB.new(template)
		
		file = File.open("Server_Beta.html","w")

		file.write("Server_Beta.html",render.result(binding))

		file.close

	end


end



loop {
	`touch Server_Beta.html`
 

	begin

		  #Creating objects for handling server response and request
			noob = Server_Request.new;
			boon = Server_Response.new;

 	 	#Initiating the server
			client = server.accept
  		#Recieveing the http  request   
			request = client.readpartial(2048) #need to deal with exception
 	 	#Parsing the request and preparing the response for the request
			request = noob.parse(request)
	

			response= boon.prepare_response(request)

	
			puts "#{client.peeraddr[3]} #{request.fetch(:path)} - #{response.code}"
  
			response.send(client)

	rescue StandardError => e  

			client.write(e.message)
  
			client.close
	end

	`rm Server_Beta.html`
}


