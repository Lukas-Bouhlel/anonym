import { useEffect, useState, useRef } from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { useQuery, useQueryClient  } from '@tanstack/react-query';
import { useApi } from '../../context/ApiContext';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUserPlus, faTrash } from '@fortawesome/free-solid-svg-icons';
import { Modal, Button, Checkbox, CheckboxGroup, Tooltip, Whisper } from 'rsuite';

const ChannelMessages = ({ user, socket, channel, setPage }) => {
    const [messages, setMessages] = useState([]);
    const [newMessage, setNewMessage] = useState('');
    const { api_url } = useApi();
    const channelId = channel.channel_id;
    const messagesEndRef = useRef(null);
    const [inviteModalVisible, setInviteModalVisible] = useState(false);
    const [selectedFriends, setSelectedFriends] = useState([]);
    const [deleteModalVisible, setDeleteModalVisible] = useState(false);
    const queryClient = useQueryClient();
    const tooltip = (
        <Tooltip>
            Ajouter des amis au groupe privée
        </Tooltip>
    );
    const tooltipDelete = (
        <Tooltip>
            Supprimer le groupe
        </Tooltip>
    );

    // Fonction pour récupérer les messages
    const fetchMessages = async () => {
        try {
            const response = await axios.get(`${api_url}/api/channels/${channelId}/messages`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            throw new Error(error);
        }
    };

    // Utilisation de React Query pour récupérer les messages
    const { data: initialMessages = [], isLoading } = useQuery({
        queryKey: ['messages', channelId],
        queryFn: fetchMessages,
        enabled: !!channelId, // Lancer la requête seulement si channelId est défini et que la page est bien canal
    });

    // Mettre à jour les messages lorsque la requête est terminée
    useEffect(() => {
        if (initialMessages.length > 0) {
            setMessages(initialMessages);
        }
    }, [initialMessages]);

    // Écouter les nouveaux messages via WebSocket
    useEffect(() => {
        if (socket) {
            socket.on('newMessage', (messageData) => {
                setMessages((prevMessages) => [...prevMessages, messageData]);
            });

            return () => {
                socket.off('newMessage'); // Nettoyage
            };
        }
    }, [socket]); // Écoute seulement les changements de socket

    // Rejoindre le canal et écouter les messages
    useEffect(() => {
        if (channelId && socket) {
            // Rejoindre le canal
            socket.emit('joinChannel', { channelId, userId: user.id });

            return () => {
                socket.emit('leaveChannel', { channelId, userId: user.id });
            };
        }
    }, [channelId, socket, user.id]); // Inclut channelId et user.id

    // Envoyer un message
    const handleSendMessage = () => {
        if (newMessage) {
            socket.emit('privateMessage', {
                senderId: user.id,
                content: newMessage,
                channelId: channelId,
            });
            setNewMessage(''); // Réinitialiser le champ de saisie
        }
    };

    // Envoyer un message en appuyant sur "Entrée"
    const handleKeyDown = (e) => {
        if (e.key === 'Enter') {
            handleSendMessage();
        }
    };

    useEffect(() => {
        // Faire défiler vers le bas lorsque les messages changent
        if (messagesEndRef.current) {
            messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [messages]);

    // Fonction pour récupérer la liste des amis
    const fetchFriends = async () => {
        try {
            const response = await axios.get(`${api_url}/api/friends`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération des amis:', error);
            return [];
        }
    };

    // Fonction pour récupérer les membres du canal
    const fetchChannelMembers = async () => {
        try {
            const response = await axios.get(`${api_url}/api/channels/${channelId}/users`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            return [];
        }
    };

    // Utilisation de React Query pour récupérer les amis
    const { data: friends = [] } = useQuery({
        queryKey: ['friends'],
        queryFn: fetchFriends
    });

    const { data: channelMembers = [] } = useQuery({
        queryKey: ['channelMembers', channelId],
        queryFn: fetchChannelMembers,
        enabled: !!channelId, // Exécuter seulement si channelId est défini
    });

    const availableFriends = friends.filter(friend => 
        !channelMembers.some(member => member.id === friend.friend_id)
    );

    // Gestion de la sélection des amis
    const handleInviteFriends = async () => {
        try {
            // Faire une requête pour chaque utilisateur sélectionné
            for (const friendId of selectedFriends) {
                await axios.post(`${api_url}/api/channels/invite`, {
                    channelId: channelId,
                    userId: friendId,
                }, {
                    withCredentials: true,
                });
            }
            setSelectedFriends([]);
            queryClient.invalidateQueries(['channelMembers', channelId]);
            setInviteModalVisible(false); // Fermer le modal après l'invitation
        } catch (error) {
            console.error("Erreur lors de l'invitation:", error);
        }
    };

    // Fonction pour supprimer le canal
    const handleDeleteChannel = async () => {
        try {
            await axios.delete(`${api_url}/api/channels/${channelId}`, {
                withCredentials: true,
            });
            setPage('friends');
            queryClient.invalidateQueries(['channels']);
            setDeleteModalVisible(false);
        } catch (error) {
            console.error("Erreur lors de la suppression du canal :", error);
        }
    };

    const formatDate = (dateString) => {
        const options = { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Europe/Paris' };
        const date = new Date(dateString);
        return date.toLocaleString('fr-FR', options).replace(',', ''); // Remplacer la virgule par un espace pour un format plus propre
    };    

    return (
        <div className='message-container'>
            <div className='message-container-toolbar'>
                <h2>{channel.name}</h2>
                <div>
                    <Whisper placement="bottom" controlId="control-id-hover" trigger="hover" speaker={tooltip}>
                        <FontAwesomeIcon icon={faUserPlus} onClick={() => setInviteModalVisible(true)}/>
                    </Whisper>
                    {user.id === channel.created_by && (
                        <Whisper placement="bottom" controlId="control-id-hover" trigger="hover" speaker={tooltipDelete}>
                            <FontAwesomeIcon icon={faTrash} onClick={() => setDeleteModalVisible(true)}/>
                        </Whisper>
                    )}
                </div>
            </div>
            <div className='message-container-content'>
                <div className="messages">
                    <div className='messages-content'>
                        <p>Bienvenue au début du groupe privé <strong>{channel.name}</strong></p>
                        {isLoading ? (
                            <span>Chargement des messages...</span>
                        ) : (
                            messages.map((msg, index) => (
                                <div key={index} className="message">
                                    <div className="profile-content-infos-img">
                                    {(msg.User?.Inventories?.[0]?.Shop?.content || msg.sender?.Inventories?.[0]?.Shop?.content) && (
                                            <img className="avatar-profile decoration-profile" src={`${msg.User ? msg.User.Inventories[0].Shop.content : msg.sender.Inventories[0].Shop.content}`} alt="hugenerd"/>
                                        )}
                                        <img src={msg.User ? msg.User.avatar : msg.sender.avatar} alt="avatar" className="avatar-profile"/>
                                    </div>
                                    <div className='message-info'>
                                        <div>
                                            <strong ref={messagesEndRef}>{msg.User ? msg.User.username : msg.sender.username}</strong>
                                            <span>{formatDate(msg.createdAt)}</span>
                                        </div>
                                        {msg.content}
                                    </div>
                                    
                                </div>
                            ))
                        )}
                    </div>
                </div>
                <div className='add-messages'>
                    <input
                        aria-label="Écrire un message"
                        type="text"
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        placeholder="Écrire un message..."
                        onKeyDown={handleKeyDown}
                    />
                </div>
            </div>
             {/* Modal pour inviter des amis */}
             <Modal open={inviteModalVisible} onClose={() => setInviteModalVisible(false)}>
                <Modal.Header>
                    <Modal.Title>Inviter des amis dans {channel.name}</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <CheckboxGroup value={selectedFriends} onChange={setSelectedFriends}>
                        {availableFriends.map(friend => (
                            <Checkbox key={friend.id} value={friend.friend_id}>
                                {friend.FriendDetails.username}
                            </Checkbox>
                        ))}
                    </CheckboxGroup>
                </Modal.Body>
                <Modal.Footer>
                    <Button onClick={() => setInviteModalVisible(false)} appearance="subtle">Annuler</Button>
                    <Button onClick={handleInviteFriends} color="blue" appearance="primary">Inviter</Button>
                </Modal.Footer>
            </Modal>
             {/* Modal de confirmation de suppression */}
             <Modal open={deleteModalVisible} onClose={() => setDeleteModalVisible(false)}>
                <Modal.Header>
                    <Modal.Title>Confirmer la suppression</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    Êtes-vous sûr de vouloir supprimer ce canal ? Tout les messages et utilisateurs seront supprimés.
                </Modal.Body>
                <Modal.Footer>
                    <Button onClick={() => setDeleteModalVisible(false)} appearance="subtle">Annuler</Button>
                    <Button onClick={handleDeleteChannel} color="red" appearance="primary">Supprimer</Button>
                </Modal.Footer>
            </Modal>
        </div>
    );
};

ChannelMessages.propTypes = {
    user: PropTypes.shape({
        id: PropTypes.number.isRequired,
        username: PropTypes.string.isRequired,
        avatar: PropTypes.string,
    }).isRequired,
    socket: PropTypes.object.isRequired,
    channel: PropTypes.shape({
        channel_id: PropTypes.number.isRequired,
        name: PropTypes.string.isRequired,
        created_by: PropTypes.number.isRequired,
    }).isRequired,
    setPage: PropTypes.func.isRequired,
};

export default ChannelMessages;