import React from 'react';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useUser } from '../../../context/UserContext'; 
import { useNavigate } from 'react-router-dom';

const Login = () => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
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
            // Appeler la fonction `login` du contexte pour stocker l'utilisateur
            login(data.user);
            // console.log('Login successful:', data.user);
            navigate(`/app`);
        },
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
                <input type="text" placeholder="Email" {...register("email", { required: true })}/>
                <input type="password" placeholder="mot de passe" {...register("password", { required: true })}/>
                <a href="#">Mot de passe oublié ?</a>
                <button>Se connecter</button>
            </form>
        </div>
    )
}
export default Login;