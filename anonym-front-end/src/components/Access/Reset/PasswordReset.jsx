import React, { useState } from 'react';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { usePopup } from '../../../context/PopupContext';

const PasswordReset = ({setStatusForm}) => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
    const { api_url } = useApi();
    const { setOpenPopup, setTextPopup, setState } = usePopup();
    const [messageError, setMessageError] = useState('');
    const [showMessage, setShowMessage] = useState(false);

     // Mutation pour la réinitialisation du mot de passe
     const resetPasswordMutation = useMutation({
        mutationFn: async (data) => {
            return await axios.post(`${api_url}/api/auth/reset-password`, {
                email: data.email,
            }, { withCredentials: true });
        },
        onSuccess: () => {
            setOpenPopup(true);
            setShowMessage(false);
            setTextPopup('Email envoyé pour la réinitialisation de votre mot de passe');
            setState('update');
            setMessageError('');
        },
        onError: (error) => {
            setShowMessage(true);
            setMessageError(error.response.data.message);
        }
    });

    // Gestion de la soumission du formulaire
    const onSubmit = (data) => {
        resetPasswordMutation.mutate(data); // Lancer la mutation de réinitialisation
    };

    return ( 
        <div className="form-container sign-in">
            <form onSubmit={handleSubmit(onSubmit)}>
                <h1>Réinitialiser</h1>
                <span>Réinitialisez votre mot de passe avec votre e-mail</span>
                <input 
                    type='email'
                    placeholder='E-mail'
                    {...register("email", { required: 'L\'adresse email est requise' })}
                />
                <a className="link-login-or-password-reset" onClick={() => setStatusForm('login')}>
                    Se connecter ?
                </a>
                <button>Réinitialiser</button>
            </form>

            {/* Gestion de l'affichage des erreurs */}
            {(showMessage || (errors.email)) && 
                !errors.email && ( 
                    <p className='error-message-form'>{messageError}</p>
            )}
      
            {/* Affichage des messages d'erreur si tous les champs sont remplis */}
            {(errors.email) && (
                <p className='error-message-form'>
                    {errors.email?.message}
                </p>
            )}
        </div>
    );
}
export default PasswordReset;