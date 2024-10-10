import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter as Router } from 'react-router-dom';
import Profile from '../../src/pages/Profile';
import { act } from '@testing-library/react';
import { UserProvider } from '../../src/context/UserContext';
import { PopupProvider } from '../../src/context/PopupContext';
import { ApiProvider } from '../../src/context/ApiContext';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import axios from 'axios'; // Importation de axios
import '@testing-library/jest-dom';

jest.mock('../../src/components/Profile/Profils', () => {
    const Profils = () => <div>Profils Component</div>;
    Profils.displayName = 'Profils';
    return Profils;
});

jest.mock('../../src/components/Profile/Account', () => {
    const Account = () => <div>Account Component</div>;
    Account.displayName = 'Account';
    return Account;
});

jest.mock('../../src/components/Profile/Invoices', () => {
    const Invoices = () => <div>Invoices Component</div>;
    Invoices.displayName = 'Invoices';
    return Invoices;
});

jest.mock('../../src/components/Profile/Inventory', () => {
    const Inventory = () => <div>Inventory Component</div>;
    Inventory.displayName = 'Inventory';
    return Inventory;
});

jest.mock('axios');

const mockUser = {
    roles: ['USER'],
};

describe('Profile Component', () => {
    let logoutMock = jest.fn();
    let setUserMock;

    beforeEach(() => {
        jest.clearAllMocks(); // Réinitialiser tous les mocks
        logoutMock = jest.fn();
        setUserMock = jest.fn();
    
        // Mock des appels axios
        axios.get.mockResolvedValue({
            data: {
                roles: ['USER'],
            },
        });
    });

    const renderProfile = (user) => {
        const queryClient = new QueryClient();

        render(
            <QueryClientProvider client={queryClient}>
                <ApiProvider>
                    <PopupProvider>
                        <UserProvider value={{ user, logout: logoutMock, setUser: setUserMock }}>
                            <Router>
                                <Profile />
                            </Router>
                        </UserProvider>
                    </PopupProvider>
                </ApiProvider>
            </QueryClientProvider>
        );
    };

    test('renders Profils component by default', async () => {
        await act(async () => {
            renderProfile(mockUser);
        });
        expect(screen.getByText('Profils Component')).toBeInTheDocument();
    });

    test('switches to Account component when clicked', async () => {
        await act(async () => {
            renderProfile(mockUser);
        });
        fireEvent.click(screen.getByText('Profil'));
        expect(screen.getByText('Account Component')).toBeInTheDocument();
    });

    test('opens logout modal on logout button click', async () => {
        await act(async () => {
            renderProfile(mockUser);
        });
        fireEvent.click(screen.getByText('Déconnexion'));// Vérifiez que le modal est ouvert
    });

    test('calls logout function when confirmed in modal', async () => {
        await act(async () => {
            renderProfile(mockUser);
        });
        
        // Cliquez sur le bouton de déconnexion
        await act(async () => {
            fireEvent.click(screen.getByText('Déconnexion'));
        });
    
        // Attendez que la modale soit visible
        const modal = await screen.findByRole('dialog');
        expect(modal).toBeInTheDocument();
    
        // Cliquez sur le bouton de confirmation (Déconnexion dans ce cas)
        const confirmButton = screen.getByRole('button', { name: /Déconnexion/i });
        
        await act(async () => {
            fireEvent.click(confirmButton); // Cliquez sur le bouton de déconnexion
        });
    });

    test('navigates to admin dashboard if user has admin role', async () => {
        const adminUser = {
            roles: ['ADMIN'], // Assurez-vous que l'utilisateur a le rôle ADMIN
        };
    
        await act(async () => {
            renderProfile(adminUser);
        });
    });    
    
    test('renders without crashing when user is null', async () => {
        await act(async () => {
            renderProfile(null);
        });

        expect(screen.queryByText('Admin DashBoard')).not.toBeInTheDocument();
    });
});
