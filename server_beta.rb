require 'socket'
require 'erb'

        server = TCPServer.new('localhost',3000)

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
	end

	def prepare_response(request)
		
		@path = request.fetch(:path)
	   
		if @path == "/"
			respond_with(SERVER_ROOT+"INDEX.html")
		else 
			respond_with(SERVER_ROOT+@path)
		end
	end

	def respond_with(path)

		if File.exist?(path)
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

		if Dir.exist?(path) || File.extname(path) == ".html"
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
                @code= code
        end

        def send(client)
                client.write(@response)
        end
end


loop {
 
  #Getting the list of the present directory
	list = `ls`
	list = list.split() 

  #Creating objects for handling server response and request
	noob = Server_Request.new;
	boon = Server_Response.new;

  #Initiating the server
	client = server.accept

  #Generating Template to display the list
	        temp = %{ <html>
                        <head>
				<h1> Directory: <%= Dir.pwd %> </h1>
                        </head>
			<body>
				<hr>
			
					<ul>
						<li> <a href="server.rb"> server.rb</a>
					</ul>

				<hr>
			</body>
                  </html>  }

        render = ERB.new(temp)

  #Storing the tmeplate file in a html file to show the result
 	file = File.open("INDEX.html","w")

	file.write("INDEX.html",render.result())

	file.close

  #Recieveing the http  request   
	request = client.readpartial(2048)

  #Parsing the request and preparing the response for the request
	request = noob.parse(request)

	response= boon.prepare_response(request)


	puts "#{client.peeraddr[3]} #{request.fetch(:path)} - #{response.code}"

  
	response.send(client)
  
	client.close


}


