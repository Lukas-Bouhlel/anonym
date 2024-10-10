import { render, screen, waitFor } from '@testing-library/react';
import { UserProvider, useUser } from '../../src/context/UserContext'; // Ajustez le chemin selon votre structure de fichiers
import { ApiProvider } from '../../src/context/ApiContext'; // Assurez-vous d'importer ApiProvider
import { PopupProvider } from '../../src/context/PopupContext'; // Ajoutez PopupProvider ici
import axios from 'axios';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

jest.mock('axios'); // Mocker axios pour les requêtes API

// Composant de test pour vérifier l'utilisation du contexte utilisateur
const TestComponent = () => {
    const { user, isLoading, error, logout } = useUser();

    return (
        <div>
            {isLoading && <div data-testid="loading">Chargement...</div>}
            {error && <div data-testid="error">Erreur de chargement</div>}
            {user ? (
                <div>
                    <div data-testid="user-info">Utilisateur: {user.name}</div>
                    <button onClick={logout}>Déconnexion</button>
                </div>
            ) : (
                <div data-testid="no-user">Pas d&apos;utilisateur connecté</div>
            )}
        </div>
    );
};

describe('UserContext', () => {
    const queryClient = new QueryClient(); // Créer une instance de QueryClient

    beforeAll(() => {
        // Simulez l'URL de l'API
        process.env.VITE_API_URL = 'http://mockapi.com'; // Remplacez par l'URL que vous attendez
    });

    test('devrait récupérer et afficher les informations de l\'utilisateur', async () => {
        const mockUser = { name: 'John Doe' };
        axios.get.mockResolvedValueOnce({ data: mockUser }); // Mocker la réponse de l'API

        render(
            <QueryClientProvider client={queryClient}>
                <ApiProvider>
                    <PopupProvider> {/* Ajoutez PopupProvider ici */}
                        <UserProvider>
                            <TestComponent />
                        </UserProvider>
                    </PopupProvider>
                </ApiProvider>
            </QueryClientProvider>
        );

        // Vérifiez que le texte "Chargement..." est affiché pendant la récupération
        expect(screen.getByTestId('loading')).toBeInTheDocument();

        // Attendez que les données de l'utilisateur soient récupérées
        await waitFor(() => {
            expect(screen.getByTestId('user-info')).toHaveTextContent('Utilisateur: John Doe');
        });
    });

    test('devrait gérer l\'erreur de chargement des informations de l\'utilisateur', async () => {
        axios.get.mockRejectedValueOnce(new Error('Erreur de chargement'));
    
        render(
            <QueryClientProvider client={queryClient}>
                <ApiProvider>
                    <PopupProvider>
                        <UserProvider>
                            <TestComponent />
                        </UserProvider>
                    </PopupProvider>
                </ApiProvider>
            </QueryClientProvider>
        );
    
        // Attendez que l'erreur soit affichée
        await waitFor(() => {
            expect(screen.getByTestId('error')).toHaveTextContent('Erreur de chargement');
        });
    });
    

    test('devrait déconnecter l\'utilisateur', async () => {
        const mockUser = { name: 'John Doe' };
        axios.get.mockResolvedValueOnce({ data: mockUser }); // Mocker la réponse de l'API
        axios.post.mockResolvedValueOnce({}); // Mocker la réponse de déconnexion

        render(
            <QueryClientProvider client={queryClient}>
                <ApiProvider>
                    <PopupProvider> {/* Ajoutez PopupProvider ici */}
                        <UserProvider>
                            <TestComponent />
                        </UserProvider>
                    </PopupProvider>
                </ApiProvider>
            </QueryClientProvider>
        );

        // Attendez que les données de l'utilisateur soient récupérées
        await waitFor(() => {
            expect(screen.getByTestId('user-info')).toHaveTextContent('Utilisateur: John Doe');
        });

        // Déconnecter l'utilisateur
        screen.getByText('Déconnexion').click();

        // Vérifiez que le texte "Pas d'utilisateur connecté" est affiché après déconnexion
        await waitFor(() => {
            expect(screen.getByTestId('no-user')).toHaveTextContent('Pas d\'utilisateur connecté');
        });
    });
});
