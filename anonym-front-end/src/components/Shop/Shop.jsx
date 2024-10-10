import { useState } from "react";
import PropTypes from 'prop-types';
import axios from "axios";
import { useQuery, useMutation, useQueryClient  } from "@tanstack/react-query";
import { useApi } from "../../context/ApiContext";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCheck } from "@fortawesome/free-solid-svg-icons";
import Popup from "../Utils/Popup";

const Shop = ({ user }) => {
    const { api_url } = useApi();
    const queryClient = useQueryClient(); 
    const [showPopup, setShowPopup] = useState(false); 

    // Fonction pour récupérer l'inventaire
    const fetchShop = async () => {
        try {
            const response = await axios.get(`${api_url}/api/shop`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            return [];
        }
    };

     // Fonction pour récupérer l'inventaire
     const fetchInventory = async () => {
        try {
            const response = await axios.get(`${api_url}/api/inventory`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            return [];
        }
    };

    // Mutation pour mettre à jour l'état "active" de l'item
    const toggleActiveMutation = useMutation({
        mutationFn: async (itemId) => {
            try {
                const response = await axios.put(`${api_url}/api/inventory/${itemId}`, 
                    {active: true}, 
                    {withCredentials: true}
                );
                return response.data;
            } catch (error) {
                console.error("Erreur lors de la mise à jour de l'état actif:", error);
                return null;
            }
        },
        onSuccess: () => {
            setShowPopup(true);
            queryClient.invalidateQueries(['inventory']);
        },
    });

    // Fonction pour gérer l'achat d'un article
    const handlePurchase = async (articleId) => {
        try {
            const response = await axios.post(`${api_url}/api/payment`, 
                { article_id: articleId }, 
                { withCredentials: true }
            );
            // Rediriger vers l'URL de la session de paiement Stripe
            window.location.href = response.data.url;
        } catch (error) {
            console.error("Erreur lors de l'achat:", error);
        }
    };
    
    // Récupération de l'inventaire via react-query
    const shop = useQuery({
        queryKey: ['shop'], // Clé de la requête pour le caching
        queryFn: fetchShop, // Fonction de récupération de l'inventaire
    });

    // Récupération de l'inventaire via react-query
    const inventory = useQuery({
        queryKey: ['inventory'], // Clé de la requête pour le caching
        queryFn: fetchInventory, // Fonction de récupération de l'inventaire
    });

    // Fonction pour vérifier si un article est déjà acheté
    const isArticlePurchased = (articleId) => {
        return inventory.data && inventory.data.some(item => item.article_id === articleId);
    };

    // Fonction pour gérer le clic sur le bouton "Activer"
    const handleToggleActive = (articleId) => {
        const item = inventory.data && inventory.data.find(item => item.article_id === articleId);
        if (item) {
            toggleActiveMutation.mutate(item.item_id);
        }
    };

    return (
        <div id="shop">
            <Popup showPopup={showPopup} setShowPopup={setShowPopup} text={'Ta décoration d\'avatar a été mise à jour !'}/>
            <div className="shop-title">
                <h1>Boutique</h1>
            </div>
            {!shop.isLoading && !inventory.isLoading && (
                <div className="shop">
                    <div className="card-deck">
                        {shop?.data && shop.data.length > 0 ? (
                            shop.data.map((item, index) => (
                                <div className="card shop-card-content" key={index}>
                                    <div className="shop-card-content-header">
                                        {isArticlePurchased(item.article_id) && (
                                            <div className="article-already-bought"><FontAwesomeIcon icon={faCheck}/></div>
                                        )}
                                        <img className="card-img-top shop-card-content-header-first" src={item.content} alt="Card image cap" />
                                        <img className="card-img-top shop-card-content-header-last" src={user.avatar} alt="Card image cap" />
                                    </div>
                                    <div className="card-footer shop-card-content-footer">
                                        <p className="card-text">{item.title}</p>
                                        <div className="shop-card-content-footer-paiement">
                                            <div className="shop-card-content-footer-paiement-amount">
                                                {isArticlePurchased(item.article_id) ? (
                                                    <p>Déjà en possession</p>
                                                ) : (
                                                    <p>{item.amount} €</p>
                                                )}
                                            </div>
                                            {isArticlePurchased(item.article_id) ? (
                                                <button onClick={() => handleToggleActive(item.article_id)}>Utiliser maintenant</button>
                                            ) : (
                                                <button onClick={() => handlePurchase(item.article_id)}>Acheter pour {item.amount} €</button>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            ))
                        ) : (
                            <>Not Found.</>
                        )}
                    </div>
                </div>
            )}
        </div>
    )
}

Shop.propTypes = {
    user: PropTypes.shape({
        avatar: PropTypes.string.isRequired, 
    }).isRequired, 
};

export default Shop;