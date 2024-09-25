import React, { useState } from "react";
import { Link, useNavigate  } from "react-router-dom";
import Profils from "../components/Profile/Profils";
import Account from "../components/Profile/Account";
import Inventory from "../components/Profile/Inventory";
import Invoices from "../components/Profile/Invoices";
import { useUser } from '../context/UserContext';
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faXmark, faDoorOpen } from "@fortawesome/free-solid-svg-icons";
import { Modal, Button } from 'rsuite';

const Profile = () => {
    const { user, logout, setUser } = useUser();
    const [typeProfils, setTypeProfils] = useState('Profils');
    const [deleteModalOpen, setDeleteModalOpen] = useState(false); 
    const navigate = useNavigate(); // Hook pour rediriger après la déconnexion
    const roles = ["ADMIN", "SUPER_ADMIN"];
    const hasRole = roles.includes(user.roles);

    const handleLogout = async () => {
        await logout(); // Appelle la fonction logout
        navigate('/');  // Redirige vers la page d'accueil après la déconnexion
    };

    return (
        <div id="profile">
            <div className="container-fluid">
                <div className="row flex-nowrap">
                    <div className="col-auto col-sm-3 px-0 sidebar">
                        <div className="d-flex flex-column px-3 align-items-center align-items-sm-start text-white min-vh-100 sidebar-content">
                            <ul className="profile-sidebar nav nav-pills flex-column mb-0 align-items-center align-items-sm-start" id="menu">
                                <span className="profile-category"><strong>Paramètres utilisateur</strong></span>
                                <li className="nav-item">
                                    <span onClick={() => setTypeProfils('Profils')} className={`link-sidebar ${typeProfils === 'Profils' ? 'link-sidebar-active' : ''}`}>Mon Compte</span>
                                </li>
                                <li className="nav-item">
                                    <span onClick={() => setTypeProfils('Account')} className={`link-sidebar ${typeProfils === 'Account' ? 'link-sidebar-active' : ''}`}>Profil</span>
                                </li>
                                {hasRole && (
                                    <li className="nav-item">
                                        <span onClick={() => navigate('/admin')} className={`link-sidebar ${typeProfils === 'Admin' ? 'link-sidebar-active' : ''}`}>Admin DashBoard</span>
                                    </li>
                                )}
                            </ul>
                            <hr/>
                            <ul className="profile-sidebar nav nav-pills flex-column mb-0 align-items-center align-items-sm-start" id="menu">
                                <span className="profile-category"><strong>Paramètres de facturation</strong></span>
                                <li className="nav-item">
                                    <span onClick={() => setTypeProfils('Invoices')} className={`link-sidebar ${typeProfils === 'Invoices' ? 'link-sidebar-active' : ''}`}>Facturation</span>
                                </li>
                            </ul>
                            <hr />
                            <ul className="profile-sidebar nav nav-pills flex-column mb-0 align-items-center align-items-sm-start" id="menu">
                                <span className="profile-category"><strong>Paramètres de l'appli</strong></span>
                                <li className="nav-item">
                                    <span onClick={() => setTypeProfils('Inventory')} className={`link-sidebar ${typeProfils === 'Inventory' ? 'link-sidebar-active' : ''}`}>Inventaire</span>
                                </li>
                            </ul>
                            <hr />
                            <ul className="profile-sidebar nav nav-pills flex-column mb-0 align-items-center align-items-sm-start" id="menu">
                                <li className="nav-item">
                                <span onClick={() => setDeleteModalOpen(true)}  className="ms-1 d-none d-sm-inline link-sidebar link-side-exit">Déconnexion <FontAwesomeIcon icon={faDoorOpen}/></span>
                                </li>
                            </ul>
                            {/* Modal pour la suppression du compte */}
                            <Modal open={deleteModalOpen} onClose={() => setDeleteModalOpen(false)} size="xs">
                                <Modal.Header>
                                    <Modal.Title>Déconnexion</Modal.Title>
                                </Modal.Header>
                                <Modal.Body>
                                    Êtes-vous sûr(e) de vouloir vous déconnecter ?
                                </Modal.Body>
                                <Modal.Footer>
                                    <Button onClick={() => setDeleteModalOpen(false)} appearance="subtle">
                                        Annuler
                                    </Button>
                                    <Button onClick={handleLogout} color="red">
                                        Déconnexion
                                    </Button>
                                </Modal.Footer>
                            </Modal>
                            <hr />
                        </div>
                    </div>
                    <div className="profile-container col">
                        {typeProfils === 'Profils' ? (
                            <Profils user={user} setTypeProfils={setTypeProfils} setUser={setUser}/>
                        ) : typeProfils === 'Account' ? (
                            <Account user={user} setUser={setUser}/>
                        ) : typeProfils === 'Invoices' ? (
                            <Invoices/>
                        ) : typeProfils === 'Inventory' && (
                            <Inventory user={user}/>
                        )}
                        <div className="container-link">
                            <Link to='/app' className="container-link-esc">
                            <span>
                                <FontAwesomeIcon icon={faXmark}/>
                            </span>
                            ESC
                            </Link>   
                        </div>
                    </div>
                </div>
            </div>

        </div>
    )
}

export default Profile;