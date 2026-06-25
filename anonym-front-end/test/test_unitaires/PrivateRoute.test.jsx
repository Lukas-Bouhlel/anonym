import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import PrivateRoute from '../../src/router/PrivateRoute';

jest.mock('../../src/context/UserContext', () => ({
  useUser: jest.fn(),
}));

import { useUser } from '../../src/context/UserContext';

const renderRoute = ({ allowedRoles = [] } = {}) => {
  render(
    <MemoryRouter initialEntries={['/admin']}>
      <Routes>
        <Route
          path="/admin"
          element={(
            <PrivateRoute allowedRoles={allowedRoles}>
              <div>Admin content</div>
            </PrivateRoute>
          )}
        />
        <Route path="/" element={<div>Home page</div>} />
      </Routes>
    </MemoryRouter>
  );
};

describe('PrivateRoute', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('shows the loading state while the user is loading', () => {
    useUser.mockReturnValue({ user: null, isLoading: true });

    renderRoute();

    expect(screen.getByText('Chargement...')).toBeInTheDocument();
  });

  test('redirects anonymous visitors to the home page', () => {
    useUser.mockReturnValue({ user: null, isLoading: false });

    renderRoute();

    expect(screen.getByText('Home page')).toBeInTheDocument();
  });

  test('redirects connected users without an allowed role', () => {
    useUser.mockReturnValue({ user: { roles: 'USER' }, isLoading: false });

    renderRoute({ allowedRoles: ['ADMIN', 'SUPER_ADMIN'] });

    expect(screen.getByText('Home page')).toBeInTheDocument();
  });

  test('renders the content for an allowed admin role', () => {
    useUser.mockReturnValue({ user: { roles: 'ADMIN' }, isLoading: false });

    renderRoute({ allowedRoles: ['ADMIN', 'SUPER_ADMIN'] });

    expect(screen.getByText('Admin content')).toBeInTheDocument();
  });

  test('renders the content when no role restriction is provided', () => {
    useUser.mockReturnValue({ user: { roles: 'USER' }, isLoading: false });

    renderRoute();

    expect(screen.getByText('Admin content')).toBeInTheDocument();
  });
});
