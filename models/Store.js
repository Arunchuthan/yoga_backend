const mongoose = require('mongoose');

const StoreSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    imageUrl: { type: String, required: true } // Publicly accessible image URL
});

module.exports = mongoose.model('Store', StoreSchema);