const {NlpManager, Language} = require('node-nlp');
const manager = new NlpManager(({languages : ['en']}));

const colors = ["black","white","grey","cream","brown","red","blue","light blue","pink","green","beige","yellow","orange","gold","silver","bronze"]
const products=["shirt","t-shirt","shorts","pants","dress","shoes","sportswear","sportwear","sport wear","accessory","accessories","necklace","bracelet","ring"];
//add document
//Greeting
manager.addDocument('en','Hello','greeting');
manager.addDocument('en','Heellooo','greeting');
manager.addDocument('en','Hi','greeting');
manager.addDocument('en','Hii','greeting');
manager.addDocument('en','Hey','greeting');
manager.addDocument('en','Heey','greeting');
manager.addDocument('en','Heeey!','greeting');
manager.addDocument('en','Good morning','greeting');
manager.addDocument('en','Good evening','greeting');
manager.addDocument('en','Good afternoon','greeting');
manager.addDocument('en','Good day','greeting');
manager.addDocument('en','how are you?','greeting');

//Greeting.bye
manager.addDocument('en','Good bye','greeting.bye');
manager.addDocument('en','Bye','greeting.bye');
manager.addDocument('en','Bye bye','greeting.bye');
manager.addDocument('en','Take care','greeting.bye');
manager.addDocument('en','Bye for now','greeting.bye');
manager.addDocument('en','Ok, see you later','greeting.bye');
manager.addDocument('en','Okay, see you later','greeting.bye');
manager.addDocument('en','Ok bye','greeting.bye');
manager.addDocument('en','Ciao','greeting.bye');

//random questions
manager.addDocument('en','Who are ?','faq');
manager.addDocument('en',"What's your name?",'faq');
manager.addDocument('en',"What is your name?",'faq');
manager.addDocument('en','Who is this?','faq');
manager.addDocument('en','say about you','faq');
manager.addDocument('en','why are you here','faq');
manager.addDocument('en','describe yourself','faq');
manager.addDocument('en','tell me about yourself','faq');
manager.addDocument('en','tell me about you','faq');
manager.addDocument('en','I want to know more about you','faq');
manager.addDocument('en','talk about yourself','faq');

//age
manager.addDocument("en", "your age", "age");
manager.addDocument("en", "how old are you", "age");
manager.addDocument("en", "what's your age", "age");
manager.addDocument("en", "I'd like to know your age", "age");
manager.addDocument("en", "tell me your age", "age");

//help
manager.addDocument("en", "can help me now", "help");
manager.addDocument("en", "assist me", "help");
manager.addDocument("en", "I need you to help me", "help");
manager.addDocument("en", "I need your help", "help");
manager.addDocument("en", "can you assist me", "help");
manager.addDocument("en", "you can help me", "help");

//thanking
manager.addDocument("en", "Thank you", "thanking");
manager.addDocument("en", "Thanks", "thanking");
manager.addDocument("en", "Thanks a lot", "thanking");
manager.addDocument("en", "Thanks", "thanking");
manager.addDocument("en", "that's awesome thank you", "thanking");
manager.addDocument("en", "nice thank you", "thanking");
manager.addDocument("en", "thanks buddy", "thanking");
manager.addDocument("en", "cheers", "thanking");
manager.addDocument("en", "alright thanks", "thanking");

// user back
manager.addDocument("en", "I'm back", "user.back");
manager.addDocument("en", "Im back", "user.back");
manager.addDocument("en", "I have returned", "user.back");
manager.addDocument("en", "here I am again", "user.back");
manager.addDocument("en", "I came back", "user.back");


//user search
manager.addDocument('en',"I'm looking for",'search.general');
manager.addDocument('en',"I am looking for",'search.general');
manager.addDocument('en',"I want",'search.general');
manager.addDocument('en',"Is there any",'search.general');
//manager.addDocument('en',"Do have",'search.general');
//manager.addDocument('en',"Is there any "+couleur+" shirts",'shirt');

//user search product
products.forEach(product => {
    manager.addDocument('en',"I'm looking for a "+product,'search.product');
});
/*manager.addDocument('en',"I'm looking for a shirt",'search.product');
manager.addDocument('en',"I'm looking for a t-shirt",'search.product');
manager.addDocument('en',"I'm looking for shorts",'search.product');
manager.addDocument('en',"I'm looking for pants",'search.product');
manager.addDocument('en',"I'm looking for a dress",'search.product');
manager.addDocument('en',"I'm looking for shoes",'search.product');
manager.addDocument('en',"I'm looking for sportswear",'search.product');
manager.addDocument('en',"I'm looking for sportwear",'search.product');
manager.addDocument('en',"I'm looking for sport wear",'search.product');
manager.addDocument('en',"I'm looking for accessory",'search.product');
manager.addDocument('en',"I'm looking for accessories",'search.product');
manager.addDocument('en',"I'm looking for necklace",'search.product');
manager.addDocument('en',"I'm looking for bracelet",'search.product');
manager.addDocument('en',"I'm looking for ring",'search.product');*/

products.forEach(product => {
    manager.addDocument('en',"I want a "+product,'search.product');
});
/*manager.addDocument('en',"I want a shirt",'search.product');
manager.addDocument('en',"I want a t-shirt",'search.product');
manager.addDocument('en',"I want shorts",'search.product');
manager.addDocument('en',"I want pants",'search.product');
manager.addDocument('en',"I want dress",'search.product');
manager.addDocument('en',"I want shoes",'search.product');
manager.addDocument('en',"I want sportswear",'search.product');
manager.addDocument('en',"I want sportwear",'search.product');
manager.addDocument('en',"I want sport wear",'search.product');
manager.addDocument('en',"I want accessory",'search.product');
manager.addDocument('en',"I want accessories",'search.product');
manager.addDocument('en',"I want necklace",'search.product');
manager.addDocument('en',"I want bracelet",'search.product');
manager.addDocument('en',"I want ring",'search.product');*/

products.forEach(product => {
    manager.addDocument('en',"Is there any "+product,'search.product');
});
/*manager.addDocument('en',"Is there any shirts",'search.product');
manager.addDocument('en',"Is there any t-shirt",'search.product');
manager.addDocument('en',"Is there any shorts",'search.product');
manager.addDocument('en',"Is there any pants",'search.product');
manager.addDocument('en',"Is there any dresses",'search.product');
manager.addDocument('en',"Is there any dress",'search.product');
manager.addDocument('en',"Is there any shoes",'search.product');
manager.addDocument('en',"Is there any sportswear",'search.product');
manager.addDocument('en',"Is there any sport wear",'search.product');
manager.addDocument('en',"Is there any necklaces",'search.product');
manager.addDocument('en',"Is there any necklace",'search.product');
manager.addDocument('en',"Is there any bracelets",'search.product');
manager.addDocument('en',"Is there any rings",'search.product');*/


//color
colors.forEach(color => {
  manager.addDocument('en',"i want it in "+color+"",'search.color');
  manager.addDocument('en',"is there any in"+color+"",'search.color');
  manager.addDocument('en',color+"",'search.color');
  products.forEach(product => {
    manager.addDocument('en','i want a '+color+' '+product,'search.color');
  });
});


//final search yes
manager.addDocument('en',"yes",'search.final');
manager.addDocument('en',"yeah",'search.final');
manager.addDocument('en',"yes, that's all",'search.final');
manager.addDocument('en',"yes, that's it",'search.final');
manager.addDocument('en',"yes, that's enough",'search.final');
manager.addDocument('en',"it is",'search.final');

//no
manager.addDocument('en',"no",'search.negation');
manager.addDocument('en',"nope",'search.negation');
manager.addDocument('en',"nah",'search.negation');
manager.addDocument('en',"no, i still have something else",'search.negation');
manager.addDocument('en',"no, i have one more thing",'search.negation');

//size
manager.addDocument('en',"XXS XS S M L Xl XXL size",'search.size');
manager.addDocument('en',"big size",'search.size');
manager.addDocument('en',"large size",'search.size');
manager.addDocument('en',"small size",'search.size');
manager.addDocument('en',"tiny size",'search.size');

//category
manager.addDocument('en',"Men women accessory acessories cosmetics jewelery kids sport mode shoes category",'search.category');
manager.addDocument('en',"Men",'search.category');
manager.addDocument('en',"women ",'search.category');
manager.addDocument('en',"accessory ",'search.category');
manager.addDocument('en',"acessories ",'search.category');
manager.addDocument('en',"cosmetics ",'search.category');
manager.addDocument('en',"jewelery ",'search.category');
manager.addDocument('en',"kids ",'search.category');
manager.addDocument('en',"sport ",'search.category');

//brand
manager.addDocument('en',"brand",'search.brand');
//manager.addDocument('en',"i want the brand",'search.brand');
manager.addDocument('en',"zara ",'search.brand');
manager.addDocument('en',"bershka ",'search.brand');
manager.addDocument('en',"adidas ",'search.brand');
manager.addDocument('en',"nike ",'search.brand');
manager.addDocument('en',"decathlon ",'search.brand');
manager.addDocument('en',"nivea ",'search.brand');

//add answers
//Greeting
manager.addAnswer('en','greeting','Hello, what can I do for you?');
manager.addAnswer('en','greeting','Hello, how can I help you?');
manager.addAnswer('en','greeting',"Hi");
manager.addAnswer('en','greeting','Hello, is there anything I can help you with?');

//Greeting.bye
manager.addAnswer('en','greeting.bye',"Bye.");
manager.addAnswer('en','greeting.bye','Bye, till next time.');
manager.addAnswer('en','greeting.bye',"Bye, see you soon!");

//random questions
manager.addAnswer('en','faq',"Hi, my name is Chatbot, I'm an AI created by FindMe, I'm your assistant and I'm designed to help you use this application.");
manager.addAnswer('en','faq',"Hello, I'm Chatbot, I'm an AI assitant created by FindMe, my job is to help you have a better experience using this application.");
manager.addAnswer('en','faq',"Hi there, I'm Chatbot, How can I assist you?");

//age
manager.addAnswer('en','age',"Age is just a number. You're only as old as you feel.");
manager.addAnswer('en','age',"I was created recently.");
manager.addAnswer('en','age',"I don't have an age in the way humans do, but I was created by FindMe.");

//help
manager.addAnswer("en","help","I'm glad to help. What can I do for you?");
manager.addAnswer("en","help","Sure. I'd be happy to. What's up?");
manager.addAnswer("en","help","Of course, I'll certainly try my best.");

//thanking
manager.addAnswer("en", "thanking", "It's my pleasure to help.");
manager.addAnswer("en", "thanking", "Anytime. That's what I'm here for.");
manager.addAnswer("en", "thanking", "You're welcome.");

//user back
manager.addAnswer("en", "user.back", "Welcome back. What can I do for you?");
manager.addAnswer("en", "user.back", "Good to have you here. What can I do for you?");




//search.general
manager.addAnswer('en','search.general',"Sure, do you have any specifications?");
manager.addAnswer('en','search.general',"Sure, is there any specifications for the product you are looking for?");
//manager.addAnswer('en','shirt',"Nah, we don't have "+couleur+" shirts.");


//user search product
manager.addAnswer('en','search.product',"Do you have any color in your mind?");
manager.addAnswer('en','search.product',"That's it?");
manager.addAnswer('en','search.product',"Is there a specific color?");

//colors
manager.addAnswer('en','search.color',"Got it, is that it?");
manager.addAnswer('en','search.color',"Nice, I'm pretty sure that this color will suit you well, is that all?");
manager.addAnswer('en','search.color',"Perfect, with no doubt this color will look amazing on you, any other specifications?");

//search.final yes
manager.addAnswer('en','search.final',"Great, let me help you find what you are looking for, first of all, navigate to the home page, there you can find in the top right a filter icon where you can select different criteria such as size, the region you're willing to shop from, colors and you can choose how to sort results based on different fields also you can search directly a product by entering his name or scanning his QR or barcode, there's also the possibility to check categories where you can find similar results of what you're looking for.");

//no
manager.addAnswer('en','search.negation',"I'm sorry, please tell me more, I'm all ears.");
manager.addAnswer('en','search.negation',"I apologize, please keep providing me with informations.");
manager.addAnswer('en','search.negation',"Alright, what's more?");

//size
manager.addAnswer('en','search.size',"Understood, is that all?");
manager.addAnswer('en','search.size',"Got it, will that be everything?");

//category
manager.addAnswer('en','search.category',"Got it, will that be everything?");
manager.addAnswer('en','search.category',"Ok, to find products similar to the category you're looking for, you can check the category page and choose one of many and it will display a variety of products in this context.");

//brand
manager.addAnswer('en','search.brand',"You can search the product from the home page and you can filter you reserch by adding a sort method based on the brand");;

//train model
(async () => {
    await manager.train();
    manager.save();
  })();


// Process user input
module.exports.discuss = async (req,res) => {

    const { message } = req.body;
    if (!message) {
        return res.status(400).json({ error: 'Message is required' });
      }
      try {
        const response = await manager.process('en', message);
        const reply = response && response.answer ? response.answer : "Sorry, I don't understand, please reformulate the sentence.";
        res.status(200).json({ chatbot: reply, response: response });
      } catch (err) {
        console.error('Error processing message:', err);
        res.status(500).json({ error: 'Internal Server Error' });
      }
  };