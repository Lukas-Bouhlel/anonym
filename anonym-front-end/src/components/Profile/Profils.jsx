import { useState } from "react";
import PropTypes from 'prop-types';
import axios from "axios";
import { useNavigate  } from "react-router-dom";
import { Modal, Button } from 'rsuite';
import { useApi } from '../../context/ApiContext';
import Popup from "../Utils/Popup";
import { usePopup } from '../../context/PopupContext';

/**
 * Composant Profils pour gérer les informations de l'utilisateur et les actions de compte.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {Object} props.user - Les informations de l'utilisateur.
 * @param {Function} props.setTypeProfils - Fonction pour changer le type de profil.
 * @param {Function} props.setUser - Fonction pour mettre à jour l'utilisateur.
 * @returns {JSX.Element} - Le rendu du composant Profils.
 */
const Profils = ({user, setTypeProfils, setUser}) => {
    const [open, setOpen] = useState(false);
    const [size, setSize] = useState();
    const [deleteModalOpen, setDeleteModalOpen] = useState(false); 
    const [currentPassword, setCurrentPassword] = useState("");
    const [newPassword, setNewPassword] = useState("");
    const [confirmNewPassword, setConfirmNewPassword] = useState("");
    const [errorMessage, setErrorMessage] = useState("");
    const [showPopup, setShowPopup] = useState(false);
    const { setOpenPopup, setTextPopup, setState } = usePopup();// Utilise le contexte pour gérer la popup
    const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
    const navigate = useNavigate(); 

    /**
     * Ouvre la modal pour changer le mot de passe.
     * @param {string} value - La taille de la modal.
     */
    const handleOpen = value => {
      setSize(value);
      setOpen(true);
    };

    /**
     * Ferme la modal pour changer le mot de passe.
     */
    const handleClose = () => setOpen(false);

    /**
     * Supprime le compte de l'utilisateur via l'API.
     */
    const handleDeleteAccount = async () => {
        try {
            await axios.delete(`${api_url}/api/account/delete`, {
                withCredentials: true
            });
            setUser(null);
            setOpenPopup(true);
            setTextPopup('Votre compte a été supprimé. Nous espérons vous revoir bientôt sur notre plateforme !');
            setState('error');
            navigate('/');
        } catch (error) {
            console.error("Erreur lors de la suppression du compte:", error);
        }
    };

    /**
     * Met à jour le mot de passe de l'utilisateur via l'API.
     * @param {Object} e - L'événement de soumission du formulaire.
     */
    const handleSubmit = async (e) => {
        e.preventDefault();

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
                setShowPopup(true);
            }
        } catch (error) {
            setErrorMessage(error.response?.data?.message || "Une erreur est survenue.");
        }
    };

    return (
        <div id="profils">
            <Popup showPopup={showPopup} setShowPopup={setShowPopup} text={'Votre mot de passe a bien été mis à jour !'} state={'update'}/>
            <div className="profils-title">
                <h1>Mon Compte</h1>
            </div>
            <div className="profils-infos">
                <div className="profils-infos-first">
                    <div className="profile-content-infos-img">
                        {user.Inventories?.[0]?.Shop?.content && (
                            <img className="avatar-profile decoration-profile" src={`${user.Inventories[0].Shop.content}`} alt="hugenerd" width="80" height="80"/>
                        )}
                        <img src={`${user.avatar}`} alt="hugenerd" width="80" height="80" className="rounded-circle avatar-profile" />
                    </div>
                    <button onClick={() => setTypeProfils('Account')} className="profils-infos-button">Modifier profil d&apos;utilisateur</button>
                </div>
                <div className="profils-infos-content">
                    <div className="profils-infos-content-item">
                        <div>
                            <h3>Nom d&apos;utilisateur</h3>
                            <span>{user.username}</span>
                        </div>
                        <button onClick={() => setTypeProfils('Account')} >Modifier</button>
                    </div>
                    <div className="profils-infos-content-item">
                        <div>
                            <h3>E-mail</h3>
                            <span>{user.email}</span>
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
                    {errorMessage && <div className="error-message" style={{ color: "red" }}>{errorMessage}</div>}
                    <form onSubmit={handleSubmit}>
                        <div className="mb-3">
                            <label htmlFor="currentPassword" className="form-label">Mot de passe actuel</label>
                            <input aria-required="true" aria-label="Mot de passe actuel" type="password" className="form-control" id="currentPassword" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} required />
                        </div>
                        <div className="mb-3">
                            <label htmlFor="newPassword" className="form-label">Nouveau mot de passe</label>
                            <input aria-required="true" aria-label="Nouveau mot de passe" type="password" className="form-control" id="newPassword" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} required />
                        </div>
                        <div className="mb-3">
                            <label htmlFor="confirmNewPassword" className="form-label">Confirmer le nouveau mot de passe</label>
                            <input aria-required="true" aria-label="Confirmer le nouveau mot de passe" type="password" className="form-control" id="confirmNewPassword" value={confirmNewPassword} onChange={(e) => setConfirmNewPassword(e.target.value)} required />
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

Profils.propTypes = {
    user: PropTypes.shape({
        avatar: PropTypes.string,
        username: PropTypes.string,
        email: PropTypes.string,
        Inventories: PropTypes.arrayOf(
            PropTypes.shape({
                Shop: PropTypes.shape({
                    content: PropTypes.string
                })
            })
        )
    }).isRequired,
    setTypeProfils: PropTypes.func.isRequired,
    setUser: PropTypes.func.isRequired
};

export default Profils;