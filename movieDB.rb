require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'do_postgres'
require 'haml'
require 'lib/authorization'
require 'yaml'
require 'open-uri'
$API_KEY = "3cbb4446ab38deb3541b672b248efbf0"
	
class Actor
	include DataMapper::Resource
	property :name,	String, :key => true
	property :age,	Integer
	has n, :casts
	has n, :movies, :through => :casts
end
class Movie
	include DataMapper::Resource
	property :title, String, :key => true
	property :release_year, Integer
	property :length, Integer
	property :plot, Text
	property :mpaa_rating, String
	belongs_to :director
	has n, :casts
	has n, :actors, :through => :casts
end
class Director
	include DataMapper::Resource
	property :name, String, :key => true
	property :age,	Integer
	has n, :movies
end
class Cast
	include DataMapper::Resource
	property :id, Serial
	belongs_to :movie
	belongs_to :actor
end

DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/movieDB.db")
DataMapper.auto_upgrade!
before do headers "Content-Type" => "text/html; charset=utf-8" end

get '/' do haml :index end
post '/search' do haml :search end
post '/autofill' do haml :autofill end
	
post '/addMovie' do
	redirect '/autofill' if params[:submit] == 'autofill'
	require_admin
	params[:title].strip!
	halt(400, "Invalid Movie Title") if (params[:title]=="")
	halt(400, "Invalid Director Name") if (params[:director_name]=="")	
	movie = Movie.new(:title => params[:title], :release_year => params[:release_year].to_i, :length => params[:length].to_i, :mpaa_rating => params[:mpaa_rating], :plot => params[:plot].gsub("\r\n","<br />"))
	params[:cast].split(/[ ]?,[ ]?/).each do |name|
		actor = Actor.get(name)
		actor = Actor.new( :name => name, :age => 0) if (actor.nil?)
		movie.actors << actor
	end
	movie.save
	director = Director.get(params[:director_name])
	director = Director.new(:name => params[:director_name], :age => 0) if director.nil?
	director.movies << movie 
	director.save
	redirect '/movie/'+movie.title
end
post '/addMultipleMovies' do
	require_admin
	params[:movielist].split(/[ ]?\r\n[ ]?/).each do |title|
		next unless Movie.get(title).nil?
		m = YAML.load(open(URI.escape("http://api.themoviedb.org/2.1/Movie.search/en/yaml/"+$API_KEY+'/'+title)).read)
		next if (m[0] == false || !m[0].is_a?(Hash))
		result = YAML.load(open("http://api.themoviedb.org/2.1/Movie.getInfo/en/yaml/"+$API_KEY + '/' + m[0]["id"].to_s).read)[0]
		release_year = result['released'].split('-')[0]
		result['name'].strip!
		movie = Movie.new(:title => result['name'], :release_year => release_year, :length => result['runtime'].to_i, :mpaa_rating => '', :plot => result['overview'])
		dirname = ''
		result['cast'].each do |person|
			dirname = person['name'] if person['job'] == "Director"
			if person['job'] == "Actor"
				actor = Actor.get(person['name'])
				actor = Actor.new( :name => person['name'], :age => 0) if (actor.nil?)
				movie.actors << actor
			end
		end
		movie.save
		director = Director.get(dirname)
		director = Director.new(:name => dirname, :age => 0) if director.nil?
		director.movies << movie
		director.save
	end
	redirect '/movies'
end
post '/editMovie/:key' do
	require_admin
	movie = Movie.get(params[:key])
	movie.destroy! unless movie.nil?
	params[:title].strip!
	movie = Movie.new(:title => params[:title], :release_year => params[:release_year].to_i, :length => params[:length].to_i, :mpaa_rating => params[:mpaa_rating], :plot => params[:plot].gsub("\r\n","<br />"))
	params[:cast].split(/[ ]?,[ ]?/).each do |name|
		actor = Actor.get(name)
		actor = Actor.new( :name => name) if actor.nil?
		movie.actors << actor 
	end
	movie.save
	director = Director.get(params[:director_name])
	director = Director.new(:name => params[:director_name], :age => 0) if director.nil?
	director.movies << movie
	director.save
	redirect "/movie/#{ params[:title] }"
end
post '/addActor' do
	require_admin
	params[:name].strip!
	halt(400, "Invalid Actor Name") if (params[:name]=="")
	actor = Actor.new(:name => params[:name], :age => params[:age].to_i)
	actor.save
	redirect '/actors'
end
post '/editActor/:oldName' do
	require_admin
	params[:name].strip!
	halt(400, "Invalid Actor Name") if (params[:name]=="")
	actor = Actor.get(params[:oldName])
	actor.destroy!
	actor = Actor.new(:name => params[:name], :age => params[:age].to_i)
	actor.save
	redirect '/actors'
end
post '/addDirector' do
	require_admin
	params[:name].strip!
	halt(400, "Invalid Director Name") if (params[:name]=="")
	director = Director.new(:name => params[:name], :age => params[:age].to_i)
	director.save
	redirect '/directors'
end
post '/editDirector/:oldName' do
	require_admin
	params[:name].strip!
	halt(400, "Invalid Director Name") if (params[:name]=="")
	director = Director.get(params[:oldName])
	director.destroy!
	director = Director.new(:name => params[:name], :age => params[:age].to_i)
	director.save
	redirect '/directors'
end
get '/delete:type/:value' do #deleteMovie, deleteActor, deleteDirector
	require_admin
	record = eval("#{params[:type]}.get(params[:value])")
	record.destroy!
	redirect "/#{params[:type].downcase}s"
end

get '/:page' do haml params[:page].to_sym end #/movies /addMovie/ /actors/ /addActor/ /director/ /addDirector/
get '/:type/:key' do haml params[:type].to_sym end	#/movie/:title /editMovie/:title /actor/:name /editActor/:name /director/:name /editDirector/:name

helpers do
	include Sinatra::Authorization
	def text_input(lable, name, text="")
		%{<tr><td> #{lable}</td><td><input type="text" size="25" name="#{name}" value="#{text}">}
	end
	def jQ_clean(text)
		text.gsub(/[ :&,'!\.]/,'')
	end
	def textarea_input(lable, name, text="",size=10)
		%{<tr><td> #{lable}</td><td><textarea rows="#{size.to_s}" cols="23" name=#{name}>#{text}</textarea>}
	end
end