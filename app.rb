require "sinatra"
require "sinatra/reloader" if development?
require "pry-byebug"
require "better_errors"
require_relative 'cookbook'    # You need to create this file!
require_relative 'controller'  # You need to create this file!
require_relative 'router'
require_relative 'recipe'

csv_file   = File.join(__dir__, 'recipes.csv')
cookbook   = Cookbook.new(csv_file)
controller = Controller.new(cookbook)


configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path('..', __FILE__)
end

get '/new' do
  erb :new
end

post '/recipes' do
  recipe = Recipe.new(params[:name], params[:time], params[:difficulty], params[:description])
  cookbook.add_recipe(recipe)
  @recipes = cookbook.all
  erb :index
end

get '/destroy/:name' do
  puts params[:name]
  "Destruction de l'élement #{params[:name]}"
  cookbook.remove_recipe(params[:name].to_i)
  @recipes = cookbook.all
  erb :index
end

get '/fetch' do
  erb :fetch
end

post '/fetch' do
  url = "https://www.marmiton.org/recettes/recherche.aspx?aqt=#{params[:name]}"
    doc = Nokogiri::HTML(open(url), nil, 'utf-8')
    result = []
    doc.search('.recipe-card-link').each_with_index do |item , index|
         link = "https://www.marmiton.org/" + URI.parse(item.attributes["href"].value).to_s
         link = link.gsub(".org//", ".org/")
         name = item.search('.recipe-card__title').text
         doc2 = Nokogiri::HTML(open(link), nil, 'utf-8')
         description = doc2.search('.recipe-preparation__list').text.strip.gsub(/\t|\n|\r/, '')
         time = doc2.search('.recipe-infos__total-time__value').text
         difficulty = doc2.search('.recipe-infos__level').text.strip.gsub(/\t|\n|\r/, '')
         result <<
           {
              name: name,
              link: link,
              time: time,
              difficulty: difficulty
            }
    end

      "Recherche de l'élement #{result.to_s}"
      @name = params[:name]
      @result = result
      erb :result

end


get '/' do
  @recipes = cookbook.all
  erb :index
end
