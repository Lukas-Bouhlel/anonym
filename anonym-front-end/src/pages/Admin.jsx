import { useUser } from '../context/UserContext';
import { useApi } from "../context/ApiContext";
import axios from "axios";
import { useQuery } from '@tanstack/react-query';
import Sidebar from "../components/Admin/Sidebar";
import Users from "../components/Admin/Users";
import Shop from "../components/Admin/Shop";
import { usePopup } from "../context/PopupContext";
import Popup from "../components/Utils/Popup";

/**
 * Composant de la page d'administration.
 * Ce composant permet à l'administrateur de gérer les utilisateurs et la boutique.
 * Il utilise `react-query` pour effectuer les appels API afin de récupérer les données des utilisateurs et des articles de la boutique.
 * Affiche également des popups pour les notifications ou messages importants.
 * 
 * @component
 * @returns {React.ReactElement} - Page d'administration.
 */
const Admin = () => {
    const { user } = useUser();
    const { api_url } = useApi();
    const { openPopup, setOpenPopup, textPopup, setTextPopup, state, setState } = usePopup();

    /**
     * Récupère la liste des utilisateurs depuis l'API.
     * 
     * @async
     * @function fetchUsers
     * @returns {Promise<Object[]|null>} - Retourne la liste des utilisateurs ou null en cas d'erreur.
     */
    const fetchUsers = async () => {
        try {
            const response = await axios.get(`${api_url}/api/account/users`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération des utilisateurs:', error);
            return null;
        }
    };

    // Utilisation de react-query pour la récupération des utilisateurs
    const users = useQuery({
        queryKey: ['users'],
        queryFn: fetchUsers,
    });

    /**
     * Récupère la liste des articles de la boutique depuis l'API.
     * 
     * @async
     * @function fetchShop
     * @returns {Promise<Object[]|null>} - Retourne la liste des articles ou null en cas d'erreur.
     */
    const fetchShop = async () => {
        try {
            const response = await axios.get(`${api_url}/api/shop`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération des articles:', error);
            return null;
        }
    };

    // Utilisation de react-query pour la récupération des articles
    const shop = useQuery({
        queryKey: ['shop'], 
        queryFn: fetchShop, 
    });

    return (
        <div id="admin">
            {openPopup && (
                <Popup showPopup={openPopup} setShowPopup={setOpenPopup} text={textPopup} setTextPopup={setTextPopup} state={state} setState={setState}/>
            )}
           <Sidebar/>
           <div className="content-admin">
                <div className="content-admin-container">
                    <h1 className='admin-title'><span>Bonjour,</span> {user.username}</h1>
                    <Users users={users} refetch={users.refetch}/>
                    <Shop shop={shop} refetch={shop.refetch}/>
                </div>
           </div>
        </div>
    )
}

export default Admin;