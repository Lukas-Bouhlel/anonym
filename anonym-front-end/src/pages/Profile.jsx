import { useState, useRef } from "react";
import { Link, useNavigate  } from "react-router-dom";
import Profils from "../components/Profile/Profils";
import Account from "../components/Profile/Account";
import Inventory from "../components/Profile/Inventory";
import Invoices from "../components/Profile/Invoices";
import { useUser } from '../context/UserContext';
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faXmark, faDoorOpen } from "@fortawesome/free-solid-svg-icons";
import { Modal, Button } from 'rsuite';

/**
 * Composant Profile qui représente la page de profil de l'utilisateur.
 * Il permet à l'utilisateur de gérer ses informations de profil, de facturation, et d'inventaire,
 * ainsi que de se déconnecter de l'application.
 *
 * @component
 * @returns {React.ReactElement} - L'interface de la page de profil.
 */
const Profile = () => {
    const { user, logout, setUser } = useUser();
    const [typeProfils, setTypeProfils] = useState('Profils');
    const [deleteModalOpen, setDeleteModalOpen] = useState(false); 
    const [isSidebarOpen, setIsSidebarOpen] = useState(false); 
    const [isDragging, setIsDragging] = useState(false);
    const sidebarRef = useRef(null);
    const navigate = useNavigate();
    const roles = ["ADMIN", "SUPER_ADMIN"];
    const hasRole = user && roles.includes(user.roles);

    /**
     * Gère la déconnexion de l'utilisateur en appelant la fonction logout et redirige vers la page d'accueil.
     */
    const handleLogout = async () => {
        await logout(); 
        navigate('/'); 
    };

    /**
     * Gère le début du glissement pour ouvrir ou fermer la barre latérale.
     */
    const handleTouchStart = () => {
        setIsDragging(true);
    };

    /**
     * Gère le mouvement du touché pour déterminer s'il faut ouvrir ou fermer la barre latérale.
     * @param {TouchEvent} e - L'événement de touché.
     */
    const handleTouchMove = (e) => {
        if (isDragging) {
            const touch = e.touches[0];
            if (touch.clientX > 50) {
                // Ouvrir la sidebar si le glissement est suffisant
                setIsSidebarOpen(true);
            } else if (touch.clientX < 30) {
                // Fermer la sidebar si le glissement vers la gauche est suffisant
                setIsSidebarOpen(false);
            }
        }
    };

    /**
     * Gère la fin du glissement.
     */
    const handleTouchEnd = () => {
        setIsDragging(false);
    };

    return (
        <div id="profile">
            <div className="container-fluid">
                <div className="row flex-nowrap">
                    <div 
                        className={`sidebar col-auto px-0 ${isSidebarOpen ? 'open' : ''}`}
                        ref={sidebarRef}
                        onTouchStart={handleTouchStart}
                        onTouchMove={handleTouchMove}
                        onTouchEnd={handleTouchEnd}
                        >
                        <div className="d-flex flex-column px-3 align-items-center align-items-sm-start text-white min-vh-100 sidebar-content">
                            <ul className="profile-sidebar nav nav-pills flex-column mb-0 align-items-center align-items-sm-start" id="menu">
                                <span className="profile-category"><strong>Paramètres utilisateur</strong></span>
                                <li className="nav-item">
                                    <span onClick={() => {setTypeProfils('Profils'); setIsSidebarOpen(false);}} className={`link-sidebar ${typeProfils === 'Profils' ? 'link-sidebar-active' : ''}`}>Mon Compte</span>
                                </li>
                                <li className="nav-item">
                                    <span onClick={() => {setTypeProfils('Account'); setIsSidebarOpen(false);}} className={`link-sidebar ${typeProfils === 'Account' ? 'link-sidebar-active' : ''}`}>Profil</span>
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
                                    <span onClick={() => {setTypeProfils('Invoices'); setIsSidebarOpen(false);}} className={`link-sidebar ${typeProfils === 'Invoices' ? 'link-sidebar-active' : ''}`}>Facturation</span>
                                </li>
                            </ul>
                            <hr />
                            <ul className="profile-sidebar nav nav-pills flex-column mb-0 align-items-center align-items-sm-start" id="menu">
                                <span className="profile-category"><strong>Paramètres de l&apos;appli</strong></span>
                                <li className="nav-item">
                                    <span onClick={() => {setTypeProfils('Inventory'); setIsSidebarOpen(false);}} className={`link-sidebar ${typeProfils === 'Inventory' ? 'link-sidebar-active' : ''}`}>Inventaire</span>
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
                            <div>
                                <span>
                                    <FontAwesomeIcon icon={faXmark}/>
                                </span>
                                ESC
                            </div>
                            </Link>   
                        </div>
                    </div>
                </div>
            </div>

        </div>
    )
}

export default Profile;