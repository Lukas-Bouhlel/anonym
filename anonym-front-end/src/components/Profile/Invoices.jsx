import React, { useState } from "react";
import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { useApi } from "../../context/ApiContext";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faAngleUp, faAngleDown } from "@fortawesome/free-solid-svg-icons";
import Popup from "../Utils/Popup";

const Invoices = () => {
    const { api_url } = useApi();
    const [expandedRows, setExpandedRows] = useState([]);
    const [showPopup, setShowPopup] = useState(false); 

    const fetchInvoices = async () => {
        try {
            const response = await axios.get(`${api_url}/api/invoice`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération de l\'utilisateur:', error);
            return null;
        }
    };

    // Utilisation de react-query pour la récupération de l'utilisateur
    const invoices = useQuery({
        queryKey: ['invoices'], // Clé de la requête pour le caching
        queryFn: fetchInvoices, // Fonction de récupération de l'utilisateur
    });

    // Fonction pour formater la date
    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return date.toLocaleDateString('fr-FR'); // Format MM/DD/YYYY
    };

    const formatDays = (dateString) => {
        const givenDate = new Date(dateString);
        const currentDate = new Date();
    
        // Calcul de la différence en millisecondes
        const differenceInTime = currentDate - givenDate;
    
        // Conversion de la différence en jours (1 jour = 24h * 60min * 60sec * 1000ms)
        const differenceInDays = Math.floor(differenceInTime / (1000 * 60 * 60 * 24));
    
        return differenceInDays;
    };

    // Fonction pour basculer l'expansion des lignes
    const toggleRowExpansion = (index) => {
        const isExpanded = expandedRows.includes(index);
        if (isExpanded) {
            setExpandedRows(expandedRows.filter(row => row !== index));
        } else {
            setExpandedRows([...expandedRows, index]);
        }
    };

   // Fonction pour générer et envoyer la facture par email
    const generateInvoice = async (id) => {
        try {
            await axios.get(`${api_url}/api/invoice/${id}`, {
                withCredentials: true,
            });
            setShowPopup(true);
        } catch (error) {
            console.error('Erreur lors de l\'envoi de la facture:', error);
        }
    };

    return (
        <div id="invoices">
            <Popup showPopup={showPopup} setShowPopup={setShowPopup} text={'La facture a été envoyée dans votre boîte email !'} state={'success'}/>
            <div className="invoices-title">
                <h1>Historique des transactions</h1>
            </div>
            {!invoices.isLoading && (
                <div className="table-responsive-sm invoices">
                    <table className="table table-dark">
                        <thead>
                            <tr>
                                <th scope="col">Date</th>
                                <th scope="col">Description</th>
                                <th scope="col">Montant</th>
                                <th scope="col"></th>
                            </tr>
                        </thead>
                        <tbody>
                            {invoices.data.length > 0 ? (
                                invoices.data.map((invoice, index) => (
                                    <React.Fragment key={index}>
                                        <tr onClick={() => toggleRowExpansion(index)} style={{ cursor: 'pointer' }}>
                                            <td>{formatDate(invoice.createdAt)}</td>
                                            <td>{invoice.content}</td>
                                            <td>{invoice.amount}€</td>
                                            <td>
                                                {expandedRows.includes(index) ? <FontAwesomeIcon icon={faAngleUp}/> : <FontAwesomeIcon icon={faAngleDown}/>}
                                            </td>
                                        </tr>
                                        {/* Détails supplémentaires lorsque la ligne est étendue */}
                                        {expandedRows.includes(index) && (
                                            <tr className="expanded-row">
                                                <td colSpan="4">
                                                    <div className="expanded-details">
                                                        <h1>Détails de l&apos;achat</h1>
                                                        <p>Total : <span>{invoice.amount}€</span></p>
                                                        <span className="send-invoice" onClick={() => generateInvoice(invoice.id)} >
                                                            Télécharger la facture
                                                        </span>
                                                        <p>Date d&apos;achat : <span>Il y a {formatDays(invoice.createdAt) === 0 ? 1 : formatDays(invoice.createdAt)} jours</span></p>
                                                    </div>
                                                </td>
                                            </tr>
                                        )}
                                    </React.Fragment>
                                ))
                            ) : (
                                <tr><td colSpan="4">Aucune facture disponible.</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    )
}

export default Invoices;