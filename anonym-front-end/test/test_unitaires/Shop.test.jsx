import { render, screen, fireEvent } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Shop from '../../src/components/Shop/Shop'; // Assurez-vous que le chemin est correct
import { useApi } from '../../src/context/ApiContext';
import axios from 'axios';

// Création d'un client React Query
const queryClient = new QueryClient();

jest.mock('axios');

jest.mock('../../src/context/ApiContext', () => ({
    useApi: jest.fn(),
}));

const mockApiUrl = 'http://mockapi.com'; // Remplacez par votre URL d'API fictive

// Mock de l'utilisateur
const user = {
    avatar: 'http://mockavatar.com/avatar.png'
};

// Fonction de configuration pour les tests
const setup = () => {
    useApi.mockReturnValue({ api_url: mockApiUrl });
    render(
        <QueryClientProvider client={queryClient}>
            <Shop user={user} />
        </QueryClientProvider>
    );
};

describe('Shop Component', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('devrait rendre le composant Shop', async () => {
        // Mock de la réponse de l'API
        axios.get.mockResolvedValueOnce({
            data: [{ article_id: 1, content: 'item1.png', title: 'Item 1', amount: 10 }],
        });
        axios.get.mockResolvedValueOnce({
            data: [],
        });
        

        setup();

        expect(await screen.findByText('Boutique')).toBeInTheDocument();
    });

    test('devrait afficher les articles de la boutique', async () => {
        // Mock de la réponse de l'API
        axios.get.mockResolvedValueOnce({
            data: [{ article_id: 1, content: 'item1.png', title: 'Item 1', amount: 10 }],
        });
        axios.get.mockResolvedValueOnce({
            data: [{ article_id: 1, item_id: 2 }], // Simuler que l'article a été acheté
        });
    
        setup();
    
        // Vérifiez que l'article s'affiche
        expect(await screen.findByText('Item 1')).toBeInTheDocument();
        expect(await screen.findByText('10 €')).toBeInTheDocument();
    });
    

    test('devrait gérer l\'activation d\'un article', async () => {
        // Mock de la réponse de l'API pour shop et inventory
        axios.get.mockResolvedValueOnce({
            data: [{ article_id: 1, content: 'item1.png', title: 'Item 1', amount: 10 }],
        });
        axios.get.mockResolvedValueOnce({
            data: [{ article_id: 1, item_id: 2 }], // Simuler que l'article a été acheté
        });

        axios.put.mockResolvedValueOnce({
            data: {},
        });

        setup();

        // Attendez que le bouton soit dans le document et cliquez dessus
        const useNowButton = await screen.findByText('Utiliser maintenant');
        fireEvent.click(useNowButton);

        // Vérifiez que le popup s'affiche après l'activation
        expect(await screen.findByText((content) => 
            content.includes("Ta décoration d'avatar a été mise à jour !")
        )).toBeInTheDocument();
    });

    test('devrait gérer l\'achat d\'un article', async () => {
        // Mock de la réponse de l'API pour shop et inventory
        axios.get.mockResolvedValueOnce({
            data: [{ article_id: 1, content: 'item1.png', title: 'Item 1', amount: 10 }],
        });
        axios.get.mockResolvedValueOnce({
            data: [],
        });

        axios.post.mockResolvedValueOnce({
            data: { url: 'http://localhost/' },
        });

        setup();

        // Attendez que le bouton soit dans le document et cliquez dessus
        const buyButton = await screen.findByText('Acheter pour 10 €');
        fireEvent.click(buyButton);

        // Vérifiez que la redirection a lieu
        expect(window.location.href).toBe('http://localhost/');
    });
});
