import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import Success from '../../src/pages/Success'; // Assurez-vous que le chemin est correct
import { useApi } from '../../src/context/ApiContext'; // Mock de useApi
import { useQuery } from '@tanstack/react-query'; // Mock de useQuery
import { MemoryRouter } from 'react-router-dom';

// Mock du composant Confetti
jest.mock('react-confetti-boom', () => {
    return function DummyConfetti() {
        return <div>Confetti Mock</div>;
    };
});

// Mock de useApi
jest.mock('../../src/context/ApiContext', () => ({
    useApi: jest.fn(),
}));

// Mock de useQuery
jest.mock('@tanstack/react-query', () => ({
    useQuery: jest.fn(),
}));

// Mock de axios
jest.mock('axios');

describe('Success Page', () => {
    const mockApiUrl = 'http://localhost:3000';

    beforeEach(() => {
        jest.clearAllMocks(); // Nettoyer les mocks avant chaque test
        useApi.mockReturnValue({ api_url: mockApiUrl });
    });

    const renderWithRouter = (ui, { route = '/' } = {}) => {
        window.history.pushState({}, 'Test page', route);
        return render(<MemoryRouter initialEntries={[route]}>{ui}</MemoryRouter>);
    };

    test('should render success message and payment details when payment is confirmed', async () => {
        // Mock de la réponse de l'API
        const mockPaymentData = {
            invoice: {
                content: 'Produit A, Produit B',
                amount: 50,
                createdAt: new Date().toISOString(),
            },
        };

        useQuery.mockReturnValue({
            isLoading: false,
            data: mockPaymentData,
        });

        renderWithRouter(<Success />);

        // Vérifier que les éléments de succès sont affichés
        expect(screen.getByText(/Super!/i)).toBeInTheDocument();
        expect(screen.getByText(/Paiement confirmées/i)).toBeInTheDocument();
        expect(screen.getByText(/Merci pour votre achat!/i)).toBeInTheDocument();
        expect(screen.getByText(/Votre résumé/i)).toBeInTheDocument();
        expect(screen.getByText(/Produit A, Produit B/i)).toBeInTheDocument();
        expect(screen.getByText(/Total/i)).toBeInTheDocument();
        expect(screen.getByText(/50€/i)).toBeInTheDocument();
        
        // Vérifier la date formatée
        const dateFormatted = screen.getByText(/Le \d{2}\/\d{2}\/\d{4}/i);
        expect(dateFormatted).toBeInTheDocument();
    }); 

    test('should show loading state initially', () => {
        useQuery.mockReturnValue({
            isLoading: true,
        });

        renderWithRouter(<Success />);

        // Vérifiez que rien n'est affiché tant que le paiement est en cours de chargement
        expect(screen.queryByText(/Super!/i)).not.toBeInTheDocument();
    });
});