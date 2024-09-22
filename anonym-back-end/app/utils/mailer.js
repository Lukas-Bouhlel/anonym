const nodemailer = require('nodemailer');

module.exports = (config) => {
  const transporter = nodemailer.createTransport(config);

  // Fonction d'envoi d'email
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
      console.log('Email envoyé : ' + info.response);
      return info;
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email :', error);
      throw error; // Propager l'erreur pour la gérer plus haut
    }
  };

  // Retourner la fonction d'envoi d'email
  return { sendEmail };
};
