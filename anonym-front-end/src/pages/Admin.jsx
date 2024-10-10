import { useUser } from '../context/UserContext';
import { useApi } from "../context/ApiContext";
import axios from "axios";
import { useQuery } from '@tanstack/react-query';
import Sidebar from "../components/Admin/Sidebar";
import Users from "../components/Admin/Users";
import Shop from "../components/Admin/Shop";
import { usePopup } from "../context/PopupContext";
import Popup from "../components/Utils/Popup";

const Admin = () => {
    const { user } = useUser();
    const { api_url } = useApi();
    const { openPopup, setOpenPopup, textPopup, setTextPopup, state, setState } = usePopup();

    const fetchUsers = async () => {
        try {
            const response = await axios.get(`${api_url}/api/account/users`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération des amis:', error);
            return null;
        }
    };

    // Utilisation de react-query pour la récupération des amis
    const users = useQuery({
        queryKey: ['users'], // Clé de la requête pour le caching
        queryFn: fetchUsers, // Fonction de récupération des amis
    });

    const fetchShop = async () => {
        try {
            const response = await axios.get(`${api_url}/api/shop`, {
                withCredentials: true,
            });
            return response.data;
        } catch (error) {
            console.error('Erreur lors de la récupération des amis:', error);
            return null;
        }
    };

    // Utilisation de react-query pour la récupération des amis
    const shop = useQuery({
        queryKey: ['shop'], // Clé de la requête pour le caching
        queryFn: fetchShop, // Fonction de récupération des amis
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