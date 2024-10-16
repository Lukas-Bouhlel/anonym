const nodemailer = require('nodemailer');

/**
 * Crée un transporteur pour l'envoi d'e-mails en utilisant Nodemailer.
 *
 * @param {Object} config - La configuration du service de messagerie.
 * @param {string} config.service - Le service de messagerie (par exemple, 'gmail').
 * @param {Object} config.auth - Informations d'authentification pour le service de messagerie.
 * @param {string} config.auth.user - Adresse e-mail utilisée pour l'envoi des e-mails.
 * @param {string} config.auth.pass - Mot de passe ou token pour l'authentification.
 * @returns {Object} - Objet contenant la fonction `sendEmail` pour l'envoi des e-mails.
 */
module.exports = (config) => {
  const transporter = nodemailer.createTransport(config);

    /**
   * Envoie un e-mail avec les options spécifiées.
   *
   * @async
   * @function sendEmail
   * @param {string} to - Adresse e-mail du destinataire.
   * @param {string} subject - Sujet de l'e-mail.
   * @param {string} [text=''] - Contenu texte brut de l'e-mail (facultatif).
   * @param {string} [html=''] - Contenu HTML de l'e-mail (facultatif).
   * @param {Array<Object>} [attachments=[]] - Liste des pièces jointes (facultatif).
   * @returns {Promise<Object>} - Résultat de l'envoi de l'e-mail.
   * @throws {Error} - Lance une erreur si l'envoi de l'e-mail échoue.
   *
   * @example
   * const { sendEmail } = require('./mailer')({
   *   service: 'gmail',
   *   auth: { user: 'your-email@gmail.com', pass: 'your-password' }
   * });
   * 
   * sendEmail('destinataire@example.com', 'Sujet', 'Contenu en texte', '<h1>Contenu HTML</h1>')
   *   .then(info => console.log('E-mail envoyé:', info))
   *   .catch(err => console.error('Erreur:', err));
   */
  const sendEmail = async (to, subject, text = '', html = '', attachments = []) => {
    const mailOptions = {
      from: config.auth.user, // Utiliser l'adresse e-mail configurée
      to,                     // Destinataire de l'e-mail
      subject,                // Sujet de l'e-mail
      text,                   // Contenu texte brut de l'e-mail (optionnel)
      html,                   // Contenu HTML de l'e-mail (optionnel)
      attachments             // Ajouter les pièces jointes ici
    };

    try {
      // Utiliser 'await' pour gérer l'envoi d'e-mail
      const info = await transporter.sendMail(mailOptions);
      return info;
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email :', error);
      throw error; // Propager l'erreur pour la gérer plus haut
    }
  };

  // Retourner la fonction d'envoi d'email
  return { sendEmail };
};
