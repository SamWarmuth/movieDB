require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'do-postgres'
require 'data-objects'
require 'haml'


class Actor
	include DataMapper::Resource
	
	property :name,	String, :key => true
	property :age,	Integer
	
	has n, :movies, :through => Resource
end

class Movie
	include DataMapper::Resource
	
	property :title, 		String, :key => true
	property :release_year,	Integer
	property :length,		Integer
	property :plot,			Text
	property :mpaa_rating,	String
	
	belongs_to :director
	has n, :actors, :through => Resource
end

class Director
	include DataMapper::Resource
	
	property :name,	String, :key => true
	property :age,	Integer
	
	has n, :movies
end


configure do
	DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/movieDB.db")

	#Create/Upgrade All Tables!
	DataMapper.auto_upgrade!
end

#Use utf-8 for outgoing
before do
	headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do
	haml :index
end


post '/search' do
	haml :search
end

get '/movies' do
	haml :listMovies
end

get '/movie/:title' do
	haml :movieInfo
end

get '/addMovie' do
	haml :addMovie
end

post '/addMovie' do
	halt(400, "Invalid Movie Title") if (params[:title]=="")
	movie = Movie.new(:title => params[:title], :release_year => params[:release_year].to_i, :length => params[:length].to_i, :mpaa_rating => params[:mpaa_rating], :director_name => params[:director_name], :plot => params[:plot])
	
	params[:cast].split(/[ ]?,[ ]?/).each do |name|
		actor = Actor.get(name)
		movie.actors << actor
	end
	movie.save
	redirect '/movies'
end

get '/deleteMovie/:title' do
	movie = Movie.get(params[:title])
	movie.destroy!
	redirect '/movies'
end

get '/actors' do
	haml :listActors
end

get '/actor/:name' do
	haml :actorInfo
end


get '/addActor' do
	haml :addActor
end

post '/addActor' do
	actor = Actor.new(:name => params[:name], :age => params[:age].to_i)
	actor.save
	redirect '/actors'
end

get '/deleteActor/:name' do
	actor = Actor.get(params[:name])
	actor.destroy!
	redirect '/actors'
end

get '/directors' do
	haml :listDirectors
end

get '/director/:name' do
	haml :directorInfo
end

get '/addDirector' do
	haml :addDirector
end

post '/addDirector' do
	director = Director.new(:name => params[:name], :age => params[:age].to_i)
	director.save
	redirect '/directors'
end

get '/deleteDirector/:name' do
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
	%body{:style => "color: gray; margin-left: 75px; margin-right: 75px; font: 18px/20px helvetica; text-align: center;"}
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
	#{movie.director_name},
	= movie.length
	minutes
	%br/
%br/
%a{:href => "/addMovie"} Add Movie
%br/
	
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
%br/
%h4
	%a{:href => "/deleteMovie/#{movie.title}"} Delete Movie
		
		
	
@@addMovie
%h1 Add Movie
%br/

%form{:method => "POST", :action => "/addMovie"}
	%table{:align => "center"}
		%tr 
			%td Title
			%td 
				%input{:type => "text", :size => "25", :name => "title"}
		%tr
			%td Release Year
			%td
				%input{:type => "text", :size => "25", :name => "release_year"}
		%tr
			%td Length (Minutes)
			%td
				%input{:type => "text", :size => "25", :name => "length"}
		%tr
			%td Director Name
			%td
				%input{:type => "text", :size => "25", :name => "director_name"}
		%tr
			%td MPAA Rating
			%td
				%input{:type => "text", :size => "25", :name => "mpaa_rating"}
		%tr
			%td Plot Summary
			%td
				%textarea{:rows => "5", :cols => "23", :name => "plot"}
		%tr
			%td Cast (comma separated)
			%td
				%textarea{:rows => "5", :cols => "23", :name => "cast"}
	%br/	
	%input{:type => "submit", :value => "Add Movie"}
	
@@listActors
%h1 Actors
-Actor.all.each do |actor|
	%strong 
		%a{:href => "/actor/#{actor.name}"} #{actor.name}
	= actor.age
	years old
	%br/
%br/
%a{:href => "/addActor"} Add Actor
%br/
	
@@actorInfo
- actor = Actor.get(params[:name])
%h1
	= actor.name
	
%h2
	= actor.age
	years old
	%p
		%strong Movies
	
%h3
	- actor.movies.each do |movie|
		%a{:href => "/movie/#{movie.title}"} #{movie.title}
		%br/
	
%br/
%h4
	%a{:href => "/deleteActor/#{actor.name}"} Delete Actor
	
@@addActor
%h1 Add Actor
%br/
%form{:method => "POST", :action => "/addActor"}
	%table{:align => "center"}
		%tr 
			%td Name
			%td 
				%input{:type => "text", :size => "25", :name => "name"}
		%tr
			%td Age
			%td
				%input{:type => "text", :size => "25", :name => "age"}
	%br/	
	%input{:type => "submit", :value => "Add Actor"}
	
	
@@listDirectors
%h1 Directors
-Director.all.each do |director|
	%strong
		%a{:href => "/director/#{director.name}"} #{director.name}
	= director.age
	years old
	%br/
%br/
%a{:href => "/addDirector"} Add Director
%br/

@@directorInfo
- director = Director.get(params[:name])
%h1
	= director.name
%h2
	= director.age
	years old
	%br/
	%br/
	%br/
	%strong Movies
%h3
	- director.movies.each do |movie|
		%a{:href => "/movie/#{movie.title}"} #{movie.title}
		%br

@@addDirector
%h1 Add Director
%br/
%form{:method => "POST", :action => "/addDirector"}
	%table{:align => "center"}
		%tr 
			%td Name
			%td 
				%input{:type => "text", :size => "25", :name => "name"}
		%tr
			%td Age
			%td
				%input{:type => "text", :size => "25", :name => "age"}
	%br/	
	%input{:type => "submit", :value => "Add Director"}