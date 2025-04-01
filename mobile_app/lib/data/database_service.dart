import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static List<String> docIDs = [];

  static Future updateDocumentIds(String collection) async {
    docIDs = [];
    await FirebaseFirestore.instance
        .collection(collection)
        .get()
        .then(
          (snapshot) => snapshot.docs.forEach((document) {
            print(document.reference.id);
            docIDs.add(document.reference.id);
          }),
        );
  }

  static Future<String> getUserNameByEmail(String email) async {
    CollectionReference users = FirebaseFirestore.instance.collection(
      "user_data",
    );

    print("Fetching user with email: $email");

    QuerySnapshot querySnapshot =
        await users.where("email", isEqualTo: email).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      print("User found: ${userData["name"]}");
      return userData["name"] ?? "User";
    }

    print("No user found for email: $email");
    return "User";
  }
}
