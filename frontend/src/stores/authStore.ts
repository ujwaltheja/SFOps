import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  user: any | null;
  tenantId: string | null;
  setAuth: (token: string, user: any, tenantId: string) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      tenantId: null,
      setAuth: (token, user, tenantId) => set({ token, user, tenantId }),
      clearAuth: () => set({ token: null, user: null, tenantId: null }),
    }),
    {
      name: 'sfops-auth',
    }
  )
);
