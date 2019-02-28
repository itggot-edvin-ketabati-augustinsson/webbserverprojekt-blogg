require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    slim(:home)
end

post('/login') do
    db = SQLite3::Database.new('blogg.db')
    db.results_as_hash = true
    result = db.execute("SELECT Password, UserId FROM users WHERE Username =(?)", params["name"])
    if result == []
        redirect('/failed')
    end
    encrypted_pass = result[0]["Password"]
    if BCrypt::Password.new(encrypted_pass) == params["pass"]
        session[:loggedin] = true
        session[:user_id] = result[0]["UserId"]
        session[:name] = params["name"]
        redirect('/profil')
    else
        redirect('/failed')
    end
end

get('/profil') do
    if session[:loggedin] == true
        db = SQLite3::Database.new('blogg.db')
        db.results_as_hash = true
        posts = db.execute("SELECT posts.PostId, posts.ContentText, posts.ContentImage, users.Username FROM posts INNER JOIN users ON users.UserId = posts.UserId WHERE posts.UserId =(?)", session[:user_id])
        slim(:profil, locals:{
            username: session[:name],
            posts: posts
        })
    else
        redirect('/')
    end
end

post('/logout') do
    session.destroy
    redirect('/')
end

get('/register') do
    slim(:register)
end

post('/create') do
    name = params["name"]
    password = BCrypt::Password.create(params["pass"])
    db = SQLite3::Database.new('blogg.db')
    db.execute("INSERT INTO users(Username, Password) VALUES( (?), (?) )",name, password)
    redirect('/')
end

get('/failed') do
    session.destroy
    slim(:login_failed)
end

post('/post') do
    text = params["post_text"]
    image = params["post_image"]
    user_id = session[:user_id]
    db = SQLite3::Database.new('blogg.db')
    if image != nil
        db.execute("INSERT INTO posts(UserId, ContentText, ContentImage) VALUES( (?),(?),(?) )",user_id,text,image)
    else
        db.execute("INSERT INTO posts(UserId, ContentText) VALUES( (?),(?) )",user_id,text)
    end
    redirect('/profil')
end

post('/delete/:id') do
    db = SQLite3::Database.new('blogg.db')
    db.execute("DELETE FROM posts WHERE PostId = (?)",params["id"])
    redirect('/profil')
end

get('/edit/:id') do
    db = SQLite3::Database.new('blogg.db')
    db.results_as_hash = true
    post = db.execute("SELECT PostId, ContentText, ContentImage FROM posts WHERE PostId =(?)", params["id"])
    slim(:edit, locals:{
        post: post
    })
end

post('/update/:id') do
    
end

error 400..510 do
    session.destroy
    slim(:error)
end