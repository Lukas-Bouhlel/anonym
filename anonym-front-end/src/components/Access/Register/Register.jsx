import React from 'react';
import axios from 'axios';
import { useForm } from "react-hook-form";
import { useMutation  } from '@tanstack/react-query';
import { useApi } from '../../../context/ApiContext';
import { useUser } from '../../../context/UserContext'; 
import { useNavigate } from 'react-router-dom';

const Register = () => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
    const { registered } = useUser(); 
    const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
    const navigate = useNavigate();

    // Utiliser `useMutation` pour gérer la requête de login
    const mutation = useMutation({
        mutationFn: async (data) => {
          console.log(data)
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
            console.log('Login successful:', data.user);
            navigate(`/app`);
        },
        onError: (data) => {
          console.log(data.response.data.message);
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
        <span>utilisez votre email pour l'inscription</span>
        <input type="text" placeholder="Name" {...register("name", { required: true })}/>
        <input type="email" placeholder="Email" {...register("email", { required: true })}/>
        <input type="password" placeholder="Password" {...register("password", { required: true })}/>
        <button type="submit">S'inscrire</button>
      </form>
    </div>
  );
};

export default Register;
