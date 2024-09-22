import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useNavigate } from 'react-router-dom';

const Reset = () => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
    const { api_url } = useApi();
    const navigate = useNavigate();
    const [token, setToken] = useState('');

    // Extraction du token de l'URL à partir des query params
    useEffect(() => {
        const params = new URLSearchParams(location.search); // Récupère les paramètres de l'URL
        const tokenFromUrl = params.get('token'); // Récupère le token
        setToken(tokenFromUrl); // Met à jour le state avec le token
    }, [location.search]);

    // Mutation pour la réinitialisation du mot de passe
    const resetPasswordMutation = useMutation({
        mutationFn: async (data) => {
            return await axios.post(`${api_url}/api/auth/reset?token=${token}`, {
                password: data.password,
                confirmPassword: data.confirmPassword
            }, { withCredentials: true });
        },
        onSuccess: () => {
            alert('Mot de passe réinitialisé avec succès');
            navigate('/'); // Redirection après le succès
        },
        onError: (error) => {
            alert('Erreur lors de la réinitialisation: ' + error.response.data.message);
        }
    });

    // Gestion de la soumission du formulaire
    const onSubmit = (data) => {
        if (data.password !== data.confirmPassword) {
            alert("Les mots de passe ne correspondent pas.");
            return;
        }
        resetPasswordMutation.mutate(data); // Lancer la mutation
    };

    return (
        <div className='reset'>
            <form className="reset-form" onSubmit={handleSubmit(onSubmit)}>
                <h1>Réinitialisation</h1>
                <span>Renseigner votre nouveau mot de passe</span>
                <input type="password" placeholder='Mot de passe' {...register("password", { required: true })} />
                <input type="password" placeholder="Mot de passe de confirmation" {...register("confirmPassword", { required: true })} />
                <button>Valider</button>
            </form>
        </div>
    )
}
export default Reset;