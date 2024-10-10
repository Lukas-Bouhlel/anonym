import { useState } from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useUser } from '../../../context/UserContext'; 
import { useNavigate } from 'react-router-dom';

const Login = ({setStatusForm, setStatusAccess}) => {
    const { register, handleSubmit, formState: { errors }, } = useForm();
    const [showMessage, setShowMessage] = useState(false);
    const [messageError, setMessageError] = useState('');
    const { login } = useUser(); 
    const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
    const navigate = useNavigate();

    // Utiliser `useMutation` pour gérer la requête de login
    const mutation = useMutation({
        mutationFn: async (data) => {
            const response = await axios.post(`${api_url}/api/auth/login`, {
                identifier: data.email,
                password: data.password,
            }, { withCredentials: true });
            return response.data;
        },
        onSuccess: (data) => {
            login(data.user);
            navigate(`/app`);
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
                <h1>Se connecter</h1>
                <span>utilisez votre e-mail et votre mot de passe</span>
                <input  aria-label={"Email"} aria-required="true" type="text" placeholder="Email" {...register("email", { required: "L'adresse email est requise." })}/>
                <input aria-label={"Mot de passe"} aria-required="true" type="password" placeholder="Mot de passe" {...register("password", { required: "Le mot de passe est requis" })}/>
                <a className="link-login-or-password-reset" onClick={() => setStatusForm('resetPassword')}>Mot de passe oublié ?</a>
                <button>Se connecter</button>
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
                <p onClick={() => setStatusAccess(true)}className='mobile-redirect-register-or-login'>S&apos;inscrire</p>
            </form>
        </div>
    )
}

Login.propTypes = {
    setStatusForm: PropTypes.func.isRequired, // Function to set form status
    setStatusAccess: PropTypes.func.isRequired, // Function to set access status
};

export default Login;