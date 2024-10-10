import { useState } from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useAuth } from '../../../context/AuthContext';
import { useUser } from '../../../context/UserContext';

const Register = ({setStatusAccess}) => {
  const { register, handleSubmit, formState: { errors }, } = useForm();
  const { AnonymIsClose } = useAuth();
  const { registered } = useUser();
  const [showMessage, setShowMessage] = useState(false);
  const [messageError, setMessageError] = useState('');
  const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API

  // Utiliser `useMutation` pour gérer la requête de login
  const mutation = useMutation({
    mutationFn: async (data) => {
      const response = await axios.post(`${api_url}/api/auth/signup`, {
        username: data.name,
        email: data.email,
        password: data.password
      }, { withCredentials: true });
      return response.data;
    },
    onSuccess: (data) => {
      // Appeler la fonction `login` du contexte pour stocker l'utilisateur
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
