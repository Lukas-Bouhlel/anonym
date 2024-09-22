import React from 'react';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';

const PasswordReset = ({setStatusForm}) => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
    const { api_url } = useApi();

     // Mutation pour la réinitialisation du mot de passe
     const resetPasswordMutation = useMutation({
        mutationFn: async (data) => {
            return await axios.post(`${api_url}/api/auth/reset-password`, {
                email: data.email,
            }, { withCredentials: true });
        },
        onSuccess: () => {
            alert('Email envoyé pour la réinitialisation du mot de passe');
        },
        onError: (error) => {
            alert('Erreur lors de la réinitialisation: ' + error.response.data.message);
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
                    {...register("email", { required: true })}
                />
                <a className="link-login-or-password-reset" onClick={() => setStatusForm('login')}>
                    Se connecter ?
                </a>
                <button>Réinitialiser</button>
            </form>
        </div>
    );
}
export default PasswordReset;