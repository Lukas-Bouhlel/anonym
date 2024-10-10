import { useEffect, useState } from "react";
import PropTypes from 'prop-types'; 
import axios from "axios";
import { useForm } from "react-hook-form";
import { useApi } from '../../context/ApiContext';
import Popup from "../Utils/Popup";

const Account = ({ user, setUser }) => {
    const [avatarFile, setAvatarFile] = useState(null);
    const [previewUsername, setPreviewUsername] = useState(user?.username || "");
    const [previewAvatar, setPreviewAvatar] = useState(user?.avatar || "");
    const [showPopup, setShowPopup] = useState(false);
    const { api_url } = useApi();

    const { register, handleSubmit, setValue, reset, formState: { errors } } = useForm({
        defaultValues: {
            username: user.username || "",
            email: user?.email || ""
        }
    });

    // Mettre à jour les valeurs du formulaire et les aperçus après une mise à jour du compte (user)
    useEffect(() => {
        reset({
            username: user?.username || "",
            email: user?.email || ""
        });
        setPreviewUsername(user?.username || "");
    }, [user, reset]);

    const onSubmit = async (data) => {
        const formData = new FormData();

        const jsonData = {
            username: data.username,
            email: data.email,
        };

         // Si l'avatar est supprimé, l'ajouter dans le JSON
        if (data.avatar === "delete") {
            jsonData.avatar = "delete"; // Indiquer dans le JSON que l'avatar est supprimé
        }

        // Ajouter l'objet JSON sous forme de chaîne dans formData
        formData.append('datas', JSON.stringify(jsonData));
    
        if (avatarFile) {
            formData.append('image', avatarFile); // Ajouter l'avatar en tant que fichier
        }
        
        try {
            // Envoi du formulaire
            const response = await axios.put(`${api_url}/api/account/update`, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
                withCredentials: true
            });
            setShowPopup(true);
            setUser(response.data);
            reset(); // Réinitialise les champs du formulaire
            setAvatarFile(null); // Réinitialise le fichier local
            setPreviewAvatar(""); // Supprime l'avatar dans l'aperçu
        } catch (error) {
            console.error("Erreur lors de la soumission du formulaire :", error);
        }
    };

    // Fonction pour gérer l'upload de fichier
    const handleFileChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            setAvatarFile(file); // Enregistre le fichier dans l'état
            setPreviewAvatar(URL.createObjectURL(file)); // Met à jour l'aperçu de l'avatar
        }
    };

    // Fonction pour gérer la suppression de l'avatar
    const handleDeleteAvatar = () => {
        setValue('avatar', 'delete'); // Définit la valeur avatar à 'delete'
        setAvatarFile(null); // Réinitialise le fichier local
        setPreviewAvatar(""); // Supprime l'avatar dans l'aperçu
    };

    // Mise à jour du username en temps réel
    const handleUsernameChange = (e) => {
        setPreviewUsername(e.target.value); // Met à jour l'aperçu du nom d'utilisateur
    };

    // Fonction pour gérer le reset du formulaire et des états locaux
    const handleReset = () => {
        reset(); // Réinitialise les champs du formulaire
        setPreviewUsername(user?.username || ""); // Réinitialise le nom d'utilisateur à sa valeur initiale
        setPreviewAvatar(user?.avatar || ""); // Réinitialise l'avatar à sa valeur initiale
        setAvatarFile(null); // Réinitialise le fichier local de l'avatar
    };

    return (
        <div id="account">
            <Popup showPopup={showPopup} setShowPopup={setShowPopup} text={'Votre profil a bien été mis à jour !'} state={'update'}/>
            <div className="account-title">
                <h1>Profils</h1>
            </div>
            <div className="account">
                <div className="account-content">
                    <form onSubmit={handleSubmit(onSubmit)}>
                        <div className="mb-3">
                            <label htmlFor="username" className="form-label">Nom d&apos;utilisateur</label>
                            <input
                                type="text"
                                className="form-control"
                                id="username"
                                aria-required="true" 
                                aria-label="Nom d'utilisateur"
                                {...register("username", { required: "Le nom d'utilisateur est requis" })}
                                onChange={handleUsernameChange}
                            />
                            {errors.username && <span className="text-danger">{errors.username.message}</span>}
                        </div>

                        <div className="mb-3">
                            <label htmlFor="email" className="form-label">E-mail</label>
                            <input
                                type="email"
                                className="form-control"
                                aria-required="true" 
                                aria-label="E-mail"
                                id="email"
                                {...register("email", {
                                    required: "L'email est requis",
                                    pattern: {
                                        value: /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/,
                                        message: "Le format de l'email est incorrect"
                                    }
                                })}
                            />
                            {errors.email && <span className="text-danger">{errors.email.message}</span>}
                        </div>

                        <div className="mb-3">
                            <label htmlFor="avatar" className="form-label">Avatar</label>
                            <div className="content-file-edit">
                                <input
                                    aria-label="Avatar"
                                    type="file"
                                    className="form-control input-file"
                                    id="avatar"
                                    onChange={handleFileChange}
                                />
                                <button
                                    type="button"
                                    className="btn"
                                    onClick={handleDeleteAvatar}
                                >
                                    Supprimer l&apos;avatar
                                </button>
                            </div>
                            {avatarFile && <p>Avatar sélectionné : {avatarFile.name}</p>}
                        </div>
                        <div className="account-content-footer-input">
                            <button type="button" className="btn account-content-footer-input-reset" onClick={() => handleReset()}>
                                Réinitialiser
                            </button>
                            <button type="submit" className="btn account-content-footer-input-submit">
                                Enregistrer
                            </button>
                        </div>
                    </form>
                </div>
                <div className="account-view">
                    <h2>Aperçu</h2>
                    <div className="profils-infos">
                        <div className="profils-infos-first">
                            <div className="profile-content-infos-img">
                                {user?.Inventories?.[0]?.Shop?.content && (
                                    <img className="avatar-profile decoration-profile" src={`${user.Inventories[0].Shop.content}`} alt="hugenerd" width="80" height="80"/>
                                )}
                                <img className="rounded-circle avatar-profile image-profile" src={`${previewAvatar || user.avatar}`} alt="hugenerd" width="80" height="80" />
                            </div>
                        </div>
                        <div className="profils-infos-content">
                            <div className="profils-infos-content-item">
                                <div>
                                    <span>{previewUsername}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div >
    )
}

Account.propTypes = {
    user: PropTypes.shape({
        avatar: PropTypes.string,
        username: PropTypes.string.isRequired,
        email: PropTypes.string.isRequired,
        Inventories: PropTypes.arrayOf(
            PropTypes.shape({
                Shop: PropTypes.shape({
                    content: PropTypes.string
                })
            })
        )
    }).isRequired,
    setUser: PropTypes.func.isRequired,
};

export default Account;