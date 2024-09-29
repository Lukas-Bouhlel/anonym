import React, { useState } from "react";
import axios from 'axios';
import { useApi } from '../context/ApiContext';
import { useQuery, useMutation } from '@tanstack/react-query';
import spaceman from '../assets/images/icons/spaceman.svg'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser, faEllipsisVertical } from '@fortawesome/free-solid-svg-icons';
import { Tooltip, Whisper } from 'rsuite';
import Popup from "../components/Utils/Popup";

const Friends = () => {
    const { api_url } = useApi();
    const [choiceFriendsType, setChoiceFriendsType] = useState('online');
    const [usernameToAdd, setUsernameToAdd] = useState('');
    const [addStatus, setAddStatus] = useState();
    const [messageStatus, setMessageStatus] = useState('');
    const [showPopup, setShowPopup] = useState(false);
    const [messagePopup, setMessagePopup] = useState('');

    const fetchFriends = async () => {
        try {
            const response = await axios.get(`${api_url}/api/friends`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération des amis:', error);
            return null;
        }
    };

    // Utilisation de react-query pour la récupération des amis
    const { data: friends, isLoading, isError, refetch } = useQuery({
        queryKey: ['friends'], // Clé de la requête pour le caching
        queryFn: fetchFriends, // Fonction de récupération des amis
    });

    // Mutation pour envoyer une demande d'ami
    const { mutate: sendFriendRequest, isLoading: isSending } = useMutation({
        mutationFn: async (username) => {
            try {
                const response = await axios.post(`${api_url}/api/friends/${username}`, {}, {
                    withCredentials: true,
                });
                return response.data;
            } catch (error) {
                console.error('Erreur lors de l\'ajout d\'ami:', error);
                throw error;
            }
        },
        onSuccess: () => {
            // Afficher le nom d'utilisateur ajouté dans le message de succès
            setAddStatus('Success');
            setMessageStatus(`Ta demande d'ami a été envoyée à ${usernameToAdd} !`);
            refetch();
        },
        onError: (data) => {
            setMessageStatus(data.response.data.message);
            setAddStatus('Error');
        }
    });

    // Mutation pour supprimer un ami
    const { mutate: deleteFriend } = useMutation({
        mutationFn: async (friend) => {
            try {
                await axios.delete(`${api_url}/api/friends/${friend.id}`, {
                    withCredentials: true,
                });
                setMessagePopup(`${friend.username} vient d'être retiré de votre liste d'amis !`)
                setShowPopup(true);
            } catch (error) {
                console.error("Erreur lors de la suppression de l'ami:", error);
                throw error;
            }
        },
        onSuccess: () => {
            refetch(); // Rafraîchit la liste des amis après suppression
        }
    });

    // Mutation pour mettre à jour le status d'un ami
    const { mutate: updateFriend } = useMutation({
        mutationFn: async ({ friend, status }) => {
            try {
                await axios.put(`${api_url}/api/friends/${friend.id}`, {
                    status: status
                }, { withCredentials: true });
                status === 'BLOQUED' ? setMessagePopup(`${friend.username} vient d'être bloqué !`) : setMessagePopup(`${friend.username} vient d'être débloqué !`);
                setShowPopup(true);
            } catch (error) {
                console.error("Erreur lors de la mise à jour du status de l'utilisateur:", error);
                throw error;
            }
        },
        onSuccess: () => {
            refetch(); // Rafraîchit la liste des amis après suppression
        }
    });

    // Fonction de gestion du formulaire d'ajout d'amis
    const handleAddFriend = (e) => {
        e.preventDefault();
        if (usernameToAdd) {
            sendFriendRequest(usernameToAdd); // Envoie la demande d'ajout d'ami
        }
    };

    // Fonction pour filtrer les amis en fonction du statut sélectionné
    const filterFriends = (friendsList) => {
        if (!friendsList) {
            return [];
        }
        switch (choiceFriendsType) {
            case 'online':
                return friendsList.filter(friend => friend.status === 'online');
            case 'all':
                return friendsList.filter(friend => friend.status !== 'BLOQUED');
            case 'bloqued':
                return friendsList.filter(friend => friend.status === 'BLOQUED');
            default:
                return friendsList;
        }
    };

    if (isLoading) {
        return <div>Chargement...</div>; // Affiche un indicateur de chargement
    }

    if (isError) {
        return <div>Erreur lors du chargement des amis.</div>; // Gestion des erreurs
    }

    // Filtrer les amis en fonction du choix sélectionné
    const filteredFriends = filterFriends(friends);

    // Fonction pour faire le rendu du tooltip avec la suppression
    const renderTooltip = (friend, status) => (
        <Tooltip>
            <div
                className="delete-friend"
                onClick={() => deleteFriend(friend)} // Appelle la fonction de suppression avec l'ID de l'ami
            >
                Retirer l'ami
            </div>
            <div
                className="update-friend"
                onClick={() => updateFriend({ friend, status })} // Appelle la fonction de suppression avec l'ID de l'ami
            >
                {choiceFriendsType === 'bloqued' ? (
                    <>Débloquer l'utilisateur</>
                ) : (
                    <>Bloquer l'utilisateur</>
                )}

            </div>
        </Tooltip>
    );

    return (
        <div id="friends">
            <Popup showPopup={showPopup} setShowPopup={setShowPopup} text={messagePopup} />
            {friends && (
                <>
                    <div className="content-friends d-flex">
                        <h1 className="content-friends-title"><FontAwesomeIcon icon={faUser} />  Amis</h1>
                        <button onClick={() => setChoiceFriendsType('online')} className={`content-friends-filter ${choiceFriendsType === 'online' ? 'content-friends-filter-active' : ''}`}>En ligne</button>
                        <button onClick={() => setChoiceFriendsType('all')} className={`content-friends-filter ${choiceFriendsType === 'all' ? 'content-friends-filter-active' : ''}`}>Tous</button>
                        <button onClick={() => setChoiceFriendsType('bloqued')} className={`content-friends-filter ${choiceFriendsType === 'bloqued' ? 'content-friends-filter-active' : ''}`}>Bloqué</button>
                        <button onClick={() => setChoiceFriendsType('add')} className={`content-friends-add ${choiceFriendsType === 'add' ? 'content-friends-add-active' : ''}`}>Ajouter</button>
                    </div>
                    {choiceFriendsType !== 'add' ? (
                        <>
                            <div className="status-type-friends">
                                {choiceFriendsType === 'online' ? (
                                    <p>En ligne - {friends.filter(friend => friend.status === 'online').length}</p>
                                ) : choiceFriendsType === 'all' ? (
                                    <p>Tous les amis - {friends.filter(friend => friend.status !== 'BLOQUED').length}</p>
                                ) : (
                                    <p>Bloqués - {friends.filter(friend => friend.status === 'BLOQUED').length}</p>
                                )}
                            </div>
                            <ul className="list-group list-group-flush">
                                {filteredFriends.length > 0 ? (
                                    filteredFriends.map((friend, index) => (
                                        <li key={index} className="list-group-item list-friends">
                                            <div className="content-friend">
                                                <div className="profile-content-infos-img">
                                                    {friend?.FriendDetails?.Inventories?.[0]?.Shop?.content && (
                                                        <img className="avatar-profile decoration-profile" src={`${friend.FriendDetails.Inventories[0].Shop.content}`} alt="hugenerd" width="50" height="50"/>
                                                    )}
                                                    <img src={`${friend.FriendDetails.avatar}`} alt="avatar" width="50" height="50" className="rounded-circle avatar-profile" />
                                                </div>
                                                <strong>{friend.FriendDetails.username}</strong>
                                            </div>
                                            <Whisper placement="left" controlId="control-id-click" trigger="click" speaker={renderTooltip(friend.FriendDetails, choiceFriendsType === 'bloqued' ? 'ACTIVE' : 'BLOQUED')}>
                                                <div className="tooltip-friend" tabIndex="0">
                                                    <FontAwesomeIcon icon={faEllipsisVertical} />
                                                </div>
                                            </Whisper>
                                        </li>
                                    ))
                                ) : (
                                    <div className="no-friends-found">
                                        <img className="icon-spaceman" src={spaceman} alt='icon-spaceman' />
                                        Aucun utilisateur trouvé
                                    </div>
                                )}
                            </ul>
                        </>
                    ) : (
                        <div className={`add-friends ${addStatus === 'Success' ? 'add-friends-success' : addStatus === 'Error' ? 'add-friends-error' : ''}`}>
                            <h1 className="add-friends-title">AJOUTER</h1>
                            <p className="add-friends-paragraph">Tu peux ajouter des amis grâce à leurs noms d'utilisateur Anonym</p>
                            <form className="add-friends-form" onSubmit={handleAddFriend}>
                                <input
                                    className="add-friends-form-input"
                                    placeholder="Nom d'utilisateur"
                                    type="text"
                                    value={usernameToAdd}
                                    onChange={(e) => {
                                        setUsernameToAdd(e.target.value);
                                        setAddStatus('');
                                        setMessageStatus('');
                                    }} // Gérer l'état du nom d'utilisateur
                                />
                                <button className="button add-friends-form-submit" type="submit" disabled={isSending}>
                                    {isSending ? 'Envoi en cours...' : 'Envoyer une demande d\'ami'}
                                </button>
                            </form>
                            {messageStatus && <p className={`add-friends-status ${addStatus === 'Success' ? 'add-friends-success' : addStatus === 'Error' ? 'add-friends-error' : ''}`}>{messageStatus}</p>}
                            <div className="add-friends-icons">
                                <img className="icon-spaceman" src={spaceman} alt='icon-spaceman' />
                                Anonym attends des amis. Mais rien ne t'oblige à en ajouter !
                            </div>
                        </div>
                    )}
                </>
            )}
        </div>
    )
}
export default Friends;