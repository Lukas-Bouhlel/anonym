import { useLocation, useNavigate, Link } from 'react-router-dom';
import axios from 'axios';
import { useApi } from '../context/ApiContext';
import { useQuery } from '@tanstack/react-query';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCheck } from '@fortawesome/free-solid-svg-icons';
import logo from '../assets/images/logos/anonym-logo-white.svg';
import Confetti from 'react-confetti-boom';

/**
 * Composant Success qui affiche une page de confirmation de paiement.
 * Il affiche un message de succès avec les détails de la transaction.
 *
 * @component
 * @returns {React.ReactElement} - La page de succès du paiement.
 */
const Success = () => {
    const location = useLocation();
    const { api_url } = useApi();
    const navigate = useNavigate();
    const sessionId = new URLSearchParams(location.search).get('session_id');

     /**
     * Fonction pour confirmer le paiement via une API.
     * Elle envoie une requête GET pour vérifier l'état du paiement.
     * @returns {Promise<Object>} - Les données de la réponse si le paiement est confirmé.
     */
    const confirmPayment = async () => {
        if (!sessionId) return;
        try {
            const response = await axios.get(`${api_url}/api/payment/confirm?session_id=${sessionId}`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
           navigate('/app')
        }
    };

    const payment = useQuery({
        queryKey: ['payment', sessionId],
        queryFn: confirmPayment,
        enabled: !!sessionId,
    });

    /**
     * Formate une date en chaîne de caractères au format français.
     * @param {string} dateString - La date à formater.
     * @returns {string} - La date formatée.
     */
    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return date.toLocaleDateString('fr-FR');
    };

    return (
        <>
            {!payment.isLoading && payment.data?.invoice && (
                <div id='success'>
                    <Confetti mode="boom" particleCount={30} colors={['#88CD7D', '#757575', '#FFF9F4']} shapeSize={12} />
                    <div className="navbar-logo-anonym">
                        <img src={logo} alt='logo-anonym' />nonym
                    </div>
                    <div className='card-success'>
                        <span className='card-success-icon'><FontAwesomeIcon icon={faCheck} /></span>
                        <p className='card-success-super'>Super!</p>
                        <h1 className='card-success-title'>Paiement confirmées</h1>
                        <p className='card-success-subtitle'>Merci pour votre achat!</p>
                        <hr className='card-success-line' />
                        <p className='card-success-resume'>Votre résumé</p>
                        <div className='card-success-product'>
                            <div className='card-success-product-content'>
                                <p>{payment.data.invoice.content}</p>
                            </div>
                        </div>
                        <p className='card-success-total'>Total</p>
                        <p className='card-success-amount'>{payment.data.invoice.amount}€</p>
                        <p className='card-success-date'>Le {formatDate(payment.data.invoice.createdAt)}</p>
                        <Link to="/app" className='card-success-button'>Retourn sur Anonym</Link>
                    </div>
                </div>
            )}
        </>
    )
}
export default Success