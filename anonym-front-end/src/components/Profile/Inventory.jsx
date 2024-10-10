import { useState } from "react";
import PropTypes from 'prop-types';
import axios from "axios";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useApi } from "../../context/ApiContext";
import Popup from "../Utils/Popup";
import spaceman from "../../assets/images/icons/spaceman.svg"

const Inventory = ({ user }) => {
    const { api_url } = useApi();
    const queryClient = useQueryClient();
    const [showPopup, setShowPopup] = useState(false); 
    const [messageError, setMessageError] = useState('');

    // Fonction pour récupérer l'inventaire
    const fetchInventory = async () => {
        try {
            const response = await axios.get(`${api_url}/api/inventory`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            setMessageError(error.response.data.message)
        }
    };

    // Récupération de l'inventaire via react-query
    const inventory = useQuery({
        queryKey: ['inventory'], // Clé de la requête pour le caching
        queryFn: fetchInventory, // Fonction de récupération de l'inventaire
    });

    // Mutation pour mettre à jour l'état "active" de l'item
    const toggleActiveMutation = useMutation({
        mutationFn: async ({itemId, currentState}) => {
            try {
                const response = await axios.put(
                    `${api_url}/api/inventory/${itemId}`,
                    { active: !currentState }, // On inverse l'état actuel
                    { withCredentials: true }
                );
                return response.data;
            } catch (error) {
                console.error("Erreur lors de la mise à jour de l'état actif:", error);
                return null;
            }
        },
        onSuccess: () => {
            setShowPopup(true);
            // Invalider et refetch l'inventaire après la mutation
            queryClient.invalidateQueries(['inventory']);
        },
    });

    // Fonction pour gérer le clic sur le bouton "Activer"
    const handleToggleActive = (itemId, currentState) => {
        toggleActiveMutation.mutate({ itemId, currentState });
    };

    return (
        <div id="inventory">
            <Popup showPopup={showPopup} setShowPopup={setShowPopup} text={'Ta décoration d\'avatar a été mise à jour !'}/>
            <div className="inventory-title">
                <h1>Inventaire</h1>
            </div>
            {!inventory.isLoading && (
                <div className="inventory">
                    <div className="card-deck">
                        {inventory.data && inventory.data.length > 0 ? (
                            inventory.data.map((item, index) => (
                                <div className="card inventory-card-content" key={index}>
                                    <div className="inventory-card-content-header">
                                        <img className="card-img-top inventory-card-content-header-first" src={item.Shop.content} alt="Card image cap" />
                                        <img className="card-img-top inventory-card-content-header-last" src={user.avatar} alt="Card image cap" />
                                    </div>
                                    <div className="card-footer inventory-card-content-footer">
                                        <p className="card-text">{item.Shop.title}</p>
                                        <small className="text-muted">
                                            <button
                                                className={`${item.active ? 'button-active' : 'button-no-active'}`}
                                                onClick={() => handleToggleActive(item.item_id, item.active)}
                                            >
                                                {item.active ? 'Désactiver' : 'Activer'}
                                            </button>
                                        </small>
                                    </div>
                                </div>
                            ))
                        ) : (
                            <div className="no-inventory-found">
                                <img className="icon-spaceman" src={spaceman} alt='icon-spaceman' />
                                {messageError}
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

Inventory.propTypes = {
    user: PropTypes.shape({
        avatar: PropTypes.string.isRequired, // user.avatar should be a string
    }).isRequired, // user should be an object containing avatar
};

export default Inventory;