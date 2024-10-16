import { useState } from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useAuth } from '../../../context/AuthContext';
import { useUser } from '../../../context/UserContext';

/**
 * Composant Register.
 * Ce composant gère le formulaire d'inscription pour les nouveaux utilisateurs.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {Function} props.setStatusAccess - Fonction pour changer le statut d'accès (connexion ou inscription).
 * @returns {JSX.Element} Le rendu du formulaire d'inscription.
 */
const Register = ({setStatusAccess}) => {
  const { register, handleSubmit, formState: { errors }, } = useForm();
  const { AnonymIsClose } = useAuth();// Utilise le contexte pour fermer le modal d'inscription
  const { registered } = useUser();// Utilise le contexte pour effectuer le register
  const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
  const [showMessage, setShowMessage] = useState(false);
  const [messageError, setMessageError] = useState('');

  // Utiliser `useMutation` pour gérer la requête d'inscription
  const mutation = useMutation({
    /**
     * Fonction pour gérer la requête d'inscription de l'utilisateur.
     * @param {Object} data - Les données d'inscription de l'utilisateur.
     * @param {string} data.name - Le nom d'utilisateur.
     * @param {string} data.email - L'adresse email de l'utilisateur.
     * @param {string} data.password - Le mot de passe de l'utilisateur.
     * @returns {Promise<Object>} - Les données de l'utilisateur inscrit.
     */
    mutationFn: async (data) => {
      const response = await axios.post(`${api_url}/api/auth/signup`, {
        username: data.name,
        email: data.email,
        password: data.password
      }, { withCredentials: true });
      return response.data;
    },
    onSuccess: (data) => {
      registered(data.user);
      AnonymIsClose();
      setShowMessage(false);
      setMessageError('');
    },
    onError: (data) => {
      setShowMessage(true);
      setMessageError(data.response.data.message);
    },
  });

  // Gestion de la soumission du formulaire
  const onSubmit = (data) => {
    mutation.mutate(data); // Lancer la mutation avec les données du formulaire
  };

  return (
    <div className="form-container sign-up">
      <form onSubmit={handleSubmit(onSubmit)}>
        <h1>Créer un compte</h1>
        <span>utilisez votre email pour l&apos;inscription</span>
        <input aria-label={"Name"} aria-required="true" type="text" placeholder="Name" {...register("name", { required: "Le nom d'utilisateur est requis" })} />
        <input aria-label={"Email"} aria-required="true" type="email" placeholder="Email" {...register("email", { required: "L'adresse email est requise" })} />
        <input aria-label={"Mot de passe"} aria-required="true" type="password" placeholder="Mot de passe" {...register("password", { required: "Le mot de passe est requis" })} />
        <button type="submit">S&apos;inscrire</button>
        <p onClick={() => setStatusAccess(false)} className='mobile-redirect-register-or-login'>Se connecter</p>
      </form>
      {/* Gestion de l'affichage des erreurs */}
      {(showMessage || (errors.email || errors.password || errors.name)) &&
        !errors.email && !errors.password && (
          <p className='error-message-form'>{messageError}</p>
        )}

      {/* Affichage des messages d'erreur si tous les champs sont remplis */}
      {(errors.email || errors.password) && (
        <p className='error-message-form'>
          {errors.email?.message || errors.password?.message}
        </p>
      )}
    </div>
  );
};

Register.propTypes = {
  setStatusAccess: PropTypes.func.isRequired,
};

export default Register;
