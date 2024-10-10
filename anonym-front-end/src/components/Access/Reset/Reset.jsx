import { useEffect, useState } from 'react';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useNavigate } from 'react-router-dom';
import { usePopup } from '../../../context/PopupContext';

const Reset = () => {
    const { register, handleSubmit, formState: { errors }, } = useForm();
    const { api_url } = useApi();
    const navigate = useNavigate();
    const [token, setToken] = useState('');
    const { setOpenPopup, setTextPopup, setState } = usePopup();
    const [messageError, setMessageError] = useState('');
    const [showMessage, setShowMessage] = useState(false);

    // Extraction du token de l'URL à partir des query params
    useEffect(() => {
        const params = new URLSearchParams(window.location.search); // Récupère les paramètres de l'URL
        const tokenFromUrl = params.get('token'); // Récupère le token
        setToken(tokenFromUrl); // Met à jour le state avec le token
    }, []);

    // Mutation pour la réinitialisation du mot de passe
    const resetPasswordMutation = useMutation({
        mutationFn: async (data) => {
            return await axios.post(`${api_url}/api/auth/reset?token=${token}`, {
                password: data.password,
                confirmPassword: data.confirmPassword
            }, { withCredentials: true });
        },
        onSuccess: () => {
            navigate('/');
            setOpenPopup(true);
            setShowMessage(false);
            setState('success');
            setTextPopup('Mot de passe réinitialisé avec succès');
            setMessageError('');
        },
        onError: (error) => {
            setShowMessage(true);
            setMessageError(error.response.data.message);
        }
    });

    // Gestion de la soumission du formulaire
    const onSubmit = (data) => {
        resetPasswordMutation.mutate(data); // Lancer la mutation
    };

    return (
        <div id='reset'>
            <div className='reset'>
                <form className="reset-form" onSubmit={handleSubmit(onSubmit)}>
                    <h1>Réinitialisation</h1>
                    <span>Renseigner votre nouveau mot de passe</span>
                    <input aria-label={"Mot de passe"} aria-required="true" type="password" placeholder='Mot de passe' {...register("password", { required: 'Le mot de passe est requis' })} />
                    <input aria-label={"Mot de passe de confirmation"} aria-required="true" type="password" placeholder="Mot de passe de confirmation" {...register("confirmPassword", { required: 'Le mot de passe de confirmation est requis' })} />
                    <button>Valider</button>
                </form>
                {/* Gestion de l'affichage des erreurs */}
                {(showMessage || (errors.password || errors.confirmPassword)) &&
                    !errors.password && !errors.confirmPassword && (
                        <p className='error-message-form'>{messageError}</p>
                    )}

                {/* Affichage des messages d'erreur si tous les champs sont remplis */}
                {(errors.password || errors.confirmPassword) && (
                    <p className='error-message-form'>
                        {errors.password?.message || errors.confirmPassword?.message}
                    </p>
                )}
            </div>
        </div>
    )
}
export default Reset;