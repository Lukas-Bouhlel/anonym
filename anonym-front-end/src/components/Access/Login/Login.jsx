import { useState } from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useUser } from '../../../context/UserContext'; 
import { useNavigate } from 'react-router-dom';

/**
 * Composant Login.
 * Ce composant gère le formulaire de connexion pour les utilisateurs existants.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {Function} props.setStatusForm - Fonction pour changer le statut du formulaire (connexion ou réinitialisation du mot de passe).
 * @returns {JSX.Element} Le rendu du formulaire de connexion.
 */
const Login = ({setStatusForm}) => {
    const { register, handleSubmit, formState: { errors }, } = useForm();
    const [showMessage, setShowMessage] = useState(false);
    const [messageError, setMessageError] = useState('');
    const { login } = useUser();// Utilise le contexte pour effectuer le login
    const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
    const navigate = useNavigate();

    const mutation = useMutation({
         /**
         * Fonction pour gérer la requête de connexion de l'utilisateur.
         * @param {Object} data - Les données de connexion de l'utilisateur.
         * @param {string} data.email - L'email de l'utilisateur.
         * @param {string} data.password - Le mot de passe de l'utilisateur.
         * @returns {Promise<Object>} - Les données de l'utilisateur connecté.
         */
        mutationFn: async (data) => {
            const response = await axios.post(`${api_url}/api/admin/login`, {
                identifier: data.email,
                password: data.password,
            }, { withCredentials: true });
            return response.data;
        },
        onSuccess: (data) => {
            login(data.user);
            navigate(`/admin`);
            setShowMessage(false);
            setMessageError('');
        },
        onError: (data) => {
            setShowMessage(true);
            setMessageError(data.response.data.message);
        }
    });

    // Gestion de la soumission du formulaire
    const onSubmit = (data) => {
        mutation.mutate(data); // Lancer la mutation avec les données du formulaire
    };

    return ( 
        <div className="form-container sign-in">
            <form onSubmit={handleSubmit(onSubmit)}>
                <h2>Se connecter</h2>
                <span>utilisez votre e-mail et votre mot de passe</span>
                <input  aria-label={"Email"} aria-required="true" type="text" placeholder="Email" {...register("email", { required: "L'adresse email est requise." })}/>
                <input aria-label={"Mot de passe"} aria-required="true" type="password" placeholder="Mot de passe" {...register("password", { required: "Le mot de passe est requis" })}/>
                <span className="link-login-or-password-reset" onClick={() => setStatusForm('resetPassword')}>Mot de passe oublié ?</span>
                <button className="login-submit">Se connecter</button>
                {/* Gestion de l'affichage des erreurs */}
                <p className='error-message-form' aria-live="assertive">
                    {(showMessage || (errors.email || errors.password)) && 
                        !errors.email && !errors.password && ( 
                            messageError
                    )}
                    
                    {(errors.email || errors.password) && (
                        errors.email?.message || errors.password?.message
                    )}
                </p>
            </form>
        </div>
    )
}

Login.propTypes = {
    setStatusForm: PropTypes.func.isRequired,
};

export default Login;
