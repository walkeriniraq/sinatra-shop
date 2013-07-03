require 'data_mapper'
require 'faker'
require 'jdbc/sqlite3' if defined? JRUBY_VERSION

class Database
  def self.initialize
    DataMapper::Logger.new($stdout, :debug)
    # memory database appears to timeout if not used in ~5 mins, which causes the database to be dumped
    #DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.setup(:default, 'sqlite:test.db')
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  def self.seed_data
    200.times do
      name = Faker::Company.catch_phrase
      name = name[0..-2] + 'ies' if name[-1] == 'y'
      name = name + 's' unless name[-1] == 's'
      title = Title.create(
          name: name,
          author: Faker::Name.name,
          number_pages: rand(20..400),
          price: 5 + rand(50) + (rand(0..99) * 0.1),
          quantity: rand(100),
          description: Faker::Lorem.paragraph
      )
      rand(1..4).times do
        Review.create(
            reviewer: Faker::Internet.email,
            stars: rand(1..5),
            text: Faker::Lorem.paragraph,
            date: (DateTime.now - rand(500)).to_date,
            title: title
        )
      end
    end unless Title.count > 1
    if User.count < 1
      %w(steve dave annette fred ralph jimbo homer thomas).each do |name|
        User.create(
            username: name
        )
      end
      titles = Title.all
      User.all.each do |user|
        3.times do
          book = titles.sample
          user.favorites << book unless user.favorites.include? book
        end
        user.save
      end
    end
  end
end

class User
  include DataMapper::Resource

  property :username, String, :key => true
  has n, :user_favorites
  has n, :favorites, 'Title', :through => :user_favorites, :via => :title
  #alias_method :favorites, :titles
end

class UserFavorite
  include DataMapper::Resource

  belongs_to :user, :key => true
  belongs_to :title, :key => true
end

class Review
  include DataMapper::Resource

  property :id, Serial
  property :reviewer, String
  property :stars, Integer
  property :date, Date
  property :text, Text

  belongs_to :title
end

class Title
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :author, String
  property :number_pages, Integer
  property :price, Float
  property :quantity, Integer
  property :description, Text

  has n, :user_favorites
  has n, :likes, 'User', :through => :user_favorites, :via => :user
  has n, :reviews

  def average_stars
    return 0 if reviews.nil? || reviews.empty?
    reviews.map { |x| x.stars }.inject(:+).to_f / reviews.count
  end

end

