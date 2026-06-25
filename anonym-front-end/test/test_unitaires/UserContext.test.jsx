import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import axios from 'axios';
import { ApiProvider } from '../../src/context/ApiContext';
import { PopupProvider } from '../../src/context/PopupContext';
import { UserProvider, useUser } from '../../src/context/UserContext';

jest.mock('axios');

const createQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      gcTime: 0,
    },
  },
});

const TestComponent = () => {
  const { user, isLoading, error, login, logout } = useUser();

  return (
    <div>
      {isLoading && <div data-testid="loading">Chargement...</div>}
      {error && <div data-testid="error">Erreur de chargement</div>}
      {user ? (
        <div>
          <div data-testid="user-info">Utilisateur: {user.name}</div>
          <button onClick={logout}>Deconnexion</button>
        </div>
      ) : (
        <div>
          <div data-testid="no-user">Pas d&apos;utilisateur connecte</div>
          <button onClick={() => login({ name: 'Jane Doe' })}>Connexion locale</button>
        </div>
      )}
    </div>
  );
};

const renderWithProviders = () => {
  const queryClient = createQueryClient();

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

  return queryClient;
};

describe('UserContext', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  test('fetches and displays the current user', async () => {
    axios.get.mockResolvedValueOnce({ data: { name: 'John Doe' } });

    const queryClient = renderWithProviders();

    expect(screen.getByTestId('loading')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('user-info')).toHaveTextContent('Utilisateur: John Doe');
    });

    queryClient.clear();
  });

  test('exposes the loading error', async () => {
    axios.get.mockRejectedValueOnce(new Error('Erreur de chargement'));

    const queryClient = renderWithProviders();

    await waitFor(() => {
      expect(screen.getByTestId('error')).toHaveTextContent('Erreur de chargement');
    });

    queryClient.clear();
  });

  test('logs out the current user', async () => {
    axios.get.mockResolvedValueOnce({ data: { name: 'John Doe' } });
    axios.post.mockResolvedValueOnce({});

    const queryClient = renderWithProviders();

    await waitFor(() => {
      expect(screen.getByTestId('user-info')).toHaveTextContent('Utilisateur: John Doe');
    });

    screen.getByText('Deconnexion').click();

    await waitFor(() => {
      expect(screen.getByTestId('no-user')).toHaveTextContent("Pas d'utilisateur connecte");
    });

    expect(axios.post).toHaveBeenCalledWith(
      'undefined/api/auth/logout',
      {},
      { withCredentials: true }
    );
    queryClient.clear();
  });

  test('logs in a user from local data', async () => {
    axios.get.mockRejectedValueOnce(new Error('Non connecte'));

    const queryClient = renderWithProviders();

    await waitFor(() => {
      expect(screen.getByTestId('no-user')).toBeInTheDocument();
    });

    screen.getByText('Connexion locale').click();

    await waitFor(() => {
      expect(screen.getByTestId('user-info')).toHaveTextContent('Utilisateur: Jane Doe');
    });

    queryClient.clear();
  });
});
