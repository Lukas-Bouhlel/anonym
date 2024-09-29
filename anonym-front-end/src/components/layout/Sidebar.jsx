import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser, faShop, faGear, faXmark } from '@fortawesome/free-solid-svg-icons';
import { Tooltip, Whisper, Modal, Button, Badge } from 'rsuite';
import { useApi } from '../../context/ApiContext';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';

const Sidebar = ({ user, page, setPage, setModalVisible, canal, setChannel, socket }) => {
    const { api_url } = useApi();
    const [leaveChannelModalVisible, setLeaveChannelModalVisible] = useState(false);
    const [currentChannelId, setCurrentChannelId] = useState(null);

    const tooltip = (
        <Tooltip>
            Paramètres utilisateur
        </Tooltip>
    );

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

    const { data: channels = [], error, isLoading, refetch } = useQuery({
        queryKey: ['channels'], // Clé de la requête pour le caching
        queryFn: fetchUserChannels, // Fonction de récupération des canaux
    });

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

    const handleLeaveChannel = (channelId) => {
        setCurrentChannelId(channelId);
        setLeaveChannelModalVisible(true); // Ouvre la modal de confirmation
    };

    const handleJoinChannel = (channel) => {
        setPage('canal'); 
        setChannel(channel);
        refetch();
    }
    

    return (
        <>
            <div className="col-auto px-0 sidebar">
                <div className="d-flex flex-column align-items-center align-items-sm-start text-white min-vh-100 sidebar-content">
                    <ul className="nav px-3 nav-pills flex-column mb-sm-auto mb-0 align-items-center align-items-sm-start" id="menu">
                        <li className="nav-item">
                            <Link onClick={() => setPage('friends')} className={`nav-link align-middle link-sidebar ${page === 'friends' ? 'active-link' : ''}`}>
                                <span className="ms-1 d-none d-sm-inline"><FontAwesomeIcon icon={faUser}/> Amis</span>
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link onClick={() => setPage('shop')} className={`nav-link align-middle link-sidebar ${page === 'shop' ? 'active-link' : ''}`}>
                                <span className="ms-1 d-none d-sm-inline"><FontAwesomeIcon icon={faShop}/> Boutique</span>
                            </Link>
                        </li>
                        <li>
                            <div className="message-mp"  onClick={() => setModalVisible(true)}>
                                <span className="ms-1 d-none d-sm-inline link-create-channel">Messages privés</span>
                                <a href="#">+</a>
                            </div>
                            <ul className="collapse show nav flex-column ms-1" id="submenu1" data-bs-parent="#menu">
                                {isLoading ? (
                                    <span>Chargement des canaux...</span>
                                ) : channels.length > 0 ? (
                                    channels.map(channel => (
                                        <li className="w-100" key={channel.channel_id}>
                                            <Badge content={channel.unreadCount !== 0 && channel.unreadCount}>
                                                <Link className={`link-channels align-middle link-sidebar ${`${page}-${canal && canal.channel_id}` === `canal-${channel.channel_id}` ? 'active-link' : ''}`}>
                                                    <span onClick={() => handleJoinChannel(channel)} className="d-none d-sm-inline">{channel.name}</span>
                                                    <FontAwesomeIcon onClick={() => handleLeaveChannel(channel.channel_id)} icon={faXmark}/>
                                                </Link>
                                            </Badge>
                                        </li>
                                    ))
                                ) : (
                                    <span>Aucun canal trouvé</span>
                                )}
                            </ul>
                        </li>
                    </ul>
                    <hr />
                    <div className="pb-2 px-sm-2 sidebar-profile">
                        <div className="d-flex align-items-center sidebar-profile-content" aria-expanded="false">
                            <div className="sidebar-profile-content-infos">
                                <div className="profile-content-infos-img">
                                    {user?.Inventories?.[0]?.Shop?.content && (
                                        <img className="avatar-profile decoration-profile" src={`${user.Inventories[0].Shop.content}`} alt="hugenerd" width="40" height="40"/>
                                    )}
                                    <img className="rounded-circle avatar-profile image-profile" src={`${user.avatar}`} alt="hugenerd" width="40" height="40" />
                                </div>
                                <span className="d-none d-sm-inline mx-1">
                                    <strong>{user.username}</strong>
                                </span>
                            </div>
                            <Whisper placement="top" controlId="control-id-hover" trigger="hover" speaker={tooltip}>
                                <Link to="/profile" className="open-params">
                                    <FontAwesomeIcon icon={faGear}/>
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

export default Sidebar;