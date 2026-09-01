var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
const http = require('http');
require('dotenv').config();
const cors = require('cors');
const {connectToMongoDB } = require('./db/db'); //accolades 7atinehom khater bech n'importiw fnct wala akther

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');
var productRouter = require('./routes/product');
var brandRouter = require('./routes/brand');
var shopRouter = require('./routes/shop');
var discountRouter = require('./routes/discount');
var categoryRouter = require('./routes/category');
var authRouter = require('./routes/auth');
var chatbotRouter = require('./routes/chatbot');
var notificationRouter =require("./routes/notification")


var app = express();

// view engine setup         teb3a dossier views
//app.set('views', path.join(__dirname, 'views'));
//app.set('view engine', 'jade');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(cors());

app.use('/', indexRouter);
app.use('/users', usersRouter);
app.use('/products', productRouter);
app.use('/brands', brandRouter);
app.use('/shops',shopRouter);
app.use('/discounts', discountRouter);
app.use('/categories', categoryRouter);
app.use('/auth', authRouter);
app.use('/chatbot', chatbotRouter);
app.use("/notifications",notificationRouter)

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.json('error');
});

//module.exports = app;   na7ineha khater ken yranni ala dossier bin/www
const server = http.createServer(app); //configurina serveur mte3na bech yekhdem bel http
server.listen(process.env.PORT,()=>{connectToMongoDB();
console.log('app is running on port 5000')}); //serveur 7attineh yemchi 3al port 5000(generalement port 5000 mta3 developpement back w 3000 front)
// najmou n7otou process.env.PORT fi blaset 5000