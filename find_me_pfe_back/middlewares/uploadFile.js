const multer = require('multer');
var storage = multer.diskStorage(
    {
        
        filename: function (req, file, cb) {
            // Generate a unique filename using timestamp and random string
            const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
            const fileExtension = file.originalname.split('.').pop();
            cb(null, `${uniqueSuffix}.${fileExtension}`);          
        }
    }
)
        
        var uploadFile = multer({ storage: storage });
        module.exports = uploadFile;