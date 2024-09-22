import React from 'react';
import axios from 'axios';
import { Accordion } from 'rsuite';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../context/ApiContext';

const Support = () => {
  const { register, handleSubmit, formState: { errors } } = useForm(); // Capture des erreurs du formulaire
  const { api_url } = useApi();

  // Mutation pour l'envoi du rapport
  const reportMutation = useMutation({
     mutationFn: async (data) => {
         return await axios.post(`${api_url}/api/admin/report`, {
             email: data.email,
             type: data.type,
             content: data.message
         }, { withCredentials: true });
     },
     onSuccess: () => {
         alert('Email envoyé, votre demande sera traitée dans les plus brefs délais.');
     },
     onError: (error) => {
         alert(error.response.data.message);
     }
  });

  // Gestion de la soumission du formulaire
  const onSubmit = (data) => {
    reportMutation.mutate(data); // Lancer la mutation
  };

  return (
    <section className='page-support'>
      <div className='page-support-content'>
        <h1>Centre d'aide</h1>
      </div>
      <div className='page-support-container'>
        <div className='page-support-container-content'>
          <div className='page-support-container-content-title'>
            <Accordion defaultActiveKey={1} bordered>
              <Accordion.Panel header="⚠️ Comment signaler un problème ?" eventKey={1}>
                <p>Pour signaler un problème, que ce soit sur la plateforme Anonym ou avec un autre utilisateur lors d'une discussion, ou pour nous faire part de tout autre souci lié à notre plateforme, vous pouvez le faire via ce formulaire.</p>
                <p>❗Tout abus de signalement sera sanctionné par l'équipe Anonym.</p>
              </Accordion.Panel>
              <Accordion.Panel header="Comment fonctionne le système de réputation ?" eventKey={2}>
                <p>Le système de réputation se base sur le nombre de messages envoyés à d'autres utilisateurs.</p>
                <p>Pour obtenir un multiplicateur de réputation, il est nécessaire d'acquérir un élément de personnalisation depuis la boutique.</p>
              </Accordion.Panel>
              <Accordion.Panel header="Je n'arrive plus à me connecter, comment faire ?" eventKey={3}>
              <p>Si vous rencontrez des problèmes lors de votre connexion, que vous n'avez reçu aucun message de notre part ou qu'aucun message n'apparaît lorsque vous saisissez vos identifiants, n'hésitez pas à nous envoyer un message via ce formulaire.</p>
              <p>❗Tout abus de signalement sera sanctionné par l'équipe Anonym.</p>
              </Accordion.Panel>
              <Accordion.Panel header="Quelles sont les informations recueillies par Anonym ?" eventKey={4}>
              <p>Nous pouvons collecter les types de données suivants :</p>
              <ul>
                <li>Données de connexion : nom d'utilisateur, adresse e-mail, mot de passe.</li>
                <li>Données de paiement : factures.</li>
                <li>Données de navigation : pages visitées, clics, préférences.</li>
              </ul>
              <p>Pour plus d'informations, n'hésitez pas à consulter notre page : Politique de confidentialité.</p>
              </Accordion.Panel>
              <Accordion.Panel header="🖖 Comment soutenir l'équipe Anonym ?" eventKey={5}>
              <p>Pour soutenir l'équipe Anonym, vous pouvez nous envoyer un don qui sera reversé à l'équipe de développement du projet.</p>
              <p>Si vous souhaitez vraiment soutenir Anonym, n'hésitez pas à acheter un élément de personnalisation pour votre profil.</p>
              </Accordion.Panel>
            </Accordion>
          </div>
          <div className="form-container report-in">
            <form onSubmit={handleSubmit(onSubmit)}>
                <h1 className='report-in-title'>Envoyer une demande</h1>
                <span>❗Formulaire pour nous signaler un problème</span>
                <input className="input-report" type="email" placeholder="Email" {...register("email", { required: true })}/>
                <select className="select-report" type='select'  {...register("type", { required: true })}>
                  <option value="">Type de demande</option>
                  <option value="Signalement d'utilisateur">Signalement d'utilisateur</option>
                  <option value="Problème sur la plateforme">Problème sur la plateforme</option>
                  <option value="autres">Autres</option>
                </select>
                <textarea className="textarea-report" type="text" placeholder="Message" {...register("message", { required: true })}/>
                <button className='submit-report'>Submit</button>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Support;