const mongoose = require('mongoose');

module.exports.connectToMongoDB = async () => {
    mongoose.set('strictQuery', false);
    mongoose.connect(process.env.URL_MONGO).then( () => {
        console.log('Connected to DB');
    }).catch(
        (erreur) => {
            console.log(erreur.message); 
        }
    );
}