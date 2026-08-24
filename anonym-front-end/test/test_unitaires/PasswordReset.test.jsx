import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import axios from 'axios';

import PasswordReset from '../../src/components/Access/Reset/PasswordReset';

jest.mock('axios');
jest.mock('../../src/context/ApiContext', () => ({
    useApi: () => ({ api_url: 'https://api.example.com' }),
}));
jest.mock('../../src/context/PopupContext', () => ({
    usePopup: () => ({
        setOpenPopup: jest.fn(),
        setTextPopup: jest.fn(),
        setState: jest.fn(),
    }),
}));

describe('PasswordReset', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        axios.post.mockResolvedValue({});
    });

    it('identifies password reset requests as web requests', async () => {
        const user = userEvent.setup();
        const queryClient = new QueryClient({
            defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
        });

        render(
            <QueryClientProvider client={queryClient}>
                <PasswordReset setStatusForm={jest.fn()} />
            </QueryClientProvider>,
        );

        await user.type(screen.getByLabelText('Email'), 'user@example.com');
        await user.click(screen.getByRole('button', { name: 'Réinitialiser' }));

        await waitFor(() => {
            expect(axios.post).toHaveBeenCalledWith(
                'https://api.example.com/api/auth/reset-password',
                { email: 'user@example.com', platform: 'web' },
                { withCredentials: true },
            );
        });
    });
});
