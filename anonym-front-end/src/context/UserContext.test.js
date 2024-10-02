// UserContext.test.js
import React from 'react';
import { render, screen, act } from '@testing-library/react';
import { UserProvider, useUser } from './UserContext'; // Importation du contexte
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';

// Configuration d'un mock d'axios
const mockAxios = new MockAdapter(axios);

const TestComponent = () => {
    const { user, login, logout, registered } = useUser();
    return (
        <div>
            <button onClick={() => login({ name: 'John Doe' })}>Login</button>
            <button onClick={() => registered({ name: 'Jane Doe' })}>Register</button>
            <button onClick={logout}>Logout</button>
            {user && <span>{user.name}</span>}
        </div>
    );
};

describe('UserContext', () => {
    beforeEach(() => {
        mockAxios.reset(); // Réinitialise le mock d'axios avant chaque test
    });

    test('renders without crashing', () => {
        render(
            <UserProvider>
                <TestComponent />
            </UserProvider>
        );

        expect(screen.getByText(/login/i)).toBeInTheDocument();
    });

    test('login updates the user state', async () => {
        render(
            <UserProvider>
                <TestComponent />
            </UserProvider>
        );

        // Simule un clic sur le bouton Login
        act(() => {
            screen.getByText(/login/i).click();
        });

        expect(await screen.findByText(/John Doe/i)).toBeInTheDocument();
    });

    test('registered updates the user state and shows success message', async () => {
        render(
            <UserProvider>
                <TestComponent />
            </UserProvider>
        );

        // Simule un clic sur le bouton Register
        act(() => {
            screen.getByText(/register/i).click();
        });

        expect(await screen.findByText(/Jane Doe/i)).toBeInTheDocument();
    });

    test('logout sets user to null', async () => {
        // Prérequis : se connecter d'abord
        mockAxios.onGet('/api/account').reply(200, { name: 'John Doe' });
        
        render(
            <UserProvider>
                <TestComponent />
            </UserProvider>
        );

        // Simule un clic sur le bouton Login
        act(() => {
            screen.getByText(/login/i).click();
        });

        // Vérifie que l'utilisateur est connecté
        expect(await screen.findByText(/John Doe/i)).toBeInTheDocument();

        // Simule un clic sur le bouton Logout
        act(() => {
            screen.getByText(/logout/i).click();
        });

        // Vérifie que l'utilisateur est déconnecté
        expect(screen.queryByText(/John Doe/i)).not.toBeInTheDocument();
    });

    test('fetches user data on initial render', async () => {
        mockAxios.onGet('/api/account').reply(200, { name: 'John Doe' });

        render(
            <UserProvider>
                <TestComponent />
            </UserProvider>
        );

        // Vérifie que les données de l'utilisateur sont récupérées
        expect(await screen.findByText(/John Doe/i)).toBeInTheDocument();
    });

    test('handles fetch error', async () => {
        mockAxios.onGet('/api/account').reply(500); // Simule une erreur 500

        render(
            <UserProvider>
                <TestComponent />
            </UserProvider>
        );

        // Vérifie que l'utilisateur n'est pas connecté
        expect(screen.queryByText(/John Doe/i)).not.toBeInTheDocument();
    });
});