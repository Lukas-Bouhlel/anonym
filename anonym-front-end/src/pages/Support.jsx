import { useState } from 'react';
import axios from 'axios';
import { Accordion } from 'rsuite';
import { useForm } from "react-hook-form";
import { useMutation } from '@tanstack/react-query';
import { useApi } from '../context/ApiContext';
import { usePopup } from '../context/PopupContext';
import { Helmet } from 'react-helmet-async';

/**
 * Composant Support qui gère la soumission des rapports d'assistance
 * et affiche des informations sur le fonctionnement de la plateforme.
 *
 * @component
 * @returns {React.ReactElement} - Le composant de support.
 */
const Support = () => {
  const { register, handleSubmit, formState: { errors } } = useForm();
  const [messageError, setMessageError] = useState('');
  const [showMessage, setShowMessage] = useState(false);
  const { setOpenPopup, setTextPopup, setState } = usePopup();
  const { api_url } = useApi();

  const reportMutation = useMutation({
    /**
     * Fonction pour l'envoi du rapport
     * Elle envoie une requête POST avec les informations du rapport et est envoyé au support par mail.
     * @param {Object} data - Les données à envoyer (email, type, message)
     * @returns {Promise<Object>} - Les données de la réponse si l'envoi du rapport est confirmé.
     */
    mutationFn: async (data) => {
      return await axios.post(`${api_url}/api/admin/report`, {
        email: data.email,
        type: data.type,
        content: data.message
      }, { withCredentials: true });
    },
    onSuccess: () => {
      setOpenPopup(true);
      setTextPopup('Email envoyé, votre demande sera traitée dans les plus brefs délais !');
      setState('success');
      setShowMessage(false);
      setMessageError('');
    },
    onError: (error) => {
      setShowMessage(true);
      setMessageError(error.response.data.message);
    }
  });

  // Gestion de la soumission du formulaire
  const onSubmit = (data) => {
    reportMutation.mutate(data);
  };

  return (
    <section className='page-support'>
      <Helmet>
        <title>Centre d&apos;aide - Anonym</title>
        <meta name="description" content="Besoin d'aide ? Notre page Support vous guide à travers nos services, FAQ et contact. Obtenez des réponses rapides à toutes vos questions." />
        <link rel="canonical" href={`https://www.ano-nym.fr/support`} />
      </Helmet>
      <div className='page-support-content'>
        <h1>Centre d&apos;aide</h1>
      </div>
      <div className='page-support-container'>
        <div className='page-support-container-content'>
          <div className='page-support-container-content-title'>
            <Accordion defaultActiveKey={1} bordered>
              <Accordion.Panel header="⚠️ Comment signaler un problème ?" eventKey={1}>
                <p>Pour signaler un problème, que ce soit sur la plateforme Anonym ou avec un autre utilisateur lors d&apos;une discussion, ou pour nous faire part de tout autre souci lié à notre plateforme, vous pouvez le faire via ce formulaire.</p>
                <p>❗Tout abus de signalement sera sanctionné par l&apos;équipe Anonym.</p>
              </Accordion.Panel>
              <Accordion.Panel header="Comment fonctionne le système de réputation ?" eventKey={2}>
                <p>Le système de réputation se base sur le nombre de messages envoyés à d&apos;autres utilisateurs.</p>
                <p>Pour obtenir un multiplicateur de réputation, il est nécessaire d&apos;acquérir un élément de personnalisation depuis la boutique.</p>
              </Accordion.Panel>
              <Accordion.Panel header="Je n'arrive plus à me connecter, comment faire ?" eventKey={3}>
                <p>Si vous rencontrez des problèmes lors de votre connexion, que vous n&apos;avez reçu aucun message de notre part ou qu&apos;aucun message n&apos;apparaît lorsque vous saisissez vos identifiants, n&apos;hésitez pas à nous envoyer un message via ce formulaire.</p>
                <p>❗Tout abus de signalement sera sanctionné par l&apos;équipe Anonym.</p>
              </Accordion.Panel>
              <Accordion.Panel header="Quelles sont les informations recueillies par Anonym ?" eventKey={4}>
                <p>Nous pouvons collecter les types de données suivants :</p>
                <ul>
                  <li>Données de connexion : nom d&apos;utilisateur, adresse e-mail, mot de passe.</li>
                  <li>Données de paiement : factures.</li>
                  <li>Données de navigation : pages visitées, clics, préférences.</li>
                </ul>
                <p>Pour plus d&apos;informations, n&apos;hésitez pas à consulter notre page : Politique de confidentialité.</p>
              </Accordion.Panel>
              <Accordion.Panel header="🖖 Comment soutenir l'équipe Anonym ?" eventKey={5}>
                <p>Pour soutenir l&apos;équipe Anonym, vous pouvez nous envoyer un don qui sera reversé à l&apos;équipe de développement du projet.</p>
                <p>Si vous souhaitez vraiment soutenir Anonym, n&apos;hésitez pas à acheter un élément de personnalisation pour votre profil.</p>
              </Accordion.Panel>
            </Accordion>
          </div>
          <div className="form-container report-in">
            <form onSubmit={handleSubmit(onSubmit)}>
              <h1 className='report-in-title'>Envoyer une demande</h1>
              <span>❗Formulaire pour nous signaler un problème</span>
              <input aria-required="true" aria-label="Email" className="input-report" type="email" placeholder="Email" {...register("email", { required: "L'adresse email est requise" })} />
              <select aria-label="Type" className="select-report" type='select'  {...register("type", { required: "Le type de demande est requis" })}>
                <option value="">Type de demande</option>
                <option value="Signalement d'utilisateur">Signalement d&apos;utilisateur</option>
                <option value="Problème sur la plateforme">Problème sur la plateforme</option>
                <option value="autres">Autres</option>
              </select>
              <textarea className="textarea-report" type="text" placeholder="Message" {...register("message", { required: "Le contenu de votre demande est requis" })} />
              <button className='submit-report'>Submit</button>
            </form>
            {/* Gestion de l'affichage des erreurs */}
            {(showMessage || (errors.email || errors.type || errors.message)) &&
              !errors.email && !errors.password && (
                <p className='error-message-form'>{messageError}</p>
            )}
            {/* Affichage des messages d'erreur si tous les champs sont remplis */}
            {(errors.email || errors.type || errors.message) && (
              <p className='error-message-form'>
                {errors.email?.message || errors.type?.message || errors.message?.message}
              </p>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};

export default Support;