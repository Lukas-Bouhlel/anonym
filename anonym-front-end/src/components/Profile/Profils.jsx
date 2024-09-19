import React, { useState } from "react";
import axios from "axios";
import { useNavigate  } from "react-router-dom";
import { Modal, Button } from 'rsuite';
import { useApi } from '../../context/ApiContext';

const Profils = ({user, setTypeProfils}) => {
    const [open, setOpen] = useState(false);
    const [size, setSize] = useState();
    const [deleteModalOpen, setDeleteModalOpen] = useState(false); 
    const [currentPassword, setCurrentPassword] = useState("");
    const [newPassword, setNewPassword] = useState("");
    const [confirmNewPassword, setConfirmNewPassword] = useState("");
    const [errorMessage, setErrorMessage] = useState("");
    const { api_url } = useApi();
    const navigate = useNavigate(); 

    const handleOpen = value => {
      setSize(value);
      setOpen(true);
    };

    const handleClose = () => setOpen(false);

    const handleDeleteAccount = async () => {
        try {
            // Appel API pour supprimer le compte
            await axios.delete(`${api_url}/api/account/delete`, {
                withCredentials: true
            });
            // Redirige vers la page de déconnexion ou d'accueil après suppression
            navigate('/');
        } catch (error) {
            console.error("Erreur lors de la suppression du compte:", error);
        }
    };

    // Fonction de validation du mot de passe
    const validatePassword = (password) => {
        const passwordRegex = /^(?!.*\s).{8,}$/;
        return passwordRegex.test(password);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        // Validation du nouveau mot de passe avant soumission
        if (!validatePassword(newPassword)) {
            setErrorMessage("Le mot de passe doit contenir au moins 8 caractères et ne pas inclure d'espaces.");
            return;
        }

        if (newPassword !== confirmNewPassword) {
            setErrorMessage("Les nouveaux mots de passe ne correspondent pas.");
            return;
        }

        try {
            const response = await axios.put(`${api_url}/api/account/password`, {
                currentPassword,
                newPassword,
                confirmNewPassword
            }, {
                withCredentials: true // Pour inclure les cookies JWT
            });

            if (response.status === 200) {
                handleClose();
            }
        } catch (error) {
            setErrorMessage(error.response?.data?.message || "Une erreur est survenue.");
        }
    };

    return (
        <div id="profils">
            <div className="profils-title">
                <h1>Mon Compte</h1>
            </div>
            <div className="profils-infos">
                <div className="profils-infos-first">
                    <img src={`${user.avatar}`} alt="hugenerd" width="80" height="80" className="rounded-circle" />
                    <button onClick={() => setTypeProfils('Account')} className="profils-infos-button">Modifier profil d'utilisateur</button>
                </div>
                <div className="profils-infos-content">
                    <div className="profils-infos-content-item">
                        <div>
                            <h3>Nom d'affichage</h3>
                            <span>{user.username}</span>
                        </div>
                        <button onClick={() => setTypeProfils('Account')} >Modifier</button>
                    </div>
                    <div className="profils-infos-content-item">
                        <div>
                            <h3>E-mail</h3>
                            <span>{user.username}</span>
                        </div>
                        <button onClick={() => setTypeProfils('Account')} >Modifier</button>
                    </div>
                </div>
            </div>
            <div className="profils-password">
                <h3>Mot de passe et authentification</h3>
                <button onClick={() => handleOpen('xs')} className="profils-infos-button">Changer le mot de passe</button>
            </div>
            <div className="profils-delete">
                <h4>Suppression du compte</h4>
                <button onClick={() => setDeleteModalOpen(true)} className="profils-infos-button">Supprimer le compte</button>
            </div>
            {/* Modal pour changement de mot de passe */}
            <Modal size={size} open={open} onClose={handleClose}>
                <Modal.Header>
                <Modal.Title>Mets ton mot de passe à jour</Modal.Title>
                Saisis ton mot de passe actuel puis le nouveau
                </Modal.Header>
                <Modal.Body>
                    {errorMessage && <div style={{ color: "red" }}>{errorMessage}</div>}
                    <form onSubmit={handleSubmit}>
                        <div className="mb-3">
                            <label htmlFor="currentPassword" className="form-label">Mot de passe actuel</label>
                            <input type="password" className="form-control" id="currentPassword" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} required />
                        </div>
                        <div className="mb-3">
                            <label htmlFor="newPassword" className="form-label">Nouveau mot de passe</label>
                            <input type="password" className="form-control" id="newPassword" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} required />
                        </div>
                        <div className="mb-3">
                            <label htmlFor="confirmNewPassword" className="form-label">Confirmer le nouveau mot de passe</label>
                            <input type="password" className="form-control" id="confirmNewPassword" value={confirmNewPassword} onChange={(e) => setConfirmNewPassword(e.target.value)} required />
                        </div>
                        <Modal.Footer>
                            <Button onClick={handleClose} appearance="subtle">
                                Annuler
                            </Button>
                            <Button type="submit" className="btn btn-primary" onClick={handleSubmit}>
                                Terminé
                            </Button>
                        </Modal.Footer>
                    </form>
                </Modal.Body>
            </Modal>
             {/* Modal pour la suppression du compte */}
             <Modal open={deleteModalOpen} onClose={() => setDeleteModalOpen(false)} size="xs">
                <Modal.Header>
                    <Modal.Title>Confirmation de suppression</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.
                </Modal.Body>
                <Modal.Footer>
                    <Button onClick={handleDeleteAccount} color="red">
                        Supprimer
                    </Button>
                    <Button onClick={() => setDeleteModalOpen(false)} appearance="subtle">
                        Annuler
                    </Button>
                </Modal.Footer>
            </Modal>
        </div>
    )
}

export default Profils;