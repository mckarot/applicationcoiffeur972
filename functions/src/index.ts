import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
// Importation spécifique pour les fonctions v2
import {https} from "firebase-functions/v2";

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function appelable pour supprimer un utilisateur et toutes ses
 * données associées.
 */
export const deleteUserAndData = https.onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    // 1. Vérifier que l'utilisateur qui appelle la fonction est bien un admin
    if (request.auth?.token.role !== "admin") {
      throw new https.HttpsError(
        "permission-denied",
        "Seul un administrateur peut supprimer un utilisateur."
      );
    }

    const uidToDelete = request.data.uid;
    if (!uidToDelete || typeof uidToDelete !== "string") {
      throw new https.HttpsError(
        "invalid-argument",
        "L'UID de l'utilisateur à supprimer est manquant ou invalide."
      );
    }

    try {
      // 2. Supprimer l'utilisateur de Firebase Authentication
      await admin.auth().deleteUser(uidToDelete);
      functions.logger.log(
        `Utilisateur ${uidToDelete} supprimé de l'authentification.`
      );

      // 3. Utiliser un "batch" pour supprimer toutes les données Firestore
      const batch = db.batch();

      // Supprimer le document de la collection 'users'
      const userDocRef = db.collection("users").doc(uidToDelete);
      batch.delete(userDocRef);

      // Supprimer les horaires de travail
      const schedulesQuery = db
        .collection("coiffeur_work_schedules")
        .where("coiffeur_user_id", "==", uidToDelete);
      const schedulesSnapshot = await schedulesQuery.get();
      schedulesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

      // Supprimer les absences
      const absencesQuery = db
        .collection("coiffeur_absences")
        .where("coiffeur_user_id", "==", uidToDelete);
      const absencesSnapshot = await absencesQuery.get();
      absencesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

      // Gérer les rendez-vous existants
      const appointmentsQuery = db
        .collection("appointments")
        .where("coiffeur_user_id", "==", uidToDelete);
      const appointmentsSnapshot = await appointmentsQuery.get();
      appointmentsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          coiffeur_user_id: null,
          coiffeur_name: "Coiffeur supprimé",
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // 4. Exécuter toutes les opérations de suppression
      await batch.commit();
      functions.logger.log(
        `Données Firestore de l'utilisateur ${uidToDelete} supprimées.`
      );

      return {
        success: true,
        message: `Le user ${uidToDelete} et ses données ont été supprimés.`,
      };
    } catch (error) {
      functions.logger.error(
        `Erreur lors de la suppression de l'utilisateur ${uidToDelete}:`,
        error
      );
      throw new https.HttpsError(
        "internal",
        "Une erreur est survenue lors de la suppression de l'utilisateur.",
        error
      );
    }
  }
);

