require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'do_postgres'
require 'haml'
	
class Actor
	include DataMapper::Resource
	property :name,	String, :key => true
	property :age,	Integer
	has n, :casts
	has n, :movies, :through => :casts
end

class Movie
	include DataMapper::Resource
	property :title, 		String, :key => true
	property :release_year,	Integer
	property :length,		Integer
	property :plot,			Text
	property :mpaa_rating,	String
	belongs_to :director
	has n, :casts
	has n, :actors, :through => :casts
end

class Director
	include DataMapper::Resource
	property :name,	String, :key => true
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
#Create/Upgrade All Tables!
DataMapper.auto_upgrade!

#Use utf-8 for outgoing
before do
	headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do haml :index end

post '/search' do haml :search end

get '/movies' do haml :listMovies end
get '/movie/:title' do haml :movieInfo end
get '/addMovie' do haml :addMovie end

def newMovie 
	movie = Movie.new(:title => params[:title], :release_year => params[:release_year].to_i, :length => params[:length].to_i, :mpaa_rating => params[:mpaa_rating], :plot => params[:plot])
	
	
	params[:cast].split(/[ ]?,[ ]?/).each do |name|
		actor = Actor.get(name)
		#movie.actors << actor
	end
	
	movie.save
	director = Director.get(params[:director_name])
	director.movies << movie if !director.nil?
	director.save
end

post '/addMovie' do
	halt(400, "Invalid Movie Title") if (params[:title]=="")
	newMovie
	redirect '/movies'
end

get '/editMovie/:title' do haml :editMovie end

post '/editMovie/:oldTitle' do
	halt(400, "Invalid Movie Title") if (params[:title]=="")
	movie = Movie.get(params[:oldTitle])
	movie.destroy!
	newMovie
	redirect "/movie/#{ params[:title] }"
end

get '/deleteMovie/:title' do
	movie = Movie.get(params[:title])
	movie.destroy!
	redirect '/movies'
end

get '/actors' do haml :listActors end
get '/actor/:name' do haml :actorInfo end
get '/addActor' do haml :addActor end

post '/addActor' do
	actor = Actor.new(:name => params[:name], :age => params[:age].to_i)
	actor.save
	redirect '/actors'
end

get '/editActor/:name' do haml :editActor end

post '/editActor/:oldName' do
	halt(400, "Invalid Actor Name") if (params[:name]=="")
	actor = Actor.get(params[:oldName])
	actor.destroy!
	actor = Actor.new(:name => params[:name], :age => params[:age].to_i)
	actor.save
	redirect '/actors'
end

get '/deleteActor/:name' do
	actor = Actor.get(params[:name])
	actor.destroy!
	redirect '/actors'
end

get '/directors' do haml :listDirectors end
get '/director/:name' do haml :directorInfo end
get '/addDirector' do haml :addDirector end

post '/addDirector' do
	director = Director.new(:name => params[:name], :age => params[:age].to_i)
	director.save
	redirect '/directors'
end

get '/editDirector/:name' do haml :editDirector end

post '/editDirector/:oldName' do
	halt(400, "Invalid Actor Name") if (params[:name]=="")
	director = Director.get(params[:oldName])
	director.destroy!
	director = Director.new(:name => params[:name], :age => params[:age].to_i)
	director.save
	redirect '/directors'
end

get '/deleteDirector/:name' do
	director = Director.get(params[:name])
	director.destroy!
	redirect '/directors'
end

helpers do
	def text_input(lable, name, text="")
		%{<tr><td> #{lable}</td><td><input type="text" size="25" name="#{name}" value="#{text}">}
	end
	def textarea_input(lable, name, text="")
		%{<tr><td> #{lable}</td><td><textarea rows="5" cols="23" name=#{name}>#{text}</textarea>}
	end
end

__END__

@@layout
!!!
%html
	%head
		%title= "The Movie Database"
		%style{:type => "text/css", :media => "screen"}
			:plain
				a:link {color: #000000; text-decoration: none; }
				a:active {color: #000000; text-decoration: none; }
				a:visited {color: #000000; text-decoration: none; }
				a:hover {color: #000000; text-decoration: underline; }
	%body{:style => "color: gray; margin-left: 75px; margin-right: 75px; font: 18pt/20pt helvetica; text-align: center;"}
		%h1{:style => "text-align: center; margin-bottom: -25px;"}
			%a{:href => "/"}
				The Movie Database
		%h4{:style => "text-align: center;"}
			%a{:href => "/movies"} Movies
			|
			%a{:href => "/actors"} Actors
			|
			%a{:href => "/directors"} Directors
			
			%form{:method => "POST", :action => "/search", :style => "font:14px/16px helvetica;"}
				Search
				%input{:type => "text", :size => "20", :name => "searchTerm"}
		.content
			= yield

@@index
%h3 
	Random Movie
	-if Movie.all.length != 0
		-movie = Movie.all[rand(Movie.all.length)]
		%h1
			%a{:href => "/movie/#{movie.title}"} #{movie.title}
			(#{movie.mpaa_rating})
		%h2	
			= movie.release_year
			\-
			-if !movie.director.nil?
				%a{:href => "/director/#{movie.director.name}"} #{movie.director.name}
			= movie.length
			minutes

		%p
			= movie.plot
		-actors = movie.actors
		-if (!actors[0].nil?)
			%h2
				Actors
				%br/
			%h3
				-actors.each do |actor|
					%a{:href => "/actor/#{actor.name}"} #{actor.name}
					%br/

@@search
-movies = Movie.all(:title.like => "%#{params[:searchTerm]}%")
-actors = Actor.all(:name.like => "%#{params[:searchTerm]}%")
-directors = Director.all(:name.like => "%#{params[:searchTerm]}%")
%h1 
	Searching for '#{params[:searchTerm]}'
%h2
	-if !(movies[0].nil?)
		%p Movies
		-movies.each do |movie|
			%p
				%a{:href => "/movie/#{movie.title}"} #{movie.title}
	-if !(actors[0].nil?)	
		%p Actors
		-actors.each do |actor|
			%p
				%a{:href => "/actor/#{actor.name}"} #{actor.name}
	-if !(directors[0].nil?)	
		%p Directors
		-directors.each do |director|
			%p
				%a{:href => "/director/#{director.name}"} #{director.name}

@@listMovies
%h1 Movies
-Movie.all.each do |movie|
	%strong 
		%a{:href => "/movie/#{movie.title}"} #{movie.title}
	(#{movie.mpaa_rating})
	= movie.release_year
	\-
	-if !movie.director.nil?
		#{movie.director.name},
	= movie.length
	minutes
	%br/
%p
	%a{:href => "/addMovie"} Add Movie
	
@@movieInfo
- movie = Movie.get(params[:title])
%h1
	= movie.title
	(#{movie.mpaa_rating})
%h2	
	= movie.release_year
	\-
	-if !movie.director.nil?
		%a{:href => "/director/#{movie.director.name}"} #{movie.director.name}
	= movie.length
	minutes
%p
	= movie.plot
-actors = movie.actors
-if (!actors[0].nil?)
	%h2
		Actors
		%br/
	%h3
		-actors.each do |actor|
			%a{:href => "/actor/#{actor.name}"} #{actor.name}
			%br/
%p
	%a{:href => "/editMovie/#{movie.title}"} Edit Movie		
	|
	%a{:href => "/deleteMovie/#{movie.title}"} Delete Movie	
	
@@addMovie
%h1 Add Movie
%form{:method => "POST", :action => "/addMovie"}
	%table{:align => "center"}
		= text_input("Title","title")
		= text_input("Release Year","release_year")		
		= text_input("Length (minutes)","length")
		= text_input("Director Name","director_name")
		= text_input("MPAA Rating","mpaa_rating")
		= textarea_input("Plot Summary", "plot")
		= textarea_input("Cast (comma separated)", "cast")
	%p	
		%input{:type => "submit", :value => "Add Movie"}

@@editMovie
%h1 Edit Movie
- movie = Movie.get(params[:title])
%p
	= movie.title
%form{:method => "POST", :action => "/editMovie/#{movie.title}"}
	%table{:align => "center"}
		= text_input("Title","title", movie.title)
		= text_input("Release Year","release_year", movie.release_year)		
		= text_input("Length (minutes)","length", movie.length.to_s)
		= text_input("Director Name","director_name", movie.director.name.to_s)
		= text_input("MPAA Rating","mpaa_rating", movie.mpaa_rating)
		= textarea_input("Plot Summary", "plot", movie.plot)
		- cast = ""
		- movie.actors.each do |actor|
			- cast << "#{actor.name}, "
		= textarea_input("Cast (comma separated)", "cast", cast)
	%p	
		%input{:type => "submit", :value => "Edit Movie"}
	
@@listActors
%h1 Actors
-Actor.all.each do |actor|
	%strong 
		%a{:href => "/actor/#{actor.name}"} #{actor.name}
	= actor.age
	years old
	%br/
%p
	%a{:href => "/addActor"} Add Actor
	
@@actorInfo
- actor = Actor.get(params[:name])
%h1 
	= actor.name
%h2
	= actor.age
	years old
%h3
	- actor.movies.each do |movie|
		%p
			%a{:href => "/movie/#{movie.title}"} #{movie.title}
%p
	%a{:href => "/editActor/#{actor.name}"} Edit Actor
	|
	%a{:href => "/deleteActor/#{actor.name}"} Delete Actor
	
@@addActor
%h1 Add Actor
%form{:method => "POST", :action => "/addActor"}
	%table{:align => "center"}
		= text_input("Name", "name")
		= text_input("Age", "age")
	%p	
		%input{:type => "submit", :value => "Add Actor"}
	
@@editActor
%h1 Edit Actor
- actor = Actor.get(params[:name])
%form{:method => "POST", :action => "/editActor/#{params[:name]}"}
	%table{:align => "center"}
		= text_input("Name", "name", actor.name)
		= text_input("Age", "age", actor.age)
	%p	
		%input{:type => "submit", :value => "Edit Actor"}
	
@@listDirectors
%h1 Directors
-Director.all.each do |director|
	%strong
		%a{:href => "/director/#{director.name}"} #{director.name}
	= director.age
	years old
	%br/
%p
	%a{:href => "/addDirector"} Add Director

@@directorInfo
- director = Director.get(params[:name])
%h1
	= director.name
%h2
	= director.age
	years old
%h3
	- director.movies.each do |movie|
		%p
			%a{:href => "/movie/#{movie.title}"} #{movie.title}
%p
	%a{:href => "/editDirector/#{director.name}"} Edit Director
	|
	%a{:href => "/deleteDirector/#{director.name}"} Delete Director
		

@@addDirector
%h1 Add Director
%form{:method => "POST", :action => "/addDirector"}
	%table{:align => "center"}
		= text_input("Name", "name")
		= text_input("Age", "age")
	%p	
		%input{:type => "submit", :value => "Add Director"}
	
@@editDirector
%h1 Edit Director
- director = Director.get(params[:name])
%form{:method => "POST", :action => "/editDirector/#{params[:name]}"}
	%table{:align => "center"}
		= text_input("Name", "name", director.name)
		= text_input("Age", "age", director.age)
	%p	
		%input{:type => "submit", :value => "Edit Director"}