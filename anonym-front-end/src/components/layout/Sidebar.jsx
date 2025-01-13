import { useState, useRef } from "react";
import PropTypes from 'prop-types'; 
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser, faShop, faGear, faXmark } from '@fortawesome/free-solid-svg-icons';
import { Tooltip, Whisper, Modal, Button, Badge } from 'rsuite';
import { useApi } from '../../context/ApiContext';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';

/**
 * Composant Sidebar pour afficher la barre latérale de navigation de l'application.
 *
 * Ce composant permet à l'utilisateur de naviguer entre différentes pages, de gérer ses canaux de messages,
 * de quitter des canaux et d'accéder à son profil.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {Object} props.user - Les informations de l'utilisateur connecté.
 * @param {string} props.page - La page actuelle affichée.
 * @param {Function} props.setPage - Fonction pour changer la page affichée.
 * @param {Function} props.setModalVisible - Fonction pour gérer la visibilité du modal de création de canal.
 * @param {Object} props.canal - Les informations sur le canal actuel.
 * @param {Function} props.setChannel - Fonction pour définir le canal actuel.
 * @param {Object} props.socket - L'instance de socket.io pour la communication en temps réel.
 * @returns {JSX.Element} - Le rendu du composant Sidebar.
 */
const Sidebar = ({ user, page, setPage, setModalVisible, canal, setChannel, socket }) => {
    const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
    const [leaveChannelModalVisible, setLeaveChannelModalVisible] = useState(false);
    const [currentChannelId, setCurrentChannelId] = useState(null);
    const [isSidebarOpen, setIsSidebarOpen] = useState(false); // État pour savoir si la sidebar est ouverte
    const [isDragging, setIsDragging] = useState(false); // État pour savoir si l'utilisateur ouvre la sidebar en mobile
    const sidebarRef = useRef(null);

    const tooltip = (
        <Tooltip>
            Paramètres utilisateur
        </Tooltip>
    );

    /**
     * Fonction pour récupérer les canaux de l'utilisateur via l'API.
     * @returns {Promise<Array>} - Liste des canaux de l'utilisateur.
     */
    const fetchUserChannels = async () => {
        try {
            const response = await axios.get(`${api_url}/api/channels/user`, {
                withCredentials: true,
            });
            return response.data; // Supposons que les canaux viennent avec le compte de messages non lus
        } catch (error) {
            throw new Error(error);
        }
    };

    const { data: channels = [], isLoading, refetch } = useQuery({
        queryKey: ['channels'], 
        queryFn: fetchUserChannels,
    });

    /**
     * Fonction pour quitter un canal.
     * Envoie une requête DELETE à l'API et émet un événement pour le socket.
     */
    const confirmLeaveChannel = async () => {
        try {
            await axios.delete(`${api_url}/api/channels/leave/${currentChannelId}`, {
                withCredentials: true,
            });
            socket.emit('leaveChannel', { channelId: currentChannelId });
            refetch();
            setPage('friends')
            setLeaveChannelModalVisible(false); // Ferme la modal après avoir quitté
            setCurrentChannelId(null); // Réinitialise l'ID du canal courant
        } catch (error) {
            console.error("Erreur lors de la suppression du canal:", error);
        }
    };

    /**
     * Fonction pour gérer la demande de sortie d'un canal.
     * @param {string} channelId - ID du canal à quitter.
     */
    const handleLeaveChannel = (channelId) => {
        setCurrentChannelId(channelId);
        setLeaveChannelModalVisible(true); // Ouvre la modal de confirmation
    };

    /**
     * Fonction pour rejoindre un canal.
     * @param {Object} channel - Les informations du canal à rejoindre.
     */
    const handleJoinChannel = (channel) => {
        setPage('canal');
        setChannel(channel);
        refetch();
    }

    const handleTouchStart = () => {
        setIsDragging(true);
    };

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

    const handleTouchEnd = () => {
        setIsDragging(false);
    };

    return (
        <>
            <div className={`sidebar col-auto px-0 ${isSidebarOpen ? 'open' : ''}`}
                ref={sidebarRef}
                onTouchStart={handleTouchStart}
                onTouchMove={handleTouchMove}
                onTouchEnd={handleTouchEnd}>
                <div className="flex-column align-items-center align-items-sm-start text-white min-vh-100 sidebar-content">
                    <ul className="nav px-3 nav-pills flex-column mb-sm-auto mb-0 align-items-center align-items-sm-start" id="menu">
                        <li className="nav-item">
                            <Link onClick={() => {setPage('friends'); setIsSidebarOpen(false);}} className={`nav-link align-middle link-sidebar ${page === 'friends' ? 'active-link' : ''}`}>
                                <span className="ms-1 d-sm-inline"><FontAwesomeIcon icon={faUser} /> Amis</span>
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link onClick={() => {setPage('shop'); setIsSidebarOpen(false);}} className={`nav-link align-middle link-sidebar ${page === 'shop' ? 'active-link' : ''}`}>
                                <span className="ms-1 d-sm-inline"><FontAwesomeIcon icon={faShop} /> Boutique</span>
                            </Link>
                        </li>
                        <li>
                            <div className="message-mp" onClick={() => setModalVisible(true)}>
                                <span className="ms-1 d-sm-inline link-create-channel">Messages privés</span>
                                <a href="#">+</a>
                            </div>
                            <ul className="collapse show nav flex-column ms-1" id="submenu1" data-bs-parent="#menu">
                                {isLoading ? (
                                    <li>Chargement des canaux...</li>
                                ) : channels.length > 0 ? (
                                    channels.map(channel => (
                                        <li className="w-100" key={channel.channel_id}>
                                            <Badge content={channel.unreadCount !== 0 && channel.unreadCount}>
                                                <Link className={`link-channels align-middle link-sidebar ${`${page}-${canal && canal.channel_id}` === `canal-${channel.channel_id}` ? 'active-link' : ''}`}>
                                                    <span onClick={() => {handleJoinChannel(channel); setIsSidebarOpen(false);}} className="d-sm-inline">{channel.name}</span>
                                                    <FontAwesomeIcon onClick={() => handleLeaveChannel(channel.channel_id)} icon={faXmark} />
                                                </Link>
                                            </Badge>
                                        </li>
                                    ))
                                ) : (
                                    <li>Aucun canal trouvé</li>
                                )}
                            </ul>
                        </li>
                    </ul>
                    <hr />
                    <div className="pb-2 px-sm-2 sidebar-profile">
                        <div className="d-flex align-items-center sidebar-profile-content">
                            <div className="sidebar-profile-content-infos">
                                <div className="profile-content-infos-img">
                                    {user?.Inventories?.[0]?.Shop?.content && (
                                        <img className="avatar-profile decoration-profile" src={`${user.Inventories[0].Shop.content}`} alt="hugenerd" width="40" height="40" />
                                    )}
                                    <img className="rounded-circle avatar-profile image-profile" src={`${user.avatar}`} alt="hugenerd" width="40" height="40" />
                                </div>
                                <span className="d-sm-inline mx-1">
                                    <strong>{user.username}</strong>
                                </span>
                            </div>
                            <Whisper placement="top" controlId="control-id-hover" trigger="hover" speaker={tooltip}>
                                <Link to="/profile" className="open-params">
                                    <FontAwesomeIcon icon={faGear} />
                                </Link>
                            </Whisper>
                        </div>
                    </div>
                </div>
            </div>
            {/* Modal pour quitter le canal */}
            <Modal
                open={leaveChannelModalVisible}
                onClose={() => setLeaveChannelModalVisible(false)}
            >
                <Modal.Header>
                    <Modal.Title>Quitter le canal</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    Êtes-vous sûr de vouloir quitter ce canal ?
                </Modal.Body>
                <Modal.Footer>
                    <Button onClick={() => setLeaveChannelModalVisible(false)} appearance="subtle">Annuler</Button>
                    <Button onClick={confirmLeaveChannel} color="red" appearance="primary">Confirmer</Button>
                </Modal.Footer>
            </Modal>
        </>
    )
}

Sidebar.propTypes = {
    user: PropTypes.shape({
        avatar: PropTypes.string.isRequired,
        username: PropTypes.string.isRequired,
        Inventories: PropTypes.arrayOf(
            PropTypes.shape({
                Shop: PropTypes.shape({
                    content: PropTypes.string,
                }),
            })
        ),
    }).isRequired,
    page: PropTypes.string.isRequired,
    setPage: PropTypes.func.isRequired,
    setModalVisible: PropTypes.func.isRequired,
    canal: PropTypes.shape({
        channel_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    }),
    setChannel: PropTypes.func.isRequired,
    socket: PropTypes.object.isRequired,
};

export default Sidebar;