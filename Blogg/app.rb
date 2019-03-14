require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def login(result)
    encrypted_pass = result[0]["Password"]
    if BCrypt::Password.new(encrypted_pass) == params["pass"]
        session[:loggedin] = true
        session[:user_id] = result[0]["UserId"]
        session[:name] = params["name"]
        return true
    else
        return false
    end
end

# def verify_post_owner(id)
#     db = SQLite3::Database.new('blogg.db')
#     op_id = db.execute("SELECT UserId FROM posts WHERE PostId =(?)", params["id"])
#     if op_id[0][0] == session[:user_id]
#         db.results_as_hash = true
#         post = db.execute("SELECT PostId, ContentText, ContentImage FROM posts WHERE PostId =(?)", params["id"])
#         slim(:edit, locals:{
#             post: post
#         })
#     else
#         redirect('/failed')
#     end
# end

secure_routes = ['/profil','/post','/edit/:id','/delete/:id']

before do
    if secure_routes.include? request.path()
        if session[:loggedin] != true
            redirect('/login')
        end
    end
end

get('/') do
    db = SQLite3::Database.new('blogg.db')
    db.results_as_hash = true
    posts = db.execute("SELECT posts.PostId, posts.ContentText, posts.ContentImage, users.Username FROM posts INNER JOIN users ON users.UserId = posts.UserId")
    slim(:home, locals:{
        posts: posts
    })
end

post('/login') do
    db = SQLite3::Database.new('blogg.db')
    db.results_as_hash = true
    result = db.execute("SELECT Password, UserId FROM users WHERE Username =(?)", params["name"])
    if result == []
        redirect('/failed')
    end
    if login(result)
        redirect('/profil')
    else
        redirect('/failed')
    end
end

get('/profil') do
    db = SQLite3::Database.new('blogg.db')
    db.results_as_hash = true
    posts = db.execute("SELECT posts.PostId, posts.ContentText, posts.ContentImage, users.Username FROM posts INNER JOIN users ON users.UserId = posts.UserId WHERE posts.UserId =(?)", session[:user_id])
    slim(:profil, locals:{
        username: session[:name],
        posts: posts
    })
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
    op_id = db.execute("SELECT UserId FROM posts WHERE PostId =(?)", params["id"])
    if op_id[0][0] == session[:user_id]
        db.execute("DELETE FROM posts WHERE PostId = (?)",params["id"])
        redirect('/profil')
    else
        redirect('/failed')
    end
end

get('/edit/:id') do
    db = SQLite3::Database.new('blogg.db')
    op_id = db.execute("SELECT UserId FROM posts WHERE PostId =(?)", params["id"])
    if op_id[0][0] == session[:user_id]
        db.results_as_hash = true
        post = db.execute("SELECT PostId, ContentText, ContentImage FROM posts WHERE PostId =(?)", params["id"])
        slim(:edit, locals:{
            post: post
        })
    else
        redirect('/failed')
    end
end

post('/update/:id') do
    db = SQLite3::Database.new('blogg.db')
    
    op_id = db.execute("SELECT UserId FROM posts WHERE PostId =(?)", params["id"])
    if op_id[0][0] == session[:user_id]
        if params["post_image"] != nil
            db.execute("UPDATE posts SET ContentText =(?), ContentImage =(?) WHERE PostId =(?)",params["post_text"],params["post_image"], params["id"])
        else
            db.execute("UPDATE posts SET ContentText =(?) WHERE PostId =(?)",params["post_text"], params["id"])
        end
        redirect('/profil')
    else
        redirect('/failed')
    end
end

error 400..510 do
    slim(:error)
end

post('/fuckup') do
    session.destroy
    redirect('/')
end