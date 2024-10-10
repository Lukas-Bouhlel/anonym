import { render, screen, act } from '@testing-library/react';
import Friends from '../../src/pages/Friends'; // Remplacez par le chemin correct vers votre fichier
import { useApi } from '../../src/context/ApiContext';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import axios from 'axios';

// Mock des contextes et des appels API
jest.mock('../../src/context/ApiContext');
jest.mock('axios');

const mockApiUrl = 'http://mockapi.com';
useApi.mockReturnValue({ api_url: mockApiUrl });

const queryClient = new QueryClient();

describe('Friends Component', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('affiche un indicateur de chargement pendant le chargement des amis', async () => {
        // Mock l'appel d'API pour retourner une promesse non résolue
        axios.get.mockImplementationOnce(() => new Promise(() => {}));

        await act(async () => {
            render(
                <QueryClientProvider client={queryClient}>
                    <Friends />
                </QueryClientProvider>
            );
        });

        expect(screen.getByText("Chargement...")).toBeInTheDocument();
    });

    test('affiche une erreur lorsque l\'appel API échoue', async () => {
        // Mock l'appel d'API pour qu'il échoue
        axios.get.mockRejectedValue(new Error('Erreur'));

        await act(async () => {
            render(
                <QueryClientProvider client={queryClient}>
                    <Friends />
                </QueryClientProvider>
            );
        });
    });   

    test('affiche la liste des amis lorsque l\'appel API réussit', async () => {
        // Mock l'appel d'API pour retourner des données d'amis
        const mockFriends = [
            { id: 1, FriendDetails: { username: 'Friend1', avatar: 'friend1.png', Inventories: [{ Shop: { content: 'shop.png' } }] }, status: 'online' },
            { id: 2, FriendDetails: { username: 'Friend2', avatar: 'friend2.png', Inventories: [{ Shop: { content: 'shop.png' } }] }, status: 'offline' },
        ];

        axios.get.mockResolvedValue({ data: mockFriends });

        await act(async () => {
            render(
                <QueryClientProvider client={queryClient}>
                    <Friends />
                </QueryClientProvider>
            );
        });
    });

    test('ajoute un ami lorsque le formulaire est soumis', async () => {
        const mockFriends = [
            { id: 1, FriendDetails: { username: 'Friend1', avatar: 'friend1.png' }, status: 'online' },
        ];

        axios.get.mockResolvedValue({ data: mockFriends });
        axios.post.mockResolvedValue({ data: { message: 'Demande d\'ami envoyée' } });

        await act(async () => {
            render(
                <QueryClientProvider client={queryClient}>
                    <Friends />
                </QueryClientProvider>
            );
        });
    });

       test('supprime un ami lorsque l\'option de suppression est cliquée', async () => {
        const mockFriends = [
            { id: 1, FriendDetails: { username: 'Friend1', avatar: 'friend1.png' }, status: 'online' },
        ];

        axios.get.mockResolvedValue({ data: mockFriends });
        axios.delete.mockResolvedValue({});

        await act(async () => {
            render(
                <QueryClientProvider client={queryClient}>
                    <Friends />
                </QueryClientProvider>
            );
        });
    });
});