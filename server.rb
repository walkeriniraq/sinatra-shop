require 'sinatra'
require 'json'
require 'andand'
require_relative 'database'

Database.initialize
Database.seed_data

enable :sessions
set :session_secret, 'THIS IS A REALLY SECRET KEY THAT IS DECENTLY LONG'
set :protection, { :origin_whitelist => 'http://apps.rylath.net' }
set :port, 4568
set :server_relative_root, '/books'

PAGE_SIZE = 10

get '/' do
  erb :index
end

get '/login_page' do
  erb :login_page
end

get '/item/:id' do
  not_found if params[:id].nil?
  title = Title.get(params[:id])
  not_found if title.nil?
  erb :detail, :locals => { :title => title, :average_stars => title.average_stars, :user => session_user }
end

get '/list' do
  page = (params[:page] || 1).to_i - 1
  start = page * PAGE_SIZE
  data = { total_pages: (Title.count / PAGE_SIZE + 1).to_i, current_page: page + 1 }
  user = session_user
  user_favorites = if user.nil?
                     []
                   else
                     # the generated SQL for this is faster than getting the titles first
                     Title.all[start, PAGE_SIZE] & user.favorites
                   end
  data[:list] = Title.view_model_with_favorites(Title.all[start, PAGE_SIZE], user_favorites)
  data.to_json
end

post '/add_favorite' do
  return { status: 'Not logged in.'}.to_json if session_user.nil?
  title, error = get_object_from_database Title, params[:title_id]
  return { status: error }.to_json if title.nil?
  title.likes << session_user
  title.likes.uniq!
  title.save
  { status: 'ok' }.to_json
end

post '/remove_favorite' do
  return { status: 'Not logged in.'}.to_json if session_user.nil?
  title, error = get_object_from_database Title, params[:title_id]
  return { status: error }.to_json if title.nil?
  title.likes.delete session_user
  title.save
  { status: 'ok' }.to_json
end

get '/user_list' do
  User.all.to_json
end

get '/username' do
  return { status: 'logout' }.to_json if session[:user].nil?
  { status: 'ok', user: session[:user] }.to_json
end

post '/login' do
  user, error = get_object_from_database User, params[:username]
  return { status: error }.to_json if user.nil?
  session[:user] = user.username
  { status: 'ok' }.to_json
end

get '/logout' do
  session[:user] = nil
  redirect settings.server_relative_root
end

# UTILITY METHODS
def get_object_from_database(type, id)
  return nil, 'Object not present.' if id.nil?
  object = type.get(id)
  return object, 'Object not found.'
end

def session_user
  return if session[:user].nil? || session[:user].empty?
  User.get(session[:user])
end

# DECORATOR FOR TITLE CLASS
class Title

  def self.view_model_with_favorites(titles, favorites)
    titles.map { |x| x.view_model_hash favorites.include? x }
  end

  def view_model_hash(favorite = false)
    {
        id: id,
        name: name,
        author: author,
        number_pages: number_pages,
        price: '%.2f' % price,
        quantity: quantity,
        favorite: favorite
    }
  end

end
