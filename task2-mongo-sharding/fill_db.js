use somedb
for(var i = 0; i < 1000; i++) {
    db.helloDoc.insert({age:i, name:"ly"+i});
}
print("Documents count: " + db.helloDoc.countDocuments());
