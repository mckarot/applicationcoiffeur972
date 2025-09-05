const admin = require('firebase-admin');

// --- CONFIGURATION ---
// 1. Assurez-vous d'avoir votre fichier de clé de compte de service
//    nommé 'serviceAccountKey.json' à la racine de votre projet.
const serviceAccount = require('./serviceAccountKey.json');

// 2. Récupérez les données à importer depuis votre fichier JSON.
const dataToImport = require('./services_a_importer.json');

// 3. Spécifiez le nom de la collection Firestore où vous voulez ajouter les données.
const collectionName = 'haircut_services';
// --- FIN DE LA CONFIGURATION ---


// Initialisation de l'application Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function populateCollection() {
  const collectionRef = db.collection(collectionName);
  console.log(`Début du remplissage de la collection "${collectionName}"...`);

  for (const item of dataToImport) {
    try {
      // Ajoute des champs supplémentaires si nécessaire
      const newItem = {
        ...item,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      await collectionRef.add(newItem);
      console.log(`Document ajouté pour le service : "${item.name}"`);
    } catch (error) {
      console.error(`Erreur lors de l'ajout du service "${item.name}":`, error);
    }
  }

  console.log("Remplissage de la collection terminé !");
}

// Appel de la fonction pour démarrer le processus
populateCollection();